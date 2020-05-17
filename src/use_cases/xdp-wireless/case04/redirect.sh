#!/bin/bash

# Almacenamos la información necesaria para realizar el forwarding
src="ap1-eth2"
dest="ap1-wlan1"
src_mac="02:02:02:02:02:02"
dest_mac="08:01:01:01:01:11"

# Populamos los mapas BPF con la información útil para llevar a cabo el forwarding en ambas direcciones
./prog_user -d $src -r $dest --src-mac $src_mac --dest-mac $dest_mac
./prog_user -d $dest -r $src --src-mac $dest_mac --dest-mac $src_mac
