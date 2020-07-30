# XDP Wireless - Case01: Drop

In this test we will prove that it is possible to discard all received packets by using XDP technology. To perform the test, we must first compile our XDP program, build the scenario where the test will be performed, anchor the binary to an interface of the scenario and observe the results when we generate traffic that goes through that interface.

## Compilation

To compile the XDP program a Makefile has been left prepared in this directory, so it is not necessary to understand the whole compilation process. We will detail this process later, but for now and since it is the first case of use, and maybe the first contact with this technology, we do not want to saturate the reader. So we exclusively make a:

```bash
sudo make
```

We would have already compiled the XDP program, you will notice that in its directory several files have been generated with extensions ``*.ll``, ``*.o``, several executables that we will use later to anchor xdp programs in interfaces (``xdp_loader``), and to check the return codes of our xdp programs once already anchored (``xdp_stats``).


## Setting up the scenario

To test the XDP programs in a wireless environment, we will do Mininet-Wifi to emulate the network topologies. This emulation tool is a Mininet fork, which makes use of the Network Namespaces to isolate the independent nodes of the network. But what is a Network Namespaces? A network namespace consists of a logical network stack replica that by default has the Linux kernel, routes, ARP tables, Iptables and network interfaces.

Linux starts with a default Network namespace, with its routing table, with its ARP table, with its Iptables and network interfaces. But it is also possible to create more non-default network namespaces, create new devices in those namespaces, or move an existing device from one namespace to another. In this way, each element of the "network" has its own network namespace, that is, each element has its own network stack and interfaces. So at the networking level, as you might say, they can be seen as independent elements.

