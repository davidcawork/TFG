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

> Añadir foto del escenario generado

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

## Fuentes
