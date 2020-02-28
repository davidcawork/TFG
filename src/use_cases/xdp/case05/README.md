# XDP - Case05: Broadcast


## Compilación

```bash
make

clang -O2 -target bpf -I/usr/include/x86_64-linux-gnu -c bpf.c -o bpf.o

```




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

## Carga del programa  XDP

> Añadir literatura

```bash

sudo ip netns exec switch bash

  sudo ./xdp_loader -d switch xdp_pass
  sudo tc qdisc add dev switch ingress handle ffff:
  sudo tc filter add dev switch parent ffff: bpf obj bpf.o sec classifier flowid ffff:1 action bpf obj bpf.o sec action 
```

## Comprobación del funcionamiento

> Añadir literatura

```bash
arping 10.0.0.2/3
sudo ip netns exec uno tcpduml -l
sudo ip netns exec dos tcpduml -l
```

## Fuentes
