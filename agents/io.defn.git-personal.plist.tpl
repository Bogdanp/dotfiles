<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>Label</key>
    <string>io.defn.git-personal</string>
    <key>ProgramArguments</key>
    <array>
      <string>/bin/zsh</string>
      <string>-c</string>
      <string>git commit --no-gpg-sign -am "$(date)" && git push origin master</string>
    </array>
    <key>WorkingDirectory</key>
    <string>$HOME/Documents/Org</string>
    <key>StartCalendarInterval</key>
    <dict>
      <key>Hour</key>
      <integer>0</integer>
      <key>Minute</key>
      <integer>0</integer>
    </dict>
    <key>StandardErrorPath</key>
    <string>$HOME/.local/var/log/git-personal.log</string>
    <key>StandardOutPath</key>
    <string>$HOME/.local/var/log/git-personal.log</string>
  </dict>
</plist>
