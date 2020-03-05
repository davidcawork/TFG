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

Dado que los paquetes vienen por la red en un byte order denominado como network byte order, se necesitará traducirlo al byte order usado por nuestra maquina ( Host order ), para ello, se hará uso de las funciones ```bpf_ntohs``` y ```bpf_htons```.

Sabiendo ahora que estructuras de datos utilizar para ir filtrando los paquetes, en este test, para ponerlo en práctica, filtraremos todos los paquetes de tipo ICMP - ICMPv6 con un código ICMP-ECHO. El resto de apquetes se los pasaremos al stack de red para que el lo maneje. En cuanto a los paquetes filtrados ICMP los contestaremos nosotros mismos en la propia NIC, cambiando el ICMP-ECHO por un ICMP-REPLY, cambiando MACs, y actualizando el checksum. Como en este caso el paquete debe ser reenviado por la misma interfaz por la cual se recibió, haremos uso de código de retorno ``XDP_TX``.

## Limitaciones XDP

Ahora bien, hemos dicho que el acceso al paquete se haría de forma directa en memoria, pero, ¿Cómo sabemos nosotros a que dirección apuntar para leer el paquete? Muy buena pregunta, cada vez que un programa XDP es ejecutado este recibirá por argumentos un puntero a una estructura struct xdp md que contiene toda la información asociada al paquete. Esta estructura está definida en el siguiente archivo de cabecera bpf.h. Su definición es la siguiente:

```C
struct xdp_md {
 __u32 data;
 __u32 data_end;
 __u32 data_meta;
 /* Below access go through struct xdp_rxq_info */
 __u32 ingress_ifindex; /* rxq->dev->ifindex */
 __u32 rx_queue_index; /* rxq->queue_index */
};

``` 

Los dos últimos elementos de la estructura son campos de datos que nos indican el ``ifindex`` y ``index de la cola`` por la cual ha sido recibido. Los tres primeros campos de la estructura, son punteros al inicio del paquete, al final del paquete y a los metadatos del mismo.

El verificador del kernel, cuando el programa XDP sea cargado, se encargará de reescribir los accesos hechos con los punteros al paquete a las direcciones actuales donde este se encuentre en memoria. Es muy común ver las siguientes lineas al principio de los programas XDP:


```C

void *data_end = (void *)(long)ctx->data_end;
void *data = (void *)(long)ctx->data;

```

Esto se debe a que el compilador aplica una comprobación de tipos y dará error si no hacemos un casting de u32 a punteros a void. Esto se debe a que los campos u32 en verdad son direcciones de 32 bits, por lo que si hacemos un casting hacia puntero void nos servirán como una wildcard para seguir adelante satisfaciendo al compilador.

### Comprobación de los limites de acceso al paquete

Como se mencionó antes, se accede a los paquetes mediante acceso directo a la memoria, sabiendo que el verificador se asegurará de que dichos accesos sean seguros. Sin embargo, hacer esto en tiempo de ejecución para cada acceso de puntero resultaría en una sobrecarga de rendimiento significativa. Por lo tanto, lo que el verificador hace es comprobar que el programa XDP hace su propia comprobación de límites en su propia lógica por ello se nos suministra el puntero ```data_end```.


Cuando el verificador realiza su análisis estático en tiempo de carga, rastreará todas las direcciones de memoria utilizadas por el programa, y buscará comparaciones con el puntero data end, el cual será puesto al final del paquete en tiempo de ejecución

### Bucles y funciones inline

Dado que XDP se puede ver como un framework de los eBPF, también comparte sus limitaciones como son las limitaciones de llamadas a funciones y los bucles. Por ello muchas de las funciones que se van a desarrollar en nuestros programas XDP necesitaran ser de un carácter inline ( ```__always_inline```) para que así el compilador las sustituya tal cual en código consiguiendo una mejora de performance ya que no hay que hacer una llamada a una función con todo lo que ello conlleva (Cambio de contexto, salvado de registros, cambio del PC), y además evitar las limitaciones de llamadas a funciones del verificador.

En cuanto a la limitación de los bucles, eBPF no soporta los bucles, debemos desenrollar los bucles. ¿Desenrollar? Si, por ejemplo:

```C
for ( int i = 0; i < 4 ; i++)
 printf("Contador %d \n", i);

// Si lo desenrollamos, quedaría así:
printf("Contador %d \n", 0);
printf("Contador %d \n", 1);
printf("Contador %d \n", 2);
printf("Contador %d \n", 3);

```

Para conseguir esto debemos añaadir la siguiente declaración antes del bucle pragma unroll. Esta declaración solo es valida cuando el numero de iteraciones del bucle es conocida en tiempo de compilación.

## Compilación

Para compilar el programa XDP se ha dejado un Makefile preparado en este directorio al igual que en el [``case02``](https://github.com/davidcawork/TFG/tree/master/src/use_cases/xdp/case02), por lo que para compilarlo unicamente hay que hacer un:

```bash
make
```
Si tiene dudas sobre el proceso de compilación del programa XDP le recomendamos que vuelva al [``case02``](https://github.com/davidcawork/TFG/tree/master/src/use_cases/xdp/case02) donde se hace referencia al flow dispuesto para la compilación de los programas.


## Puesta en marcha del escenario

Para testear los programas XDP haremos uso de las Network Namespaces. Si usted no sabe lo que son las Network Namespaces, o el concepto de namespace en general, le recomendamos que se lea el [``case01``](https://github.com/davidcawork/TFG/tree/master/src/use_cases/xdp/case01) donde se hace una pequeña introducción a las Network Namespaces, qué son y cómo podemos utilizarlas para emular nuestros escenarios de Red. 

Como ya comentabamos, para que no suponga una barrera de entrada el concepto de las Network Namespaces, se ha dejado escrito un script para levantar el escenario, y para su posterior limpieza. Es importante señalar que el script debe ser lanzado con permisos de root. Para levantar el escenario debemos ejecutar dicho script de la siguiente manera:

```bash
sudo ./runenv.sh -i
```

Para limpiar nuestra máquina del escenario recreado anteriormente podemos correr el mismo script indicándole ahora el parámetro -c (Clean). A unas malas, y si se cree que la limpieza no se ha realizado de manera satisfactoria, podemos hacer un reboot de nuestra máquina consiguiendo así que todos los entes no persistentes(veth, netns..) desaparezcan de nuestro equipo.

```bash
sudo ./runenv.sh -c
```

El escenario que vamos a manejar en este caso de uso es el siguiente, compuesto unicamente de una Network namespace y un par de veth's para comunicar la Network namespace creada con la Network namespace por defecto.

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
