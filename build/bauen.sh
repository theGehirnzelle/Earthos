#!/bin/bash
# Baut ein Live-ISO deines Debian-Ablegers.
# Aufruf (als root, auf Debian 13 "trixie"):  sudo ./bauen.sh
#
# Beim ersten Start legt das Skript neben sich einen Ordner "config" und das
# Boot-Bild "splash.svg" an. Darin passt du deine Distro an und startest dann neu.
set -euo pipefail

DISTRO_NAME="EarthOS"         # <- Name deiner Distro
DEBIAN_VERSION="trixie"       # Debian 13 (aktuelles stable)
BUILD_DIR="${BUILD_DIR:-$HOME/distro-build}"
SKRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VORLAGE="$SKRIPT_DIR/config"
SPLASH="$SKRIPT_DIR/splash.svg"   # Bild im Boot-Menü (640x480)

[ "$(id -u)" -eq 0 ] || { echo "Bitte mit sudo starten."; exit 1; }

# --- Standard-Anpassungen anlegen, falls es noch keinen config-Ordner gibt ---
if [ ! -d "$VORLAGE" ]; then
  echo "Lege Vorlage an: $VORLAGE"
  mkdir -p "$VORLAGE/package-lists" \
           "$VORLAGE/hooks/normal" \
           "$VORLAGE/includes.chroot/etc/skel"

  # Welche Debian-Pakete ins System kommen
  cat > "$VORLAGE/package-lists/desktop.list.chroot" <<'LISTE'
# Desktop: GNOME, nur der Kern (ohne LibreOffice, Evolution, Rhythmbox usw.).
# Das komplette GNOME mit allen Apps wäre: task-gnome-desktop
# Für Xfce stattdessen: task-xfce-desktop   | KDE Plasma: task-kde-desktop
task-desktop
gnome-core

# Deutsch als Sprache und Tastatur
task-german
task-german-desktop
locales
console-setup
keyboard-configuration

# Grafischer Installer, damit man vom Live-System auf die Festplatte installieren kann
calamares-settings-debian

# Hardware
firmware-linux
# Laptops mit zwei Grafikkarten: "Mit dedizierter Grafikkarte starten" per Rechtsklick
switcheroo-control
# Sagt, welcher NVIDIA-Treiber zur Karte passt (wird vom EarthOS-Treiber-Skript benutzt)
nvidia-detect

# Online-Konten (Microsoft, Google, Nextcloud) stecken in GNOME selbst
# (Einstellungen -> Online-Konten); das hier sorgt für Cloud-Dateien und Kalender
gvfs-backends
gnome-calendar

# Programme nachinstallieren: App-Store mit Flatpak (Flathub wird per Hook eingetragen)
flatpak
gnome-software
gnome-software-plugin-flatpak

# Snap als zweite App-Quelle (Snaps erscheinen ebenfalls im App-Store)
snapd
gnome-software-plugin-snap

# Damit Videos, Musik und Spiele ohne Probleme laufen
gstreamer1.0-plugins-good
gstreamer1.0-plugins-bad
gstreamer1.0-plugins-ugly
gstreamer1.0-libav
mesa-vulkan-drivers

# Programmieren: Grundwerkzeuge (Compiler, make, git)
build-essential
git
curl

# Browser
firefox-esr
firefox-esr-l10n-de

# Kleine Helfer
sudo
htop
LISTE

  # Skript, das beim Bauen IM neuen System läuft
  cat > "$VORLAGE/hooks/normal/0500-branding.hook.chroot" <<'HOOK'
#!/bin/sh
# Läuft beim Bauen IM neuen System (chroot) und gibt ihm einen eigenen Namen.
set -e

NAME="@@DISTRO_NAME@@"   # wird von bauen.sh ersetzt

# os-release ist die Datei, aus der Programme den Namen des Systems lesen.
# ID bleibt "debian", damit Programme und Installationsskripte dein System
# weiterhin als Debian erkennen und richtig funktionieren.
rm -f /etc/os-release
sed -e "s/^PRETTY_NAME=.*/PRETTY_NAME=\"$NAME (basiert auf Debian 13)\"/" \
    -e "s/^NAME=.*/NAME=\"$NAME\"/" \
    /usr/lib/os-release > /etc/os-release