To raise the scenario we will only have to execute the script in Python that makes use of the Mininet-Wifi API to generate all the network topology. Once executed, it will open the Mininet-Wifi command line interface, from which we will be able to check the operation of our use case. In this particular use case, the XDP program is loaded from the python script itself, [here](https://github.com/davidcawork/TFG/blob/master/src/use_cases/xdp-wireless/case01/runenv.py#L36) you can see it, using the `xdp_loader` tool developed for it. So, as we said this script is self-contained, so we just need to run it :smile::

```bash
sudo python runenv.py
```

To clean our machine from the scenario previously recreated with Mininet-Wifi we could do a `sudo mn -c` but it is recommended that the user makes use of the Makefile target intended for this purpose, since it will additionally clean the intermediate files generated in the process of compiling our XDP program. Executing the following command would clean up our machine:

```bash
sudo make clean
```

Finally just indicate that the recreated scenario is the following, composed exclusively of two wireless stations, isolated in their own network namespaces, and an access point running the `Hostapd` daemon to intercommunicate these wifi stations.

![scenario](../../../../img/use_cases/xdp-wireless/case01/scenario.png)

## Loading the XDP program

Time to load our XDP program into the Kernel! How do we do it? There would be two ways to load our bytecode into the Kernel, the first would be to use the tool [``iproute2``](https://wiki.linuxfoundation.org/networking/iproute2) from version ``v4.12``. The second, and the most used due to the limitations of [``iproute2``](https://wiki.linuxfoundation.org/networking/iproute2) to work with BPF maps, is to use the library [``libbpf``](https://github.com/torvalds/linux/tree/master/tools/lib/bpf). In our case we will make use of a program made in C using that library to load our XDP programs into the kernel, BPF maps and so on.

The code of such program can be found [here](https://github.com/davidcawork/TFG/blob/master/src/use_cases/xdp/util/xdp_loader.c), this loader was developed following the Linux kernel developers tutorial called [xdp-tutorial](https://github.com/xdp-project/xdp-tutorial).

To the loader we are indicating ``-d`` (device), ``-S`` to indicate that the load on the interface is carried out in generic mode, ``-F`` (Force) to make an override in case there is already an XDP program attached to that interface and finally, we indicate the ``--progsec`` (program section) used in XDP to include different functionalities since in the same bytecode there can be different XDP programs. 

```bash
# Line 38 of the script runenv.py
sudo ./xdp_loader -d sta1-wlan0 -F --progsec xdp_case01 -S
```

## Testing

Once the XDP program was anchored to the interface of the ``sta1`` wifi station, we must make sure that it works as expected. We will do this by generating traffic from one wifi station to the other so that it passes through the interface that the XDP program is anchored to and we will observe its behaviour. In this case the expected behaviour is that it drops the packets as soon as they arrive at the interface, in this case the ``sta1-wlan0`` interface.


```bash

# We execute a ping from station sta2 to station sta1
mininet-wifi> sta2 ping sta1

# Additionally we can open an xterm in sta1, and start listening with a sniffer :)
mininet-wifi> xterm sta1

root@sta1~$ tcpdump -l

# Now that we've seen that we don't have connectivity, due to the XDP program, let's do an unload
# the XDP program, and we'll test the connectivity again.
mininet-wifi> sta1 ./xdp_loader -S -U -d sta1-wlan0


# We execute a ping from station sta2 to station sta1, and now yes, the connectivity should work.
mininet-wifi> sta2 ping sta1
```

## References 

* [Namespaces](http://man7.org/linux/man-pages/man7/namespaces.7.html)
* [Network Namespaces](http://man7.org/linux/man-pages/man7/network_namespaces.7.html)



---

# XDP Wireless - Case01: Drop

En este test probaremos que es posible descartar todos los paquetes recibidos haciendo uso de la tecnología XDP. Para la realizar la prueba, primero deberemos compilar nuestro programa XDP, levantar el escenario donde se va a realizar la prueba, anclar el binario a un interfaz del escenario y observar los resultados cuando generamos tráfico que atraviesa dicha interfaz.

## Compilación

Para compilar el programa XDP se ha dejado un Makefile preparado en este directorio, por lo que no es necesario entender todo el proceso de compilación. Más adelante se detallará este proceso pero de momento y dado que es el primer caso de uso, y puede que el primer contacto con esta tecnología, no se quiere saturar al lector. Por lo que exclusivamente hacemos un:

```bash
sudo make
```

Ya tendríamos compilado el programa XDP, podrá observar que en su directorio se han generado varios ficheros con extensiones ``*.ll``, ``*.o``,  varios ejecutables que utilizaremos más adelante para anclar programas xdp en interfaces (``xdp_loader``), y para comprobar los códigos de retorno de nuestros programas xdp una vez ya anclados (``xdp_stats``).


## Puesta en marcha del escenario

Para testear los programas XDP en un entorno inalámbrico, haremos Mininet-Wifi para emular las topologías de red. Esta herramienta de emulación es un fork de Mininet, la cuales hacen uso de  las Network Namespaces para conseguir aislar los nodos independientes de la red. Pero, ¿Qué es una Network Namespaces? Una network namespace consiste en una replica lógica de stack de red que por defecto tiene el kernel de Linux, rutas, tablas ARP, Iptables e interfaces de red.

Linux se inicia con un Network namespace por defecto, con su tabla de rutas, con su tabla ARP, con sus Iptables e interfaces de red. Pero también es posible crear más network namespaces no predeterminadas, crear nuevos dispositivos en esos espacios de nombres, o mover un dispositivo existente de un espacio de nombres a otro. De esta manera, cada elemento de la "red" tiene su propia network namespace, es decir, cada elemento tiene su propio stack de red e interfaces. Por lo que a nivel de networking como se diría se pueden ver como elementos independientes.

Para levantar el escenario solo tendremos que ejecutar el script en Python que hace uso de la API de Mininet-Wifi para generar toda la topología de red. Una vez ejecutado este abrirá la interfaz de linea de comandos de Mininet-Wifi, desde la cual podremos comprobar el funcionamiento de nuestro caso de uso. En este caso de uso en particular, se realiza la carga del programa XDP desde el propio script de python, [aquí](https://github.com/davidcawork/TFG/blob/master/src/use_cases/xdp-wireless/case01/runenv.py#L36) se puede ver, haciendo uso de la herramienta `xdp_loader` desarrollada para ello. Por tanto, como hemos dicho este script está autocontenido, por lo que solo deberemos ejecutarlo :smile::

```bash
sudo python runenv.py
```

Para limpiar nuestra máquina del escenario recreado anteriormente con Mininet-Wifi podríamos hacer un `sudo mn -c` pero se le recomienda al usuario que haga uso del target del Makefile destinado para ello, ya que adicionalmente limpiará los ficheros intermedios generados en el proceso de compilación de nuestro programa XDP. Ejecutando el siguiente comando limpiaríamos nuestra máquina:

```bash
sudo make clean
```

Por último únicamente indicar que el escenario recreado es el siguiente, compuesto exclusivamente de dos estaciones wireless, aisladas en sus propias network namespaces, y un punto de acceso corriendo el daemon de `Hostapd` para intercomunicar dichas estaciones wifi.

![scenario](../../../../img/use_cases/xdp-wireless/case01/scenario.png)

## Carga del programa  XDP

Hora de cargar nuestro programa XDP en el Kernel! ¿Cómo lo hacemos? Habría dos maneras de cargar nuestro bytecode en el Kernel, la primera sería hacer uso de la herramienta [``iproute2``](https://wiki.linuxfoundation.org/networking/iproute2) a partir de la versión ``v4.12``. La segunda, y la más utilizada debido a las limitaciones de [``iproute2``](https://wiki.linuxfoundation.org/networking/iproute2) para trabajar con los mapas BPF, es hacer uso de la libreria [``libbpf``](https://github.com/torvalds/linux/tree/master/tools/lib/bpf). En nuestro caso haremos uso de un programa hecho en C haciendo uso de dicha librería para cargar nuestros programas XDP en el kernel, mapas BPF y demás.

El código de dicho programa se puede encontrar [aquí](https://github.com/davidcawork/TFG/blob/master/src/use_cases/xdp/util/xdp_loader.c), este loader fue desarrollado siguiendo el tutorial de los desarrolladores del kernel de Linux llamado [xdp-tutorial](https://github.com/xdp-project/xdp-tutorial).

Al loader le estamos indicando ``-d`` (device), ``-S`` para indicar que la carga sobre la interfaz se lleva a cabo en modo genérico,``-F`` (Force) para que haga un override en caso de que ya haya un programa XDP anclado a dicha interfaz y por último, le indicamos el ``--progsec`` (program section) utilizados en XDP para englobar distintas funcionalidades ya que en un mismo bytecode puede haber distintos programas XDP. 

```bash
# Linea 38 del script runenv.py
sudo ./xdp_loader -d sta1-wlan0 -F --progsec xdp_case01 -S
```

## Comprobación del funcionamiento

Una vez que el programa XDP fue anclado a la interfaz de la estación wifi ``sta1``, debemos asegurarnos de que funciona según lo esperado. Esto lo haremos generando tráfico desde una estación wifi hacia la otra, para que atraviese por la interfaz que tiene anclado el programa XDP y observaremos su comportamiento. En este caso el comportamiento esperado es que haga un drop de los paquetes nada más llegar a la interfaz, en este caso la interfaz ``sta1-wlan0``.


```bash

# Ejecutamos un ping desde la estación sta2 hacia la estación sta1
mininet-wifi> sta2 ping sta1

# De forma adicional podemos abrir una xterm en la sta1, y ponernos a escuchar con un sniffer :)
mininet-wifi> xterm sta1

root@sta1~$ tcpdump -l

# Ahora que ya hemos visto que no tenemos conectividad, debido al programa XDP, vamos hacer un unload
# del programa XDP, y probaremos de nuevo la conectividad.
mininet-wifi> sta1 ./xdp_loader -S -U -d sta1-wlan0


# Ejecutamos un ping desde la estación sta2 hacia la estación sta1, y ahora si, debería funcionar la
# conectividad.
mininet-wifi> sta2 ping sta1
```

## Fuentes

* [Namespaces](http://man7.org/linux/man-pages/man7/namespaces.7.html)
* [Network Namespaces](http://man7.org/linux/man-pages/man7/network_namespaces.7.html)
