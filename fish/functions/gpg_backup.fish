function gpg_backup
    if test (count $argv) -eq 1;
        set TARGET $argv[1]
        mkdir -p "$TARGET"

        gpg --export-secret-keys > "$TARGET/secret-keys.gpg"
        gpg --export-ownertrust > "$TARGET/ownertrust.gpg"
    else;
        echo "usage: gpg_backup TARGET"
        return 1
    end
end
