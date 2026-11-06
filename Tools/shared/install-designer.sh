#!/bin/bash
# Installs the Ignition Designer Launcher inside the tools desktop.
# Run in the desktop terminal:  bash /config/shared/install-designer.sh
LOG=/config/shared/install-designer.log
exec > >(tee "$LOG") 2>&1
echo "=== $(date) ==="
DEST="$HOME/designerlauncher"
WORK=$(mktemp -d)

echo "--- Downloads folder:"; ls -la "$HOME/Downloads" 2>&1
echo "--- Any launcher-like files in home:"
find "$HOME" -maxdepth 3 \( -iname '*launcher*' -o -iname '*.tar.gz' -o -iname '*.tgz' \) -not -path "$DEST/*" 2>/dev/null

# 1) Use an already-downloaded archive if there is one
ARCHIVE=$(find "$HOME/Downloads" "$HOME" -maxdepth 2 -type f \( -iname '*launcher*.tar.gz' -o -iname '*launcher*.tgz' -o -iname '*launcher*.zip' \) 2>/dev/null | head -n1)

# 2) Otherwise try to download it straight from a gateway
if [ -z "$ARCHIVE" ]; then
  echo "--- No archive found, trying to download from the gateways"
  for GW in http://host.docker.internal:9088 http://host.docker.internal:8088; do
    echo "Gateway $GW status: $(curl -s -o /dev/null -w '%{http_code}' $GW/StatusPing) $(curl -s $GW/StatusPing)"
    for P in /system/launchers/designer/linux /system/launchers/designer/linux.tar.gz \
             /web/launchers/designer/linux /system/designer-launcher/linux \
             /data/launchers/designer/linux /launchers/designer/linux; do
      code=$(curl -s -L -o "$WORK/dl" -w '%{http_code}' "$GW$P")
      if gzip -t "$WORK/dl" 2>/dev/null; then type=gzip; elif unzip -tq "$WORK/dl" >/dev/null 2>&1; then type=zip; else type="not an archive ($(head -c 60 "$WORK/dl" | tr -d '\n\r'))"; fi
      echo "  $P -> HTTP $code, $type"
      if [ "$code" = "200" ] && echo "$type" | grep -qE '^(gzip|zip)$'; then
        ARCHIVE="$WORK/designerlauncher.$(echo "$type" | grep -qi gzip && echo tar.gz || echo zip)"
        mv "$WORK/dl" "$ARCHIVE"; break 2
      fi
    done
    echo "  Links on $GW home page containing 'launch':"
    curl -s -L "$GW/" | grep -oiE '(href|src)="[^"]*launch[^"]*"' | sort -u | head
  done
fi

if [ -z "$ARCHIVE" ]; then
  echo "!!! Could not find or download the launcher. Send this log to Claude."; exit 1
fi

echo "--- Using archive: $ARCHIVE"; ls -la "$ARCHIVE"
rm -rf "$DEST"; mkdir -p "$DEST"
case "$ARCHIVE" in
  *.zip) unzip -q "$ARCHIVE" -d "$DEST" ;;
  *)     tar -xzf "$ARCHIVE" -C "$DEST" ;;
esac
echo "--- Extracted:"; find "$DEST" -maxdepth 3 | head -30
SH=$(find "$DEST" -type f -iname 'designerlauncher*.sh' | head -n1)
[ -z "$SH" ] && SH=$(find "$DEST" -type f -perm -u+x -iname '*designer*' | head -n1)
echo "--- Launcher executable: $SH"
[ -z "$SH" ] && { echo "!!! No launcher script found. Send this log to Claude."; exit 1; }
chmod +x "$SH"

# Desktop + menu shortcut
mkdir -p "$HOME/Desktop" "$HOME/.local/share/applications"
for f in "$HOME/Desktop/ignition-designer.desktop" "$HOME/.local/share/applications/ignition-designer.desktop"; do
cat > "$f" <<DESK
[Desktop Entry]
Type=Application
Name=Ignition Designer Launcher
Exec="$SH"
Icon=applications-engineering
Terminal=false
Categories=Development;
DESK
chmod +x "$f"
done
echo "=== DONE: double-click 'Ignition Designer Launcher' on the desktop, or run: \"$SH\" ==="
