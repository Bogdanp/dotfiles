<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>Label</key>
    <string>io.defn.fava</string>
    <key>ProgramArguments</key>
    <array>
      <string>$HOME/Library/Python/3.12/bin/fava</string>
      <string>-H</string>
      <string>127.0.0.1</string>
      <string>-p</string>
      <string>6001</string>
      <string>cleartype.beancount</string>
      <string>personal.beancount</string>
    </array>
    <key>WorkingDirectory</key>
    <string>$HOME/sandbox/accounting</string>
    <key>StandardErrorPath</key>
    <string>$HOME/.local/var/log/fava.log</string>
    <key>StandardOutPath</key>
    <string>$HOME/.local/var/log/fava.log</string>
    <key>RunAtLoad</key>
    <true/>
  </dict>
</plist>
