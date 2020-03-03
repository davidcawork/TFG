# XDP - Case03: Echo server

En este test nos adentraremos al parseo de paquetes, su filtrado y manejo. En los anteriores caso de uso exclusivamente definíamos un comportamiento de los paquetes haciendo un uso exclusivo de los códigos de retorno XDP, más concretamente ``XDP_DROP`` para tirar los paquetes y ``XDP_PASS`` para admitir los paquetes. Hay más códigos de retorno XDP pero con ellos no podemos lograr desarrollar todas las lógicas posibles, se pueden consultar en el siguiente archivo de cabecera [``bpf.h``](https://github.com/torvalds/linux/blob/master/include/uapi/linux/bpf.h#L3298). En la siguiente tabla se pueden contemplar todos los códigos de retorno XDP.

<div align="center">
  
  <br>

|     **Código de Retorno**    |     **Comportamiento** |
|:-------------:|:-------------:|
| ``XDP_PASS`` | Admitir el paquete, pasarselo al stack de red |
| ``XDP_DROP`` | Tirar el paquete |
| ``XDP_ABORTED``  | Tirar el paquete y generar una xdp:xdp_exception, útiles para depurar. |
| ``XDP_REDIRECT`` | Utilizado cuando se realiza un forwarding del paquete a otra interfaz |
| ``XDP_TX`` | Re-transmitir el paquete por la misma interfaz por la cual se ha recibido el paquete |

<br>

</div>

Ahora bien, ¿Cómo podemos implementar una lógica más avanzada? Filtrando los paquetes y en base al tipo de paquete aplicar un acciones u otras. Para filtrar paquetes tendremos que hacer uso de las estructuras de datos  de los protocolos de red definidas en  el Kernel de Linux, además hacer numerosas comprobaciones de limites de acceso a memoria para que el verificador del Kernel no nos tire el paquete. ¿Qué estructuras de datos están a nuestra disposición para filtrar paquetes?

<div align="center">
  
  <br>

| **Estructura**            | **Archivo de cabecera**       |
|:-------------:|:-------------:|
| ``struct ethhdr``   | ``<linux/if_ether.h>`` |
| ``struct ipv6hdr``  | ``<linux/ipv6.h>``     |
| ``struct iphdr``    | ``<linux/ip.h>``       |
| ``struct icmp6hdr`` | ``<linux/icmpv6.h>``   |
| ``struct icmphdr``  | ``<linux/icmp.h>``    |

<br>

</div>

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

![scenario](../../../../img/use_cases/xdp/case03/scenario.png)

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
