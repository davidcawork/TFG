from netns_mgmt import Netns_mgmt
from ctypes import *
import subprocess, os, unittest, time


class NamedNetns_test(unittest.TestCase):

    def setUp(self):
        print("Setting up the scenario")
        if os.getuid() != 0:
            raise ValueError('Netns_mgmt must run as root.')
        
        os.system('ip netns add test')
	

    def test(self):
        print("Running Netns_mgmt class")
        with Netns_mgmt(nsname = 'test'):
            output = subprocess.check_output(['ip', 'a', 's'])
        self.assertEqual(output, subprocess.check_output(['ip', 'netns', 'exec', 'test', 'ip', 'a', 's']))

    def tearDown(self):
        print("Teardown the scenario")
        os.system('ip netns del test')


class UnnamedNetns_test(unittest.TestCase):

    def setUp(self):
        print("Setting up the scenario")
        self.process = subprocess.Popen(['unshare','-n','/bin/bash'], shell=False, stdin=subprocess.PIPE, stdout=subprocess.PIPE)
		
        
    def test(self):
        print("Running Netns_mgmt class")
        with Netns_mgmt(nspid = self.process.pid):
            output = subprocess.check_output(['ip', 'a', 's'])
        self.assertEqual(output, subprocess.check_output(['nsenter', '-t', str(self.process.pid), '-n', 'ip', 'a', 's']))
    
    def tearDown(self):
        print("Teardown the scenario")
        self.process.kill()
        del(self.process)

if __name__ == '__main__':
    unittest.main() 
