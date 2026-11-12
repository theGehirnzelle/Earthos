# EarthOS Treiber: deine erste eigene App

> **Stand 12.11.2026:** Wir bauen das Treiber-Werkzeug zuerst als **Kommandozeilen-Skript**
> (`treiber.py`), das bei der Installation oder beim ersten Start im Hintergrund läuft.
> Ein Knopf zum Nachholen kommt später in die EarthOS-Einstellungs-App. Die Schritte zum
> Fenster (1, 3) und `fenster_vorlage.py` sind deshalb für später.

**Ziel:** Eine kleine GNOME-App, die eine NVIDIA-Grafikkarte erkennt und auf Knopfdruck
den passenden Treiber installiert. So etwas wie „Zusätzliche Treiber“ bei Ubuntu.

**Werkzeuge:** Python 3, GTK4 und libadwaita (das ist die Bibliothek, mit der moderne
GNOME-Apps gebaut sind). Deine App sieht damit automatisch aus wie ein Teil von GNOME.

---

## Schritt 0: Arbeitsplatz einrichten

Am besten direkt in deiner EarthOS-Test-VM (GNOME). Die Bau-VM geht aber auch.

```bash
sudo apt install python3-gi gir1.2-gtk-4.0 gir1.2-adw-1 pciutils git
```

Sehr empfehlenswert ist die App **Workbench** aus dem App-Store (Flathub). Damit kannst du
GTK-Oberflächen live ausprobieren und siehst alle Bausteine mit Beispielen.

Nachschlagen kannst du hier:
- Bausteine (Widgets) von libadwaita: https://gnome.pages.gitlab.gnome.org/libadwaita/doc/main/
- Python-GTK4-Referenz: https://amolenaar.pages.gitlab.gnome.org/pygobject-docs/
- Wie GNOME-Apps aussehen sollen: https://developer.gnome.org/hig/

## Schritt 1: Ein leeres Fenster

Das Grundgerüst liegt als `fenster_vorlage.py` daneben. Starte es mit:

```bash
python3 fenster_vorlage.py
```

**Aufgabe:** Lies jede Zeile und finde heraus, was sie macht. Ändere Titel und Text,
probiere ein anderes Icon (`icon_name`). Merke dir die drei Ebenen:
`Application` (das Programm) → `ApplicationWindow` (das Fenster) → Inhalt (Widgets).

## Schritt 2: Grafikkarte erkennen

Linux zeigt alle Geräte als Dateien unter `/sys/bus/pci/devices/`. Jedes Gerät hat dort u. a.:
- `class`: beginnt mit `0x03` → Grafikkarte
- `vendor`: `0x10de` = NVIDIA, `0x1002` = AMD, `0x8086` = Intel
- `driver`: ein Link auf den Treiber, der gerade läuft (z. B. `nouveau` oder `nvidia`)

**Aufgabe:** Schreib eine Funktion `finde_grafikkarten()`, die diese Dateien liest und eine
Liste zurückgibt (Hersteller, aktiver Treiber). Teste sie erst **ohne** Oberfläche im Terminal.
Tipp: `pathlib.Path`, `.read_text()`, `.resolve().name` für den Treiber-Link.
Zum Vergleich zeigt dir `lspci -nnk | grep -A3 -E "VGA|3D"` dasselbe.

**Wichtig:** In der VM hast du keine NVIDIA-Karte. Bau deshalb einen **Testmodus** ein, z. B.
über eine Umgebungsvariable `EARTHOS_TEST_NVIDIA=1`, die so tut, als gäbe es eine.

## Schritt 3: Anzeigen

Zeig das Ergebnis im Fenster an:
- keine NVIDIA-Karte → „Alles bestens, kein zusätzlicher Treiber nötig“
- NVIDIA mit `nouveau` → Hinweis und ein Knopf **„Treiber installieren“**
- NVIDIA mit `nvidia` → „Der NVIDIA-Treiber ist bereits aktiv“

Tipp: `Adw.StatusPage` (hast du schon), `Gtk.Button` mit der CSS-Klasse `suggested-action`
und `pill`, und `Adw.PreferencesGroup` mit `Adw.ActionRow` für eine schöne Geräteliste.

## Schritt 4: Den richtigen Treiber herausfinden

Debian hat dafür das Werkzeug `nvidia-detect` (Paket `nvidia-detect`). Es sagt dir, welches
Paket zu der Karte passt (meist `nvidia-driver`, bei alten Karten eine Legacy-Version).

**Aufgabe:** Ruf es mit `subprocess.run(..., capture_output=True, text=True)` auf und lies
den empfohlenen Paketnamen aus der Ausgabe.

## Schritt 5: Installieren, ohne dass die App als root läuft

Grafische Apps laufen **nie** als root. Für den einen Befehl, der root braucht, nimmst du
`pkexec`. Das zeigt den normalen Passwort-Dialog von GNOME:

```
pkexec apt-get install -y nvidia-driver firmware-misc-nonfree linux-headers-amd64
```

**Wichtig:** Die Installation dauert Minuten. Läuft sie direkt im Code des Knopfs, friert
die App ein. Nutze `Gio.Subprocess` (läuft im Hintergrund), zeig solange einen
`Gtk.Spinner` und die Ausgabe in einer `Gtk.TextView`.

## Schritt 6: Secure Boot und Neustart

Ist Secure Boot an (`mokutil --sb-state`), muss der Treiber signiert werden. Debian macht das
automatisch, aber beim nächsten Start fragt ein blauer Bildschirm („MOK Management“), ob der
Schlüssel erlaubt werden soll. **Deine App sollte das vorher erklären.** Am Ende ein Knopf
**„Jetzt neu starten“** (`systemctl reboot`).

## Schritt 7: Fest in EarthOS einbauen

Damit die App in jedem EarthOS steckt, wird sie ein Debian-Paket (`.deb`):

```
earthos-treiber/
├── DEBIAN/control                                   # Name, Version, Abhängigkeiten
├── usr/bin/earthos-treiber                          # dein Programm
└── usr/share/applications/de.earthos.Treiber.desktop # Eintrag im App-Menü
```

Bauen mit `dpkg-deb --build earthos-treiber`, die `.deb` in `config/packages.chroot/`
neben `bauen.sh` legen, neu bauen. Fertig.

---

**Tipp:** Leg von Anfang an ein git-Repository an (`git init`) und committe nach jedem Schritt.
Wenn du willst, machen wir daraus später ein GitHub-Repo für alle EarthOS-Apps.
Wenn du bei einem Schritt hängst, schick mir deinen Code oder die Fehlermeldung.
