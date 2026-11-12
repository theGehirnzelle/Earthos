# EarthOS bauen (live-build)

Ergebnis: **EarthOS**, ein schlankes bootfähiges ISO mit **GNOME-Desktop**, deutscher Sprache,
Firefox, App-Store (Flathub) und grafischem Installer (Calamares). Du startest es in einer VM oder
vom USB-Stick und kannst es von dort fest installieren. Updates kommen weiter von
Debian (`sudo apt update && sudo apt upgrade`).

## Schritt für Schritt

1. **Bau-VM** mit Debian 13, mind. 4 GB RAM und 25 GB freiem Platz. Das Skript muss auf **Debian** laufen, nicht auf Ubuntu.
2. Repo holen bzw. aktualisieren:
   ```bash
   git clone https://github.com/theGehirnzelle/Earthos.git   # beim ersten Mal
   cd Earthos && git pull                                    # danach
   ```
3. Bauen:
   ```bash
   cd Earthos/build
   sudo ./bauen.sh
   ```
   Dauert je nach Internet 20 bis 60 Minuten. Das ISO liegt danach in `/root/distro-build/`,
   die Build-Nummer steht am Ende der Ausgabe.
4. Testen: ISO in VirtualBox als CD einlegen (Linux, Debian 64-bit, 4 GB RAM, 128 MB Grafikspeicher).
   Im System zeigt `grep BUILD_ID /etc/os-release`, welcher Build läuft.
5. Auf USB-Stick (fürs echte Gerät): `sudo dd if=DATEI.iso of=/dev/sdX bs=4M status=progress`
   (**sdX genau prüfen**, das Ziel wird komplett überschrieben).

## Was wo steckt (hier lernst du am meisten)

| Datei | Wirkung |
|---|---|
| `config/package-lists/desktop.list.chroot` | Welche Debian-Pakete ins System kommen. Zeile rein, neu bauen, fertig. |
| `config/hooks/normal/*.hook.chroot` | Shell-Skripte, die beim Bauen **im** neuen System laufen (hier: Name in `/etc/os-release`). |
| `config/includes.chroot/` | Dateien, die 1:1 ins System kopiert werden. `etc/skel/` = Vorlage für jeden neuen Benutzer. |
| `splash.svg` | Das Bild im Boot-Menü (640x480). Mit Inkscape bearbeiten oder durch ein eigenes SVG ersetzen. |
| `bauen.sh` | Ruft `lb config` (Grundeinstellungen) und `lb build` auf. |

Nach dem ersten Build lohnt ein Blick in `~/distro-build/config/`: Dort siehst du alle
Einstellungen, die `lb config` erzeugt hat.

## Ideen für die nächsten Runden
- GNOME-Voreinstellungen (Hintergrund, Theme, Dock) über dconf-Dateien in `includes.chroot/etc/dconf/`
- Eigene Einstellungs-App (Python + GTK4/libadwaita) als eigenes Paket
- Eigenes Plymouth-Theme (Bild beim Starten und Herunterfahren)
- Eigene Pakete mit `dpkg-deb` bauen und in `config/packages.chroot/` legen
- Eigenes Paket-Repository (dann wird es richtig „Distro")

## Wenn etwas schiefgeht
- Fehler steht am Ende von `~/distro-build/build.log`.
- Komplett neu anfangen: `cd ~/distro-build && sudo lb clean --purge`, dann `bauen.sh` erneut.
