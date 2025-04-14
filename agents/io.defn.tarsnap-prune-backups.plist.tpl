<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>Label</key>
    <string>io.defn.tarsnap-prune-backups</string>
    <key>Program</key>
    <string>/opt/local/bin/tarsnap-prune-backups</string>
    <key>WorkingDirectory</key>
    <string>/tmp</string>
    <key>StartCalendarInterval</key>
    <dict>
      <key>Hour</key>
      <integer>9</integer>
      <key>Minute</key>
      <integer>0</integer>
      <key>Weekday</key>
      <integer>1</integer>
    </dict>
    <key>StandardErrorPath</key>
    <string>$HOME/.local/var/log/tarsnap-prune.log</string>
    <key>StandardOutPath</key>
    <string>$HOME/.local/var/log/tarsnap-prune.log</string>
  </dict>
</plist>
