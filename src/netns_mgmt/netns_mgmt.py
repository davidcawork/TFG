#!/usr/bin/python

import os
from ctypes import cdll

# We make use of the setns system call from the libc library
#
# Check this out: http://man7.org/linux/man-pages/man2/setns.2.html
# 
libc = cdll.LoadLibrary('libc.so.6')
setns_func = libc.setns


class Netns_mgmt(object):
   
	"Class to manage the Network namespace in runtime"    
    

	def __init__(self, nsname=None, nspath=None, nspid=None):
		"The libc setns function is used to switch the current process between the different Netns."

		self.current_path = Netns_mgmt.get_netns_path(netns_pid=os.getpid())
		self.target_path = Netns_mgmt.get_netns_path(netns_path=nspath, netns_name=nsname, netns_pid=nspid)

		if not self.target_path:
			raise ValueError('invalid namespace')


	def __enter__(self):
		"We enter the netns, via name or via pid"

		if os.getuid() != 0:
			raise ValueError('Netns_mgmt must run as root.')

		self.current_ns = open(self.current_path)
		with open(self.target_path) as fd:
			setns_func(fd.fileno(), 0)


	def __exit__(self, *args):
		"We left the netns, going back to the original netns"

		setns_func(self.current_ns.fileno(), 0)
		self.current_ns.close()


	@staticmethod 
	def get_netns_path(netns_path=None, netns_name=None, netns_pid=None):

		if netns_name:
			netns_path = '/var/run/netns/' + str(netns_name)
		elif netns_pid:
			netns_path = '/proc/'+ str(netns_pid) +'/ns/net'

		return netns_path

