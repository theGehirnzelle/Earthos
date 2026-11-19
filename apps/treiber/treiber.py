from multiprocessing.managers import public_methods
from pathlib import Path
import subprocess


class Treiberskript():
    def find_graphicscard(self):
        device_folder = Path("/sys/bus/pci/devices/")
        class0x03 = []
        nvidea = False
        for device in device_folder.iterdir():
            print("device: ", device)
            for data in device.iterdir():
                if data.name == "class":
                    with data.open() as text:
                        text = text.read()
                        print("class: ", text)
                        if text[:4] == "0x03":
                            klasse = [data, text, device.resolve().name]
                            class0x03.append(klasse)
                if data.name == "vendor":
                    with data.open() as text:
                        text = text.read()
                        print("vendor: ", text)
                        if text == "0x10de":
                            nvidea = True
                if data.name == "driver":
                    driver = data.resolve().name
                    print("driver: ", driver)
                    if nvidea == True:
                        nvideatreiber = data.resolve().name
        print(class0x03)
        print(len(class0x03))
        print(nvidea)
        istalldriver = False
        if nvidea == True:
            print(nvideatreiber)
            if nvideatreiber == "nvidia":
                print("nvidia driver already installed")
                return []
            elif nvideatreiber == "nouveau":
                print("Standard driver active")
                installdriver = True
                return class0x03
            elif nvideatreiber == "none":
                print("no driver active")
                installdriver = True
                return class0x03
            else:
                print("error: driver not found")
                breakpoint()
        else:
            return []


    def findnvidiadriver(gpu):
        debian = False
        if Path("usr/share/hwdata/pci.ids").exists():
            print("hwdata")
            debian = True
            pci = Path("usr/share/hwdata/pci.ids")
        elif Path("usr/share/misc/pci.ids").exists():
            print("misc")
            pci = Path("usr/share/misc/pci.ids")
        else:
            print("error: pci.ids path not found")
            breakpoint()




    def installnvidiadriver(self):
        print("Methode noch in Arbeit")






if __name__ == "__main__":
    gpu = Treiberskript.find_graphicscard(self=Treiberskript())
    print(len(gpu))
    Treiberskript.findnvidiadriver(gpu)