# Begrüßung auf der Text-Konsole
printf '%s \\n \\l\n\n' "$NAME" > /etc/issue
HOOK
  chmod +x "$VORLAGE/hooks/normal/0500-branding.hook.chroot"

  # Plattform: 32-Bit für Spiele und Flathub als App-Quelle
  cat > "$VORLAGE/hooks/normal/0600-plattform.hook.chroot" <<'HOOK'
#!/bin/sh
# Läuft beim Bauen IM neuen System und bereitet es für Programme vor,
# die nicht vorinstalliert sind, aber problemlos laufen sollen.
set -e

# 32-Bit-Unterstützung, damit Steam und Windows-Spiele (Wine/Proton) laufen
dpkg --add-architecture i386

# Flathub als App-Quelle: Discord, Spotify, VS Code, Steam usw. im App-Store
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo \
  || echo "WARNUNG: Flathub konnte nicht eingetragen werden"
HOOK
  chmod +x "$VORLAGE/hooks/normal/0600-plattform.hook.chroot"

  # Dateien, die 1:1 ins System kopiert werden (etc/skel = Vorlage für jeden neuen Benutzer)
  cat > "$VORLAGE/includes.chroot/etc/skel/WILLKOMMEN.txt" <<'TEXT'
Willkommen in deiner eigenen Distro!

Diese Datei kommt aus config/includes.chroot/etc/skel/ neben bauen.sh.
Alles, was du dort ablegst, landet 1:1 im fertigen System.
TEXT
fi

# --- Bild für das Boot-Menü anlegen, falls es noch keins gibt ---
if [ ! -f "$SPLASH" ]; then
  echo "Lege Boot-Bild an: $SPLASH"
  cat > "$SPLASH" <<'SVG'
<svg xmlns="http://www.w3.org/2000/svg" width="640" height="480" viewBox="0 0 640 480">
  <defs>
    <linearGradient id="himmel" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#0a1a2e"/>
      <stop offset="1" stop-color="#03070d"/>
    </linearGradient>
    <radialGradient id="meer" cx="0.35" cy="0.3" r="0.8">
      <stop offset="0" stop-color="#3a8fd9"/>
      <stop offset="1" stop-color="#0c3460"/>
    </radialGradient>
    <clipPath id="kugel"><circle cx="190" cy="125" r="62"/></clipPath>
  </defs>

  <!-- Hintergrund mit ein paar Sternen -->
  <rect width="640" height="480" fill="url(#himmel)"/>
  <g fill="#ffffff" opacity="0.6">
    <circle cx="40" cy="40" r="1"/><circle cx="120" cy="210" r="0.8"/>
    <circle cx="300" cy="30" r="1.2"/><circle cx="420" cy="70" r="0.8"/>
    <circle cx="560" cy="35" r="1"/><circle cx="600" cy="150" r="0.8"/>
    <circle cx="500" cy="220" r="1"/><circle cx="70" cy="140" r="0.8"/>
    <circle cx="610" cy="420" r="1"/><circle cx="30" cy="400" r="0.8"/>
  </g>

  <!-- Erdkugel -->
  <circle cx="190" cy="125" r="68" fill="#5cc8ff" opacity="0.15"/>
  <circle cx="190" cy="125" r="62" fill="url(#meer)"/>
  <g clip-path="url(#kugel)" fill="#4caf50">
    <path d="M150 80 q20 -15 40 -5 q10 10 -5 22 q-15 6 -10 20 q4 14 -14 18 q-18 2 -22 -16 q-6 -22 11 -39z"/>
    <path d="M205 120 q18 -6 30 8 q10 14 -4 30 q-12 14 -26 4 q-10 -10 -6 -24 q2 -14 6 -18z"/>
    <path d="M215 70 q14 -4 22 6 q4 8 -8 10 q-12 0 -14 -16z"/>
  </g>

  <!-- Name -->
  <text x="280" y="128" font-family="DejaVu Sans, sans-serif" font-size="54" font-weight="bold" fill="#ffffff">EarthOS</text>
  <text x="283" y="160" font-family="DejaVu Sans, sans-serif" font-size="17" fill="#8fbfe6">basiert auf Debian 13</text>
</svg>
SVG
fi

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
