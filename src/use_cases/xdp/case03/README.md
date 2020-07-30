# XDP - Case03: Echo server

In this test we will go into the package parsing, filtering and handling. In the previous cases of use exclusively we defined a behavior of the packets making an exclusive use of the XDP return codes, more specifically ``XDP_DROP`` to throw the packets and ``XDP_PASS`` to admit the packets. There are more XDP return codes, but we cannot develop all the possible logics with them, they can be consulted in the following header file [``bpf.h``](https://github.com/torvalds/linux/blob/master/include/uapi/linux/bpf.h#L3298). In the following table you can see all the XDP return codes.

<div align="center">
  
  <br>

|     **Return Codes**    |     **Behavior** |
|:-------------:|:-------------:|
| ``XDP_PASS`` | Admit the packet, pass it to the network stack |
| ``XDP_DROP`` |  Drop the packet |
| ``XDP_ABORTED``  | Drop the packet and generate an xdp:xdp_exception, useful to debug. |
| ``XDP_REDIRECT`` | Useful to forward a packet to another interface. |
| ``XDP_TX`` | Re-transmit the packet through the same interface through which the packet was received |

<br>

</div>


Now, how can we implement more advanced logic? By filtering the packets and based on the type of packet apply an action or other. To filter packets we will have to make use of the data structures of the network protocols defined in the Linux Kernel, in addition to make numerous checks of memory access limits so that the Kernel verifier does not throw the packet away. What data structures are available to us to filter packets?

<div align="center">
  
  <br>

| **Structure**            | **Header file**       |
|:-------------:|:-------------:|
| ``struct ethhdr``   | ``<linux/if_ether.h>`` |
| ``struct ipv6hdr``  | ``<linux/ipv6.h>``     |
| ``struct iphdr``    | ``<linux/ip.h>``       |
| ``struct icmp6hdr`` | ``<linux/icmpv6.h>``   |
| ``struct icmphdr``  | ``<linux/icmp.h>``    |

<br>

</div>

Since the packets come through the network in a byte order called network byte order, you will need to translate it into the byte order used by your machine (Host order), by using the ``bpf_ntohs`` and ``bpf_htons`` functions.

Knowing now which data structures to use to filter the packets, in this test, to put it into practice, we will filter all the ICMP - ICMPv6 type packets with an ICMP-ECHO code. The rest of the packets will be passed to the network stack for him to handle. As for the filtered ICMP packets we will answer them ourselves in the NIC, changing the ICMP-ECHO for an ICMP-REPLY, changing MACs, and updating the checksum. As in this case the packet must be forwarded by the same interface by which it was received, we will make use of ``XDP_TX`` return code.


## XDP restrictions

Now, we have said that the access to the package would be done directly in memory, but how do we know which direction to point to read the package? Very good question, every time an XDP program is executed it will receive by arguments a pointer to an xdp md structure that contains all the information associated to the packet. This structure is defined in the following header file [``bpf.h``](https://github.com/torvalds/linux/blob/master/include/uapi/linux/bpf.h). Its definition is as follows:


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

The last two elements of the structure are data fields that tell us the ``ifindex`` and ``index of the queue`` by which it has been received. The first three fields of the structure are pointers to the beginning of the packet, to the end of the packet and to the packet's metadata.

The kernel checker, when the XDP program is loaded, will rewrite the pointer accesses to the packet to the current address where the packet is in memory. It is very common to see the following lines at the beginning of XDP programs


```C

void *data_end = (void *)(long)ctx->data_end;
void *data = (void *)(long)ctx->data;

```

This is because the compiler applies a type check and will give an error if we don't cast u32 pointers to void. This is because u32 fields are actually 32-bit addresses, so casting to void pointers will serve as a wildcard to keep you going and satisfy the compiler.

### Checking package access limits

As mentioned above, packages are accessed by direct memory access, knowing that the verifier will ensure that such access is secure. However, doing this at runtime for each pointer access would result in significant performance overhead. Therefore, what the tester does is check that the XDP program does its own limit checking on its own logic by providing the ``data_end`` pointer.


When the verifier performs its static analysis at load time, it will track all memory addresses used by the program, and look for comparisons with the data end pointer, which will be placed at the end of the package at run time


### Inline loops and functions

Since XDP can be seen as a framework for eBPF, it also shares its limitations such as function call limitations and loops. Therefore, many of the functions that will be developed in our XDP programs will need to be inline ( ``__always_inline``) so that the compiler can replace them as they are in the code, achieving an improvement in performance since it is not necessary to make a function call with all that this entails (context change, record saving, PC change), and also avoiding the limitations of function calls to the verifier.


As for loop limitation, eBPF does not support loops, we must unwind the loops. Unroll? Yes, for example:


```C
for ( int i = 0; i < 4 ; i++)
 printf("Contador %d \n", i);

// If we unroll the loop:
printf("Contador %d \n", 0);
printf("Contador %d \n", 1);
printf("Contador %d \n", 2);
printf("Contador %d \n", 3);

```

To achieve this we must add the following statement before the pragma unroll loop. This declaration is only valid when the number of iterations in the loop is known at compile time.

## Compilation

To compile the XDP program a Makefile has been left prepared in this directory as well as in the [``case02``](https://github.com/davidcawork/TFG/tree/master/src/use_cases/xdp/case02), so to compile it you only need to make a

```bash
make
```

If you are in doubt about the process of compiling the XDP program, we recommend that you return to [``case02``](https://github.com/davidcawork/TFG/tree/master/src/use_cases/xdp/case02) where the flow arranged for compiling the programs is referred to.


## Setting up the scenario

To test the XDP programs we will use the Network Namespaces. If you don't know what the Network Namespaces are, or the concept of namespace in general, we recommend that you read the [``case01``] (https://github.com/davidcawork/TFG/tree/master/src/use_cases/xdp/case01) where a short introduction to the Network Namespaces is given, what they are and how we can use them to emulate our Network scenarios. 

As we mentioned before, in order to avoid the concept of the Network Namespaces being a barrier to entry, a script has been written to raise the scenario, and to clean it up afterwards. It is important to note that the script must be launched with root permissions. To raise the scenario we must execute the script in the following way:


```bash
sudo ./runenv.sh -i
```

To clean our machine from the previously recreated scenario we can run the same script indicating now the -c (Clean) parameter. To some bad, and if it is believed that the cleaning has not been done in a satisfactory way, we can make a reboot of our machine obtaining this way that all the not persistent entities(veth, netns..) disappear of our computer.

```bash
sudo ./runenv.sh -c
```

The scenario we will handle in this use case is the following, composed only of a Network namespace and a couple of veth's to communicate the Network namespace created with the default Network namespace.

![scenario](../../../../img/use_cases/xdp/case03/scenario.png)

## Loading the XDP program

We already have a stage and the compiled XDP program.. It's time to load it into the Kernel :smirk:. If you don't know where the program [``xdp_loader``](https://github.com/davidcawork/TFG/blob/master/src/use_cases/xdp/util/xdp_loader.c) came from, what the library [``libbpf``](https://github.com/torvalds/linux/tree/master/tools/lib/bpf) gives us, or why we don't use the tool [``iproute2``](https://wiki.linuxfoundation.org/networking/iproute2) to load the XDP programs into the Kernel, please go back to [``case01``(https://github.com/davidcawork/TFG/tree/master/src/use_cases/xdp/case01) where we try to tackle all these questions. If you still have additional questions or feel that they are not fully explained, please contact me or my tutors.

In addition, we would like to mention that we will be using the ``netns`` module of the tool [``iproute2``](https://wiki.linuxfoundation.org/networking/iproute2), if you have any doubt about it, we recommend that you consult its man-pages or go back to [``case02``](https://github.com/davidcawork/TFG/tree/master/src/use_cases/xdp/case02) where a small introduction is made about it, and its basic operation to execute commands "inside" a Namespace Network.


```bash

# Anchor the XDP program (xdp_pass) in the veth0 interface, belonging to the Network Namespace "uno". 
sudo ip netns exec uno ./xdp_loader -d veth0 -F --progsec xdp_pass

# We anchor the XDP program in interface one, belonging to the Network Namespace by default.
sudo ./xdp_loader -d uno -F --progsec xdp_case03

```

In this case of use let's clarify the XDP program to be validated in the external ``veth``, so the tests will be induced from "inside'' the Network Namespace ``uno``. To anchor the program we have used again the program [``xdp_loader``](https://github.com/davidcawork/TFG/blob/master/src/use_cases/xdp/util/xdp_loader.c). It is important to point out how we have had to anchor a *dummy program* that allows to pass all the packages to the destination veth, this is a limitation of its own because it works with ``veth's`` and XDP, at the moment it is an implementation limitation, maybe in a short term this limitation will be already overcome. For more information about this limitation we recommend to see the [Netdev](https://netdevconf.info) talk called **_Veth XDP: XDP for containers_** where they explain in more detail this limitation, how to address it and why it is induced.  [Link to the talk](https://netdevconf.info/0x13/session.html?talk-veth-xdp)


## Testing

The verification of the functioning of the XDP program anchored to the ``uno`` interface will be carried out by generating pings from "inside" the Network Namespace ``uno`` to the outside, so that the ``uno`` interface filters them, analyses them and generates a response. I would also like to mention that the program supports both IPv4 and IPv6 addressing. Its functionality was extended due to the fact that most of the documentation found on XDP, where examples such as this one are carried out, makes use of IPv6 addressing.


```bash

# We pinged from "inside" Network Namespace to the external interface 
sudo ip netns exec uno ping 10.0.0.1

# In a different console we launched the program xdp_stats to see in real time the XDP return codes used
sudo ./xdp_stats -d uno
```

If everything works correctly we should see how the return codes mostly used are the from ``XDP_TX`` as long as we haven't stopped pinging from inside the Network
Namespace. The operation of this program is very simple, since from the program anchored in the Kernel we generate a map where the statistics on the XDP return codes are going to be stored, and then the ``xdp_stats`` program, user space program, knowing the name of the BPF map where the statistics are stored will look for them and print them on screen periodically.

## References

* [Veths y XDP Conference](https://netdevconf.info/0x13/session.html?talk-veth-xdp)
* [Maps eBPF](https://prototype-kernel.readthedocs.io/en/latest/bpf/ebpf_maps.html)


---



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

Ahora bien, hemos dicho que el acceso al paquete se haría de forma directa en memoria, pero, ¿Cómo sabemos nosotros a que dirección apuntar para leer el paquete? Muy buena pregunta, cada vez que un programa XDP es ejecutado este recibirá por argumentos un puntero a una estructura struct xdp md que contiene toda la información asociada al paquete. Esta estructura está definida en el siguiente archivo de cabecera [``bpf.h``](https://github.com/torvalds/linux/blob/master/include/uapi/linux/bpf.h). Su definición es la siguiente:

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

Ya tenemos escenario y el programa XDP compilado.. Es hora de cargarlo en el Kernel :smirk:. Si usted no sabe de dónde ha salido el programa [``xdp_loader``](https://github.com/davidcawork/TFG/blob/master/src/use_cases/xdp/util/xdp_loader.c), qué nos aporta la librería [``libbpf``](https://github.com/torvalds/linux/tree/master/tools/lib/bpf), o por que no hacemos uso de la herramienta [``iproute2``](https://wiki.linuxfoundation.org/networking/iproute2) para cargar los programas XDP en el Kernel, por favor vuelva al [``case01``](https://github.com/davidcawork/TFG/tree/master/src/use_cases/xdp/case01) donde se intenta abordar todas estas dudas. Si aun así tiene alguna duda extra o considera que no se encuentra del todo explicado póngase en contacto conmigo o mis tutores.

De forma adicional comentar que se va hacer uso del módulo ``netns`` de la herramienta [``iproute2``](https://wiki.linuxfoundation.org/networking/iproute2), si tiene alguna duda sobre este le recomendamos que consulte sus man-pages o vuelva al [``case02``](https://github.com/davidcawork/TFG/tree/master/src/use_cases/xdp/case02) donde se hace una pequeña introducción sobre éste, y su funcionamiento básico para ejecutar comandos "dentro" de una Network Namespace.


```bash

# Anclamos el programa XDP (xdp_pass) en la interfaz veth0, perteneciente a la Network Namespace "uno" 
sudo ip netns exec uno ./xdp_loader -d veth0 -F --progsec xdp_pass

# Anclamos el programa XDP en la interfaz uno, perteneciente a la Network Namespace por defecto.
sudo ./xdp_loader -d uno -F --progsec xdp_case03

```

En este caso de uso aclaremos el programa XDP a validar en la ``veth`` exterior, por lo que las pruebas vendrán induccidas desde "dentro" de la Network Namespace ``uno``. Para anclar el programa hemos hecho uso de nuevo del programa [``xdp_loader``](https://github.com/davidcawork/TFG/blob/master/src/use_cases/xdp/util/xdp_loader.c). Es importante señalar como hemos tenido que anclar un *dummy program* que permite pasar todos los paquetes a la veth destino, esta es una limitación propia por trabajar con ``veth's`` y XDP, de momento se trata de una limitación de implementación, puede que a un corto plazo esta limitación se vea ya superada. Para más inforación sobre esta limitación recomendamos ver la charla de la [Netdev](https://netdevconf.info) llamada **_Veth XDP: XDP for containers_** donde explican con un mayor detalle esta limitación, como abordarla y por que está inducida.  [Enlace a la charla](https://netdevconf.info/0x13/session.html?talk-veth-xdp)


## Comprobación del funcionamiento

La comprobación del funcionamiento del programa XDP anclado a la interfaz ``uno`` se llevará a cabo generando pings desde "dentro" la Network Namespace ``uno`` hacia afuera, para que la interfaz ``uno`` los filtre, analice y nos genere una respuesta. De forma adicional comentar que el programa soporta tanto direccionamiento IPv4 como IPv6, su funcionalidad se vio extendida debido a que la gran parte de la documentación encontrada sobre XDP donde llevan a cabo ejemplos como este hacen uso de direccionamiento IPv6 por lo que, a modo personal, me pareció un buen punto seguir esta corriente ya que el direccionamiento IPv4 se ha agotado este mismo [año](https://www.ripe.net/manage-ips-and-asns/ipv4/ipv4-run-out)  :cold_sweat: ..


```bash

# Lanzamos un ping desde "dentro" Network Namespace hacia la interfaz externa 
sudo ip netns exec uno ping 10.0.0.1

# En una consola aparte lanzamos el programa xdp_stats para ir viendo a tiempo real los códigos de retorno XDP empleados
sudo ./xdp_stats -d uno
```

Si todo funciona correctamente deberíamos ver como los códigos de retorno mayormente empleados son los 
de ``XDP_TX`` siempre y cuando no hayamos detenido el ping desde dentro de la Network
Namespace. El funcionamiento de este programa es muy simple, ya que desde el programa anclado en el Kernel
generamos un mapa donde se van a almacenar las estadísticas sobre los códigos de retorno XDP , y después el programa ``xdp_stats``, programa de espacio de usuario, sabiendo el nombre del mapa BPF donde  se almacenan las estadísticas va a buscarlas y las imprime por pantalla de forma periódica.

## Fuentes

* [Conferencia Veths y XDP](https://netdevconf.info/0x13/session.html?talk-veth-xdp)
* [Mapas eBPF](https://prototype-kernel.readthedocs.io/en/latest/bpf/ebpf_maps.html)

