from sys import argv
import requests
from time import sleep
import yaml
from yaml.parser import ParserError
from yaml.loader import SafeLoader
from bluepy import btle
from json import dumps
from datetime import datetime

class MyDelegate(btle.DefaultDelegate):
    def __init__(self):
        btle.DefaultDelegate.__init__(self)
        self.data = {}

    def handleNotification(self, _, data):
        databytes = bytearray(data)
        temperature = int.from_bytes(databytes[0:2],"little") / 100
        humidity = int.from_bytes(databytes[2:3],"little")
        battery = int.from_bytes(databytes[3:5],"little") / 1000
        print(f"Temperature: {temperature}, humidity: {humidity}, battery: {battery}")
        self.data = {"temperature": temperature, "humidity": humidity, "battery": battery, "success": True}

def read_values(mac):
    print(f"Connecting to {mac}")
    connected = False
    try:
        # Timeout not released: https://github.com/IanHarvey/bluepy/pull/374
        dev = btle.Peripheral(mac)
        connected = True
        print("Connection done...")
        delegate = MyDelegate()
        dev.setDelegate(delegate)
        print("Waiting for data...")
        dev.waitForNotifications(15.0)
        return delegate.data
    except btle.BTLEDisconnectError as error:
        print(error)
        return {"success": False}
    finally:
        if connected:
            dev.disconnect()

def task(devices, server_url):
    for device in devices:
        data = read_values(device['address'])
        data["sensor"]="xiaomi-" + device['address']
        data["timestamp"]=int(datetime.now().timestamp() * 1000000000)
        print(dumps(data))
        try:
            session = requests.session()
            response = session.post(server_url, data=dumps(data))
            if response.status_code >=300:
                print("Error posting data to", server_url, ": ", response.status_code, str(response.content))
        except requests.exceptions.RequestException as err:
                print("Error posting data to", server_url, ": ", err)

if __name__ == "__main__":
    devices = []
    port = 9093
    server_url = ""
    interval = 60

    if len(argv) != 2:
        print("Error: exec program with '", __name__, " config.yml'")
        exit(1)

    try:
        with open(argv[1], encoding="utf-8") as f:
            data = yaml.load(f, SafeLoader)
            if "port" in data:
                port = data["port"]
            if "devices" in data:
                devices = data["devices"]
            if "interval" in data:
                interval = data["interval"]
            if "server_url" in data:
                server_url = data["server_url"]
            else:
                print("missing server_url in config")
                exit(1)
    except FileNotFoundError:
        print(f"Configuration file not found: {argv[1]}")
        exit(1)
    except ParserError:
        print(f"Invalid configuration file: {argv[1]}")
        exit(1)

    while True:
        task(devices, server_url)
        sleep(interval)

