#!/usr/bin/python

# SPDX-License-Identifier: (GPL-2.0 OR BSD-2-Clause)
#
#       Author: David Carrascal <davidcawork@gmail.com>
#       Date:   10 May  2020

import os

from mininet.log import setLogLevel, info
from mn_wifi.cli import CLI
from mn_wifi.net import Mininet_wifi
from mn_wifi.bmv2 import P4RuntimeAP

def topology():
    'Create a network.'
    net = Mininet_wifi()

    info('*** Adding stations/hosts\n')
    sta1 = net.addStation('sta1', ip='10.0.1.1', mac='08:00:00:00:01:11')
    sta2 = net.addStation('sta2', ip='10.0.2.2', mac='08:00:00:00:02:22')
    sta3 = net.addStation('sta3', ip='10.0.3.3', mac='08:00:00:00:03:33')

    info('*** Adding P4RuntimeAP\n')
    ap1 = net.addAccessPoint('ap1',  cls=P4RuntimeAP, json_path='build/case04.json', runtime_json_path='runtime/ap1-runtime.json', 
			     log_console = True, log_dir = os.path.abspath('logs'), log_file = 'ap1.log', pcap_dump = os.path.abspath('pcaps'))

    ap2 = net.addAccessPoint('ap2',  cls=P4RuntimeAP, json_path='build/case04.json', runtime_json_path='runtime/ap2-runtime.json', 
			     log_console = True, log_dir = os.path.abspath('logs'), log_file = 'ap2.log', pcap_dump = os.path.abspath('pcaps'))
    
    ap3 = net.addAccessPoint('ap3',  cls=P4RuntimeAP, json_path='build/case04.json', runtime_json_path='runtime/ap3-runtime.json', 
			     log_console = True, log_dir = os.path.abspath('logs'), log_file = 'ap3.log', pcap_dump = os.path.abspath('pcaps'))
    
    
    net.configureWifiNodes()


    info('*** Creating links\n')
    net.addLink(sta1, ap1)
    net.addLink(sta2, ap2)
    net.addLink(sta3, ap3)
    net.addLink(ap1, ap2)
    net.addLink(ap1, ap3)
    net.addLink(ap2, ap3)


    info('*** Starting network\n')
    net.start()
    net.staticArp()

    info('*** Running CLI\n')
    CLI(net)

    info('*** Stopping network\n')
    net.stop()


if __name__ == '__main__':
    setLogLevel('info')
    topology()
