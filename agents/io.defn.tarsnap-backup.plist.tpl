<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>Label</key>
    <string>io.defn.tarsnap-backup</string>
    <key>Program</key>
    <string>/opt/local/bin/tarsnap-perform-backup</string>
    <key>StartCalendarInterval</key>
    <dict>
      <key>Hour</key>
      <integer>0</integer>
      <key>Minute</key>
      <integer>0</integer>
    </dict>
    <key>StandardErrorPath</key>
    <string>$HOME/.local/var/log/tarsnap.log</string>
    <key>StandardOutPath</key>
    <string>$HOME/.local/var/log/tarsnap.log</string>
  </dict>
</plist>
