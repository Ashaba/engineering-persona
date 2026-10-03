#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LA_DIR="${LAUNCH_AGENTS_DIR:-$HOME/Library/LaunchAgents}"
LABEL="com.engineering-persona.learn-sweep"
PLIST="$LA_DIR/$LABEL.plist"
REAL=0; [ -z "${LAUNCH_AGENTS_DIR:-}" ] && REAL=1

if [ "${1:-}" = "--remove" ]; then
  [ "$REAL" = 1 ] && [ -f "$PLIST" ] && launchctl unload "$PLIST" 2>/dev/null || true
  rm -f "$PLIST"
  echo "removed $PLIST"
  exit 0
fi

HOUR="${SWEEP_HOUR:-9}"
STATE_DIR="${PERSONA_STATE_DIR:-$HOME/.local/state/engineering-persona}"
# Unset means run-sweep.sh picks whichever agent is installed at run time.
AGENT_ENV=""
[ -n "${SWEEP_AGENT:-}" ] && AGENT_ENV="<key>EnvironmentVariables</key>
  <dict><key>SWEEP_AGENT</key><string>$SWEEP_AGENT</string></dict>"
mkdir -p "$LA_DIR" "$STATE_DIR"
cat > "$PLIST" <<PL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>$LABEL</string>
  <key>ProgramArguments</key>
  <array>
    <string>$REPO_DIR/run-sweep.sh</string>
  </array>
  <key>WorkingDirectory</key><string>$REPO_DIR</string>
  $AGENT_ENV
  <key>StartCalendarInterval</key>
  <dict><key>Hour</key><integer>$HOUR</integer><key>Minute</key><integer>0</integer></dict>
  <key>StandardOutPath</key><string>$STATE_DIR/sweep.log</string>
  <key>StandardErrorPath</key><string>$STATE_DIR/sweep.log</string>
</dict>
</plist>
PL
echo "installed $PLIST (daily at ${HOUR}:00, agent: ${SWEEP_AGENT:-auto})"

if [ "$REAL" = 1 ]; then
  launchctl unload "$PLIST" 2>/dev/null || true
  launchctl load "$PLIST" 2>/dev/null || echo "note: run 'launchctl load $PLIST' to activate"
fi
