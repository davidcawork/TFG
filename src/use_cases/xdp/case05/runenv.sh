#!/bin/bash

# Creamos ns
sudo ip netns add uno
sudo ip netns add dos
sudo ip netns add switch

# Creamos interfaces y las colocamos en cada ns
sudo ip link add uno type veth peer name veth0
sudo ip link set veth0 netns uno
sudo ip link set uno netns switch
sudo ip link add dos type veth peer name veth0
sudo ip link set veth0 netns dos
sudo ip link set dos netns switch
sudo ip link add switch type veth peer name gateway
sudo ip link set switch netns switch

# Dar IPs y levantar 
sudo ip link set gateway up
sudo ip addr add 10.0.0.1/24 dev gateway
sudo ip netns exec switch ip link set switch up
sudo ip netns exec switch ip link set uno up
sudo ip netns exec switch ip link set dos up
sudo ip netns exec uno ip link set veth0 up
sudo ip netns exec uno ip addr add 10.0.0.2/24 dev veth0
sudo ip netns exec dos ip link set veth0 up
sudo ip netns exec dos ip addr add 10.0.0.3/24 dev veth0





