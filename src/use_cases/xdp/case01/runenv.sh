#!/bin/bash

# Let's create netns
sudo ip netns add uno

# We've to create each interface and set into right netns
sudo ip link add uno type veth peer name veth0
sudo ip link set veth0 netns uno

# Finally assign Ip's, and raise each one of them. 
sudo ip link set uno up
sudo ip addr add 10.0.0.1/24 dev uno
sudo ip netns exec uno ip link set veth0 up
sudo ip netns exec uno ip addr add 10.0.0.2/24 dev veth0
