# XDP - Case04: Layer 3 forwarding


## Puesta en marcha del escenario

Para testear los programas XDP haremos uso de las Network Namespaces. Por ello, se ha dejado escrito un script para levantar el escenario haciendo uso de las network namespaces, y para su posterior limpieza. Para levantar el escenario hacemos un:

```bash
sudo ./runenv.sh -i
```

Para limpiar nuestra máquina del escenario hacemos un:

```bash
sudo ./runenv.sh -c
``` 






## Forwarding Hardcodeado

![scenario](../../../../img/use_cases/xdp/case04/scenario_01.png)

### Carga del programa  XDP

> Añadir literatura

```bash
Ir al prog_kern.c => ifindex (uno interface) | MAC (Entramos a la netns miramos la MAC de veth0)
make
sudo ip netns exec uno ./xdp_loader -d veth0 -F --progsec xdp_pass
sudo ./xdp_loader -d dos -F --progsec xdp_case04

```

### Comprobación del funcionamiento

> Añadir literatura

```bash
[xterm1] sudo ip netns exec dos ping {IP_veth0_uno}
[xterm2] sudo ip netns exec uno tcpdump -l
[xterm3] sudo ./xdp_stats -d dos
```
## Forwarding semi-Hardcodeado (BPF maps)

![scenario2](../../../../img/use_cases/xdp/case04/scenario_02.png)

### Carga del programa  XDP

> Añadir literatura

```bash
sudo ip netns exec uno ./xdp_loader -d veth0 -F --progsec xdp_pass
sudo ip netns exec dos ./xdp_loader -d veth0 -F --progsec xdp_pass
sudo ./xdp_loader -d uno -F --progsec xdp_case04_map
sudo ./xdp_loader -d dos -F --progsec xdp_case04_map


 local src="uno"
 local dest="dos"
 local src_mac=$(ip netns exec $src cat /sys/class/net/veth0/address)
 local dest_mac=$(ip netns exec $dest cat /sys/class/net/veth0/address)
 
 # set bidirectional forwarding
 ./xdp_prog_user -d $src -r $dest --src-mac $src_mac --dest-mac $dest_mac
 ./xdp_prog_user -d $dest -r $src --src-mac $dest_mac --dest-mac $src_mac

```

### Comprobación del funcionamiento

> Añadir literatura

```bash
ping from veth0(uno) to veth0(dos) [ y viceversa..]

sudo ./xdp_stats -d uno

ó

sudo ./xdp_stats -d dos

``` 

## Forwarding auto (Kernel FIBs)

![scenario3](../../../../img/use_cases/xdp/case04/scenario_03.png)

### Carga del programa  XDP

> Añadir literatura

```bash
sudo sysctl net.ipv4.conf.all.forwarding=1
sudo ./xdp_loader -d uno -F --progsec xdp_case04_fib
sudo ./xdp_loader -d dos -F --progsec xdp_case04_fib

sudo ip netns exec uno ./xdp_loader -d veth0 -F --progsec xdp_pass
sudo ip netns exec dos ./xdp_loader -d veth0 -F --progsec xdp_pass

sudo ./prog_user -d uno
sudo ./prog_user -d dos

```

### Comprobación del funcionamiento

> Añadir literatura

```bash 
sudo ./xdp_stats -d uno

ó
sudo ./xdp_stats -d dos

ping from veth0(uno) to veth0(dos) [ y viceversa..]
```

## Fuentes
