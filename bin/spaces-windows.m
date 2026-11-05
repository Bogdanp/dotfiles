/*
Window movement adapted from SpacePigeon spacectl (and its yabai/ferry sources).
https://github.com/louivers/spacepigeon/blob/main/helper/spacectl.m

MIT License

Copyright (c) 2025 louivers
Copyright (c) 2019 Asmund Vikane
Copyright (c) 2026 softmaxe

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <ApplicationServices/ApplicationServices.h>
#include <mach-o/dyld.h>
#include <mach-o/loader.h>
#include <mach-o/nlist.h>
#include <objc/message.h>
#include <objc/runtime.h>
#include <stdarg.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

#define SPACECTL_VERSION "1.3.0"

#define SPACE_TYPE_USER       0
#define SPACE_TYPE_FULLSCREEN 4

#define SKYLIGHT_PATH "/System/Library/PrivateFrameworks/SkyLight.framework/Versions/A/SkyLight"
#define BRIDGED_OPERATION_SYMBOL "__ZL54SLSPerformAsynchronousBridgedWindowManagementOperationP47SLSAsynchronousBridgedWindowManagementOperation"
#define BRIDGED_MOVE_CLASS "SLSBridgedMoveWindowsToManagedSpaceOperation"

extern int SLSMainConnectionID(void);
extern CFArrayRef SLSCopyManagedDisplaySpaces(int cid);
extern int SLSSpaceGetType(int cid, uint64_t sid);
extern CFArrayRef SLSCopySpacesForWindows(int cid, int selector, CFArrayRef window_list);
extern CFStringRef SLSCopyManagedDisplayForSpace(int cid, uint64_t sid);
extern uint64_t SLSManagedDisplayGetCurrentSpace(int cid, CFStringRef display);
extern CGError SLSSpaceSetFrontPSN(int cid, uint64_t sid, ProcessSerialNumber psn);
extern CGError SLSGetWindowOwner(int cid, uint32_t wid, int *wcid);
extern CGError SLSGetConnectionPSN(int cid, ProcessSerialNumber *psn);

typedef int64_t (*bridged_operation_fn)(void *operation);

static int g_cid;

static uint64_t now_ns(void)
{
    return clock_gettime_nsec_np(CLOCK_UPTIME_RAW);
}

static double elapsed_ms(uint64_t start_ns)
{
    return (now_ns() - start_ns) / 1e6;
}

static void sleep_ms(double ms)
{
    CFRunLoopRunInMode(kCFRunLoopDefaultMode, ms / 1000.0, true);
}

// The window server ignores the bridged move from processes that have not
// loaded AppKit. Referencing an AppKit class keeps the framework linked and
// loaded even if the linker would otherwise drop it.
static void ensure_appkit_loaded(void)
{
    (void) [NSWorkspace class];
}

//
// Symbol lookup for functions that SkyLight does not export
// (yabai: misc/macho_dlsym.h, via ferry).
//

static struct mach_header_64 *macho_find_image_header(const char *target_name, intptr_t *slide)
{
    uint32_t image_count = _dyld_image_count();
    for (uint32_t i = 0; i < image_count; ++i) {
        const char *image_name = _dyld_get_image_name(i);
        if (image_name && strcmp(image_name, target_name) == 0) {
            *slide = _dyld_get_image_vmaddr_slide(i);
            return (struct mach_header_64 *) _dyld_get_image_header(i);
        }
    }
    return NULL;
}

static void *macho_find_symbol(const char *target_image, const char *target_symbol)
{
    intptr_t slide = 0;
    struct mach_header_64 *header = macho_find_image_header(target_image, &slide);
    if (!header) return NULL;

    struct segment_command_64 *linkedit = NULL;
    struct symtab_command *symtab = NULL;
    uint8_t *cursor = (uint8_t *) header + sizeof(struct mach_header_64);

    for (uint32_t i = 0; i < header->ncmds; ++i) {
        struct load_command *cmd = (struct load_command *) cursor;
        if (cmd->cmd == LC_SEGMENT_64) {
            struct segment_command_64 *segment = (struct segment_command_64 *) cmd;
            if (strncmp(segment->segname, SEG_LINKEDIT, sizeof(segment->segname)) == 0) {
                linkedit = segment;
            }
        } else if (cmd->cmd == LC_SYMTAB) {
            symtab = (struct symtab_command *) cmd;
        }
        cursor += cmd->cmdsize;
    }

    if (!linkedit || !symtab) return NULL;

    uint8_t *linkedit_base = (uint8_t *) (linkedit->vmaddr - linkedit->fileoff + slide);
    const char *strings = (const char *) (linkedit_base + symtab->stroff);
    struct nlist_64 *symbols = (struct nlist_64 *) (linkedit_base + symtab->symoff);

    for (uint32_t i = 0; i < symtab->nsyms; ++i) {
        if (strcmp(strings + symbols[i].n_un.n_strx, target_symbol) == 0) {
            return (void *) (symbols[i].n_value + slide);
        }
    }

    return NULL;
}

static bridged_operation_fn find_bridged_perform(void)
{
    static bool looked = false;
    static bridged_operation_fn perform = NULL;
    if (!looked) {
        looked = true;
        if (objc_getClass(BRIDGED_MOVE_CLASS)) {
            perform = (bridged_operation_fn) macho_find_symbol(SKYLIGHT_PATH, BRIDGED_OPERATION_SYMBOL);
        }
    }
    return perform;
}

static uint64_t cfnumber_u64(CFTypeRef value)
{
    uint64_t result = 0;
    if (value) CFNumberGetValue(value, kCFNumberSInt64Type, &result);
    return result;
}

static CFArrayRef window_id_array(uint32_t wid)
{
    CFNumberRef number = CFNumberCreate(NULL, kCFNumberSInt32Type, &wid);
    CFArrayRef array = CFArrayCreate(NULL, (const void **) &number, 1, &kCFTypeArrayCallBacks);
    CFRelease(number);
    return array;
}

// Space ids the window is on (0x7 = all space types).
static int window_spaces(uint32_t wid, uint64_t *out, int max)
{
    CFArrayRef windows = window_id_array(wid);
    CFArrayRef spaces = SLSCopySpacesForWindows(g_cid, 0x7, windows);
    CFRelease(windows);
    if (!spaces) return 0;

    int n = 0;
    for (CFIndex i = 0; i < CFArrayGetCount(spaces) && n < max; ++i) {
        out[n++] = cfnumber_u64(CFArrayGetValueAtIndex(spaces, i));
    }
    CFRelease(spaces);
    return n;
}

static bool window_is_on_space(uint32_t wid, uint64_t sid)
{
    uint64_t spaces[16];
    int n = window_spaces(wid, spaces, 16);
    for (int i = 0; i < n; ++i) {
        if (spaces[i] == sid) return true;
    }
    return false;
}

static int move_window(uint32_t wid, uint64_t sid, int timeout_ms, double *took_ms)
{
    bridged_operation_fn perform = find_bridged_perform();
    if (!perform) return 3;

    if (window_is_on_space(wid, sid)) {
        if (took_ms) *took_ms = 0;
        return 0;
    }

    int owner_cid = 0;
    ProcessSerialNumber psn = {0};
    bool have_psn = SLSGetWindowOwner(g_cid, wid, &owner_cid) == kCGErrorSuccess &&
                    SLSGetConnectionPSN(owner_cid, &psn) == kCGErrorSuccess;

    uint64_t start = now_ns();
    Class cls = objc_getClass(BRIDGED_MOVE_CLASS);
    CFArrayRef windows = window_id_array(wid);
    SEL sel = sel_registerName("initWithWindows:spaceID:");
    id operation = ((id (*)(id, SEL, id, uint64_t)) objc_msgSend)([cls alloc], sel, (id) windows, sid);
    perform(operation);
    [operation release];
    CFRelease(windows);

    if (have_psn) SLSSpaceSetFrontPSN(g_cid, sid, psn);

    // The operation is asynchronous: poll until the window server agrees.
    bool moved = false;
    while (!(moved = window_is_on_space(wid, sid)) && elapsed_ms(start) < timeout_ms) {
        sleep_ms(2);
    }

    if (took_ms) *took_ms = elapsed_ms(start);
    return moved ? 0 : 1;
}

// Input: bundle identifier -> current numeric desktop ID, from the Python resolver.
int main(int argc, char **argv)
{
    @autoreleasepool {
        ensure_appkit_loaded();
        g_cid = SLSMainConnectionID();
        bool dry = argc == 2 && strcmp(argv[1], "--dry-run") == 0;
        if (argc > 2 || (argc == 2 && !dry)) return 2;
        NSData *input = [[NSFileHandle fileHandleWithStandardInput] readDataToEndOfFile];
        NSDictionary *targets = [NSJSONSerialization JSONObjectWithData:input options:0 error:NULL];
        if (![targets isKindOfClass:[NSDictionary class]]) return 2;
        for (id app in targets) {
            id target = targets[app];
            if (![app isKindOfClass:[NSString class]] ||
                ![target isKindOfClass:[NSNumber class]] ||
                [target unsignedLongLongValue] == 0 ||
                SLSSpaceGetType(g_cid, [target unsignedLongLongValue]) != 0) {
                fputs("Invalid or unavailable target desktop.\n", stderr);
                return 2;
            }
        }
        CFArrayRef list = CGWindowListCopyWindowInfo(kCGWindowListExcludeDesktopElements, kCGNullWindowID);
        if (!list) { fputs("Cannot read existing windows.\n", stderr); return 1; }
        int failed = 0, moved = 0, skipped = 0;
        for (NSDictionary *window in (NSArray *)list) {
            if ([window[(id)kCGWindowLayer] intValue] != 0) continue;
            pid_t pid = [window[(id)kCGWindowOwnerPID] intValue];
            NSString *app = [[[NSRunningApplication runningApplicationWithProcessIdentifier:pid]
                              bundleIdentifier] lowercaseString];
            NSNumber *target = app ? targets[app] : nil;
            if (!target) continue;
            uint32_t wid = [window[(id)kCGWindowNumber] unsignedIntValue];
            uint64_t spaces[16];
            int count = window_spaces(wid, spaces, 16);
            if (!count) continue; // Auxiliary/unmanaged windows.
            if (count != 1 || SLSSpaceGetType(g_cid, spaces[0]) != 0) {
                skipped++;
                continue; // Preserve fullscreen and all-desktop windows.
            }
            uint64_t sid = [target unsignedLongLongValue];
            if (spaces[0] == sid) continue;
            if (dry) {
                printf("%s: would move window %u to Space %llu\n", app.UTF8String, wid, sid);
                continue;
            }
            double duration = 0;
            int result = move_window(wid, sid, 2000, &duration);
            if (result) {
                fprintf(stderr, "%s: window %u did not move to Space %llu (%s)\n",
                        app.UTF8String, wid, sid, result == 3 ? "API unavailable" : "verification failed");
                failed++;
            } else {
                printf("%s: moved window %u to Space %llu\n", app.UTF8String, wid, sid);
                moved++;
            }
        }
        CFRelease(list);
        printf("Window restore: %d moved, %d failed, %d fullscreen/shared skipped%s.\n",
               moved, failed, skipped, dry ? " (dry run)" : "");
        return failed ? 1 : 0;
    }
}
