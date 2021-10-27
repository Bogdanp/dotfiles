<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>Label</key>
    <string>io.defn.yubikey-agent</string>
    <key>ProgramArguments</key>
    <array>
      <string>$HOME/sandbox/yubikey-agent/yubikey-agent</string>
      <string>-l</string>
      <string>$HOME/.local/var/run/yubikey-agent.sock</string>
    </array>
    <key>WorkingDirectory</key>
    <string>$HOME/sandbox/yubikey-agent</string>
    <key>StandardErrorPath</key>
    <string>$HOME/.local/var/log/yubikey-agent.log</string>
    <key>StandardOutPath</key>
    <string>$HOME/.local/var/log/yubikey-agent.log</string>
    <key>RunAtLoad</key>
    <true/>
  </dict>
</plist>
