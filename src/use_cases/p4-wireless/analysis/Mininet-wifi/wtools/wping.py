#!/usr/bin/python3

from scapy.all import *
import socket, subprocess



class wPing():

	""" Ping wireless """

	def __init__(self, intf='mon0', mac_receiver='ff:ff:ff:ff:ff:ff', mac_dst='ff:ff:ff:ff:ff:ff', ip_dst=None, ping=None):
		""" intf:         interface name (default mon0)
		    mac_receiver: next hop MAC
		    mac_dst:	  destination MAC 
		    ping:	  custom scapy ping """
	
		self.sock    = None
		self.Intf    = intf
		self.src_mac = None
		self.dst_mac = mac_dst
		self.rcv_mac = mac_receiver
		self.dst_ip  = ip_dst
		self.ping    = ping

		self.config()
		if ping is None:
			self.build()
		

	def config(self):
		""" Get socket to the given intf and configure params """
		try:
			self.sock = socket.socket(socket.AF_PACKET, socket.SOCK_RAW)
			self.sock.bind((self.Intf, 0))
		except:
			print('Oops! Unable to get a socket raw with the interface - ' + self.Intf)

		
		self.src_mac = subprocess.check_output('cat /sys/class/net/'+self.Intf+'/address', stderr=subprocess.STDOUT, shell=True).decode('utf-8').split("\n")[0]



	def build(self):
		""" Build ping with scapy classes"""
		self.ping =  RadioTap() / Dot11( FCfield=0x01, addr1=self.rcv_mac, addr2=self.src_mac, addr3=self.dst_mac, addr4=self.src_mac) / LLC() / SNAP() / \
			     IP(dst=self.dst_ip) / ICMP(id=0x178b)


	def run(self):
		self.sock.send(bytes(self.ping))


if __name__ == "__main__":

	wireless_ping = wPing('mon0', '02:00:00:00:02:00', '02:00:00:00:01:00', '10.0.0.2')
	wireless_ping.run()

