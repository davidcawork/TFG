# XDP - Case03: Echo server

## Compilación

```bash
make
```

Ya tendríamos compilado el programa XDP, podrá observar que en su directorio se han generado varios ficheros con extensiones ``*.ll``, ``*.o``,  varios ejecutables que utilzaremos más adelante para anclar programas xdp en interfaces (``xdp_loader``), y para comprobar los códigos de retorno de nuestros porgramas xdp una vez ya anclados (``xdp_stats``).


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

sudo ip netns exec uno ./xdp_loader -d veth0 -F --progsec xdp_pass
sudo ./xdp_loader -d uno -F --progsec xdp_case03

```

## Comprobación del funcionamiento

> Añadir literatura

```bash
sudo ip netns exec uno ping 10.0.0.1
sudo ./xdp_stats -d uno
```

## Fuentes
