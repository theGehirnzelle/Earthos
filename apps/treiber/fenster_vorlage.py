import sys

import gi
gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Adw, Gtk


class TreiberFenster(Adw.ApplicationWindow):
    def __init__(self, app):
        super().__init__(application=app, title="EarthOS Treiber")
        self.set_default_size(500, 400)

        inhalt = Adw.StatusPage(
            icon_name="video-display-symbolic",
            title="EarthOS Treiber",
            description="Hier erscheint bald deine Grafikkarte.",
        )

        ansicht = Adw.ToolbarView()
        ansicht.add_top_bar(Adw.HeaderBar())
        ansicht.set_content(inhalt)
        self.set_content(ansicht)


class TreiberApp(Adw.Application):
    def __init__(self):
        super().__init__(application_id="de.earthos.Treiber")

    def do_activate(self):
        TreiberFenster(self).present()


TreiberApp().run(sys.argv)
