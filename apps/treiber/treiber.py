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
                            klasse = data, text
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
        if nvidea == True:
            print(nvideatreiber)
            istalldriver = False
            if nvideatreiber == "nvidia":
                print("nvidia driver already installed")
            elif nvideatreiber == "nouveau":
                print("Standard driver active")
                installdriver = True
            elif nvideatreiber == "none":
                print("no driver active")
                installdriver = True
            else:
                print("error: driver not found")
                breakpoint()

    #def findnvidiadriver(self):
        #info = subprocess.run([nvidia-detect])

    #def installnvidiadriver(self):







if __name__ == "__main__":
    Treiberskript.find_graphicscard(self=Treiberskript())


