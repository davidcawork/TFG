# XDP Wireless - Case02: Pass

En este test probaremos que es posible admitir todos los paquetes recibidos haciendo uso de la tecnología XDP. ¿Admitir? Si admitir, ya que, aunque XDP mucha gente lo concibe para hacer un by-pass al stack de red del Kernel de Linux en muchas ocasiones será util trabajar en conjunto para conseguir la funcionalidad deseada. Para la realizar la prueba, al igual que en el [``case01``](https://github.com/davidcawork/TFG/tree/master/src/use_cases/xdp-wireless/case01) primero deberemos compilar nuestro programa XDP, acto seguido levantar el escenario donde se va a realizar la prueba, y por último anclar el binario a un interfaz del escenario.

## Compilación

Para compilar el programa XDP se ha dejado un Makefile preparado en este directorio al igual que en el [``case01``](https://github.com/davidcawork/TFG/tree/master/src/use_cases/xdp-wireless/case01), por lo que para compilarlo unicamente hay que  hacer un:

```bash
sudo make
```

Ahora bien, ¿Cómo se produce la compilación de nuestros programas XDP? Buena pregunta :smile: ! Como ya se ha podido ver los programas  XDP están escritos en lo que ya llaman un lenguaje C restringido, los cuales su nombre de secuencia siempre empieza por "xdp" ya que si no el verificador del Kernel no podrá saber de que tipo de bytecode se trata y lo rechazará.

Este código C restringido, se compilará haciendo uso del compilador de [``clang``](https://clang.llvm.org/) como frontend y del compilador [``LLVM``](http://llvm.org/) como backend, para conseguir un bytecode BPF y almacenarlo en un objeto ELF. Estos últimos serán los que se carguen en el Kernel (``*.o``).


Es curioso el hecho de entender, como pasamos de los hipotéticos programas XDP (C restringido) a bytecode BPF, ya que, cuando se indaga un poco más en XDP, se llega a la conclusión que XDP se podría ver como un framework de BPF para trabajar a nivel de NIC. Hay más factores que lo diferencian de los programas BPF como son las estructuras de datos que manejan, además de los metadatos pero al fin y al cabo, para anclar un programa XDP este debe antes ser "traducido" a un byte code BPF.


## Puesta en marcha del escenario

Para testear los programas XDP en un entorno inalámbrico, haremos Mininet-Wifi para emular las topologías de red. Esta herramienta de emulación es un fork de Mininet, la cuales hacen uso de  las Network Namespaces para conseguir aislar los nodos independientes de la red. Pero, ¿Qué es una Network Namespaces? Una network namespace consiste en una replica lógica de stack de red que por defecto tiene el kernel de Linux, rutas, tablas ARP, Iptables e interfaces de red.

Como ya comentábamos, para levantar el escenario solo tendremos que ejecutar el script en Python que hace uso de la API de Mininet-Wifi para generar toda la topología de red. Una vez ejecutado este abrirá la interfaz de linea de comandos de Mininet-Wifi, desde la cual podremos comprobar el funcionamiento de nuestro caso de uso. En este caso de uso en particular, se realiza la carga del programa XDP desde el propio script de python, [aquí](https://github.com/davidcawork/TFG/blob/master/src/use_cases/xdp-wireless/case01/runenv.py#L36) se puede ver, haciendo uso de la herramienta `xdp_loader` desarrollada para ello. Por tanto, como hemos dicho este script está autocontenido, por lo que solo deberemos ejecutarlo :smile::

```bash
sudo python runenv.py
```

Para limpiar nuestra máquina del escenario recreado anteriormente con Mininet-Wifi podríamos hacer un `sudo mn -c` pero se le recomienda al usuario que haga uso del target del Makefile destinado para ello, ya que adicionalmente limpiará los ficheros intermedios generados en el proceso de compilación de nuestro programa XDP. Ejecutando el siguiente comando limpiaríamos nuestra máquina:

```bash
sudo make clean
```

Por último únicamente indicar que el escenario recreado es el siguiente, compuesto exclusivamente de dos estaciones wireless, aisladas en sus propias network namespaces, y un punto de acceso corriendo el daemon de `Hostapd` para intercomunicar dichas estaciones wifi.

![scenario](../../../../img/use_cases/xdp-wireless/case02/scenario.png)


## Carga del programa  XDP

Ya tenemos escenario y el programa XDP compilado.. Es hora de cargarlo en el Kernel :smile:. Si usted no sabe de dónde ha salido el programa [``xdp_loader``](https://github.com/davidcawork/TFG/blob/master/src/use_cases/xdp/util/xdp_loader.c), qué nos aporta la librería [``libbpf``](https://github.com/torvalds/linux/tree/master/tools/lib/bpf), o por que no hacemos uso de la herramienta [``iproute2``](https://wiki.linuxfoundation.org/networking/iproute2) para cargar los programas XDP en el Kernel, por favor vuelva al [``case01``](https://github.com/davidcawork/TFG/tree/master/src/use_cases/xdp/case01) donde se intenta abordar todas estas dudas. Si aun así tiene alguna duda extra o considera que no se encuentra del todo explicado póngase en contacto conmigo o mis tutores.

Al loader le estamos indicando ``-d`` (device), ``-S`` para indicar que la carga sobre la interfaz se lleva a cabo en modo genérico,``-F`` (Force) para que haga un override en caso de que ya haya un programa XDP anclado a dicha interfaz y por último, le indicamos el ``--progsec`` (program section) utilizados en XDP para englobar distintas funcionalidades ya que en un mismo bytecode puede haber distintos programas XDP. 

```bash
# Linea 38 del script runenv.py
sudo ./xdp_loader -d sta1-wlan0 -F --progsec xdp_case02 -S
```

## Comprobación del funcionamiento

Una vez que el programa XDP fue anclado a la interfaz de la estación wifi ``sta1``, debemos asegurarnos de que funciona según lo esperado.. Puede que sea una prueba un poco simple, pero nos vale, ya que unicamente queremos verificar que nuestro programa anclado en la interfaz está pasando los paquetes que le llegan al stack de red. 

**Nota personal**: Desde que empece a trabajar con XDP, veía al stack de red de Linux como a un enemigo a batir, o "by-passear" :smile_cat: .. Ya que con XDP queremos conseguir definir de manera exclusiva el datapath que se desea implementar con un equipo que porte el Kernel de Linux, de esta manera conseguimos un performance superior ya que nos quitamos de encima toda la redundancia y capas que no nos son necesarias para el procesamiento de nuestro hipotético datapath. 

Ahora bien, en el transcurso  mi aprendizaje con esta tecnología he visto que en ocasiones trabajar de manera cooperativa con el stack de red puede reportarnos muchas facilidades (Se verá en el [``case04``](https://github.com/davidcawork/TFG/tree/master/src/use_cases/xdp/case04)) y muchas otras funcionalidades ya implementadas en este. No es cuestión de re-inventar la rueda, más que nada por que el performance que se puede llegar a ganar por hacer todo el procesamiento de manera exclusiva en la propia NIC, en mi opinión, no compensa con la robustez y fiabilidad que tendrá dicha funcionalidad en el stack de red de Linux. 


```bash
# Desanclamos el programa/s XDP de la interfaz sta1-wlan0
mininet-wifi> sta1 ./xdp_loader -S -d sta1-wlan0 -U

# Hacemos ping desde una estación wifi hacia la otra. Deberíamos tener conectividad.
mininet-wifi> sta2 ping sta1

# Ahora vamos anclar el programa XDP en la interfaz inalámbrica de la estación wifi y
# comprobar la conectividad de nuevo
mininet-wifi> sta1 ./xdp_loader -S -d sta1-wlan0 -F --progsec xdp_case02

# Hacemos de nuevo el ping, y si todo ha salido bien deberíamos tener conectividad :)
mininet-wifi> sta2 ping sta1
```

## Fuentes
* [clang](https://clang.llvm.org/)
* [LLVM](http://llvm.org/)
* [iproute2 - netns](http://man7.org/linux/man-pages/man8/ip-netns.8.html)
* [Network Namespaces](http://man7.org/linux/man-pages/man7/network_namespaces.7.html)
