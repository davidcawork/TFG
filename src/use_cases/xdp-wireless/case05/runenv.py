#!/usr/bin/python

# SPDX-License-Identifier: (GPL-2.0 OR BSD-2-Clause)
#
#       Author: David Carrascal <davidcawork@gmail.com>
#       Date:   15 May  2020

from mininet.log import setLogLevel, info
from mn_wifi.cli import CLI
from mn_wifi.net import Mininet_wifi
from mn_wifi.node import UserAP

class Mininet_Wifi(Mininet_wifi):
    def configureControlNetwork(self):
        pass


def topology():
    "Create a network."
    net = Mininet_wifi()

    info("*** Creating nodes\n")
    sta1 = net.addStation('sta1', mac='08:01:01:01:01:11', ip='10.0.0.1/8', position='15,35,0',range=20)
    sta2 = net.addStation('sta2', mac='02:02:02:02:02:02', ip='10.0.0.2/8', position='25,35,0',range=20)
    h1 = net.addHost('h1', mac='8a:84:a4:92:34:9e', ip='10.0.0.3/8', position='27,35,0')
    ap1 = net.addAccessPoint('ap1', cls=UserAP, inNamespace=True, ssid='ssid-ap1', mode='g', channel='1', position='15,30,0', range=30)


    info("*** Configuring wifi nodes\n")
    net.configureWifiNodes()

    info("*** Creating links\n")
    net.addLink(sta1, ap1)
    net.addLink(sta2, ap1)
    net.addLink(h1, ap1)

    net.plotGraph(max_x=100, max_y=100)
    
    info("*** Starting network\n")
    net.build()
    ap1.start([])

    info("*** Loading XDP program\n")
    ap1.cmd("mount -t bpf bpf /sys/fs/bpf/")
    ap1.cmd("ulimit -l unlimited")

    info("*** Running CLI\n")
    CLI(net)

    info("*** Stopping network\n")
    net.stop()


if __name__ == '__main__':
    setLogLevel('info')
    topology()

