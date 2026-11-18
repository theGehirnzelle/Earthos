#!/bin/bash
# Baut ein Live-ISO deines Debian-Ablegers.
# Aufruf (als root, auf Debian 13 "trixie"):  sudo ./build.sh
#
# Was ins System kommt, steht im Ordner config/ daneben, das Boot-Bild in splash.svg.
set -euo pipefail

DISTRO_NAME="EarthOS"         # <- Name deiner Distro
DEBIAN_VERSION="trixie"       # Debian 13 (aktuelles stable)
BUILD_DIR="${BUILD_DIR:-$HOME/distro-build}"
SKRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VORLAGE="$SKRIPT_DIR/config"
SPLASH="$SKRIPT_DIR/splash.svg"   # Bild im Boot-Menü (640x480)

[ "$(id -u)" -eq 0 ] || { echo "Bist du dumm du musst die kacke mit sudo starten?!"; exit 1; }

# Deine Anpassungen liegen neben diesem Skript: config/ (Pakete, Hooks, Dateien) und splash.svg
[ -d "$VORLAGE" ] || { echo "Ordner $VORLAGE fehlt. Bitte aus dem Git-Repo holen."; exit 1; }
[ -f "$SPLASH" ]  || { echo "Datei $SPLASH fehlt. Bitte aus dem Git-Repo holen."; exit 1; }

apt-get update
apt-get install -y live-build librsvg2-bin

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"
lb clean --all >/dev/null 2>&1 || true   # alte Bauteile weg, heruntergeladene Pakete bleiben
rm -rf config

SLUG="$(echo "$DISTRO_NAME" | tr 'A-Z ' 'a-z-')"

lb config \
  --distribution "$DEBIAN_VERSION" \
  --archive-areas "main contrib non-free non-free-firmware" \
  --binary-images iso-hybrid \
  --debian-installer none \
  --image-name "$SLUG" \
  --iso-application "$DISTRO_NAME" \
  --iso-volume "$DISTRO_NAME" \
  --bootappend-live "boot=live components quiet splash locales=de_DE.UTF-8 keyboard-layouts=de timezone=Europe/Berlin hostname=$SLUG noeject"

# Boot-Menü: die Vorlagen von live-build in den Build holen, damit wir sie ändern können
if [ -d /usr/share/live/build/bootloaders ]; then
  mkdir -p config/bootloaders
  cp -a /usr/share/live/build/bootloaders/. config/bootloaders/
fi

# Deine Anpassungen (Paketliste, Hooks, Dateien) über die Standard-Konfiguration legen
cp -r "$VORLAGE"/. config/
sed -i "s/@@DISTRO_NAME@@/$DISTRO_NAME/" config/hooks/normal/0500-branding.hook.chroot

# Build-Nummer (Datum und Uhrzeit des Builds) in /etc/os-release schreiben.
# Anzeigen im fertigen System:  grep BUILD_ID /etc/os-release
BUILD_ID="$(date +%Y%m%d-%H%M)"
cat > config/hooks/normal/0510-build-id.hook.chroot <<HOOK
#!/bin/sh
set -e
if [ -L /etc/os-release ]; then
  cp --remove-destination /usr/lib/os-release /etc/os-release
fi
sed -i '/^BUILD_ID=/d' /etc/os-release
echo 'BUILD_ID="$BUILD_ID"' >> /etc/os-release
HOOK
chmod +x config/hooks/normal/0510-build-id.hook.chroot
echo "Build-Nummer: $BUILD_ID"

# Debian-Bild im Boot-Menü durch splash.svg ersetzen
ERSETZT=0
while read -r f; do
  rm -f "$f"
  case "$f" in
    *.png) rsvg-convert -w 640 -h 480 -o "$f" "$SPLASH" ;;
    *)     cp "$SPLASH" "$f" ;;
  esac
  ERSETZT=$((ERSETZT + 1))
done < <(find config/bootloaders \( -name 'splash.svg.in' -o -name 'splash.svg' -o -name 'splash.png' \))
echo "Boot-Bild ersetzt: $ERSETZT Datei(en)"

# Menüeinträge umbenennen: "Live system" -> "EarthOS Live"
grep -RlI 'Live system' config/bootloaders 2>/dev/null \
  | xargs -r sed -i "s/Live system/$DISTRO_NAME Live/g" || true

lb build 2>&1 | tee build.log

if grep -q "^WARNUNG" build.log; then
  echo
  grep "^WARNUNG" build.log
fi

echo
echo "Fertig: $(ls "$BUILD_DIR"/*.iso)"
