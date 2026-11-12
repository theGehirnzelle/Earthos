# EarthOS

Eine eigene Linux-Distribution auf Basis von **Debian 13 „trixie“** mit **GNOME**.
Schlank ausgeliefert, aber bereit für alles: App-Store mit Flathub und Snap,
32-Bit-Unterstützung für Spiele, Codecs, Online-Konten (Microsoft, Google, Nextcloud).

## Aufbau

| Ordner | Inhalt |
|---|---|
| [`build/`](build/) | Alles, um das EarthOS-ISO zu bauen (`bauen.sh`, Paketliste, Hooks, Boot-Bild) |
| [`apps/treiber/`](apps/treiber/) | EarthOS Treiber: erkennt NVIDIA-Grafikkarten und installiert den passenden Treiber |

## ISO bauen

Auf einem **Debian-13-System** (z. B. einer VM):

```bash
git clone https://github.com/theGehirnzelle/Earthos.git
cd Earthos/build
sudo ./bauen.sh
```

Das fertige ISO liegt danach in `/root/distro-build/`. Mehr dazu in [`build/README.md`](build/README.md).

## Arbeiten mit dem Repo

```bash
git pull                      # neuesten Stand holen (z. B. in der VM)
git add .                     # Änderungen vormerken
git commit -m "Was ich geändert habe"
git push                      # hochladen
```
