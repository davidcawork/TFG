# XDP Wireless - Case04: Layer 3 forwarding

En este caso de uso exploraremos el forwarding de paquetes, en este punto ya sabemos como filtrar por las cabeceras de los paquetes, analizarlos y establecer una lógica asociada a ese filtrado con los códigos de retorno XDP. Una acción extra a realizar con los paquetes será el forwarding, en XDP vendrá implementado por códigos de retorno y por [``helpers BPF``](http://man7.org/linux/man-pages/man7/bpf-helpers.7.html), por que como ya comentábamos en el [case02](https://github.com/davidcawork/TFG/tree/master/src/use_cases/xdp-wireless/case02), XDP se termina traduciendo en BPF (eBPF), por lo que ciertas funciones, no todas, para trabajar con bpf están disponibles a la hora de trabajar con XDP. 

A lo largo de este caso de uso, se han explorado las distintas maneras para lograr el forwarding con XDP. Hemos ido desde la manera más simple a la manera más robusta y compleja. Para que no haya diferencias entre estas formas de realizar el forwarding, se ha creado un mismo escenario donde se explorarán estas vias sin que existan diferencias inducidas por este.

En el caso de uso anterior ya estábamos haciendo un forwarding, ya que, con el código ``XDP_TX`` estamos haciendo un forwarding hacia la interfaz por la cual se recibió dicho paquete. Pero, ¿Cómo hacemos un Forwarding hacia otras interfaces? ¿Cómo podemos encaminar un paquete que nos llega por una interfaz A y hacia otra interfaz B? Bien, leyendo la man-page de los [``helpers BPF``](http://man7.org/linux/man-pages/man7/bpf-helpers.7.html) nos encontramos con las funciones ``bpf_redirect()``, ``bpf_redirect_map()`` las cuales, leyendo su descripción, serán la vía utilizada para abordar esta necesidad.

```C

int bpf_redirect(u32 ifindex, u64 flags);

int bpf_redirect_map(struct bpf_map *map, u32 key, u64 flags);

```

Si nos fijamos en su definición ninguna de ellas opera con los ``sk_buff``, estructura de datos utilizada de forma muy frecuente en el stack de red del Kernel de Linux en el [case05](https://github.com/davidcawork/TFG/blob/master/src/use_cases/xdp/case05/) se explicará que limitaciones nos induce que alguno de los _helpers BPF_ hagan uso de ella. La primera de ellas, ``bpf_redirect()`` hace uso del ``ifindex`` como elemento identificador de la interfaz a la cual tiene que hacer el forwarding. En cuanto a la función ``bpf_redirect_map()`` hace uso de un mapa BPF y una _key_, recordemos que los mapas BPF son del tipo clave - valor, y en base a la key que le demos irá al mapa BPF buscara el valor asociado a esa clave, el cual, será un ``ifindex``. Esta última función la exploraremos más a fondo en este caso de uso.


## Compilación

Para compilar el programa XDP se ha dejado un Makefile preparado en este directorio al igual que en el [``case03``](https://github.com/davidcawork/TFG/tree/master/src/use_cases/xdp-wireless/case03), por lo que para compilarlo unicamente hay que hacer un:

```bash
sudo make
```
Si tiene dudas sobre el proceso de compilación del programa XDP le recomendamos que vuelva al [``case02``](https://github.com/davidcawork/TFG/tree/master/src/use_cases/xdp/case02) donde se hace referencia al flow dispuesto para la compilación de los programas.

## Puesta en marcha del escenario

Para testear los programas XDP en un entorno inalámbrico, haremos Mininet-Wifi para emular las topologías de red. Esta herramienta de emulación es un fork de Mininet, la cuales hacen uso de  las Network Namespaces para conseguir aislar los nodos independientes de la red. Pero, ¿Qué es una Network Namespaces? Una network namespace consiste en una replica lógica de stack de red que por defecto tiene el kernel de Linux, rutas, tablas ARP, Iptables e interfaces de red.

Como ya comentábamos, para levantar el escenario solo tendremos que ejecutar el script en Python que hace uso de la API de Mininet-Wifi para generar toda la topología de red. Una vez ejecutado este abrirá la interfaz de linea de comandos de Mininet-Wifi, desde la cual podremos comprobar el funcionamiento de nuestro caso de uso. En este caso de uso en particular, se realiza la carga del programa XDP desde el propio script de python, [aquí](https://github.com/davidcawork/TFG/blob/master/src/use_cases/xdp-wireless/case03/runenv.py#L37) se puede ver, haciendo uso de la herramienta `xdp_loader` desarrollada para ello. Por tanto, como hemos dicho este script está autocontenido, por lo que solo deberemos ejecutarlo :smile::

```bash
sudo python runenv.py
```

Para limpiar nuestra máquina del escenario recreado anteriormente con Mininet-Wifi podríamos hacer un `sudo mn -c` pero se le recomienda al usuario que haga uso del target del Makefile destinado para ello, ya que adicionalmente limpiará los ficheros intermedios generados en el proceso de compilación de nuestro programa XDP. Ejecutando el siguiente comando limpiaríamos nuestra máquina:

```bash
sudo make clean
```

## Forwarding Hardcodeado

El escenario levantado es el siguiente, está compuesto de una estación wireless y un host, que corren dentro de su respectivas Network Namespaces, y un punto de acceso corriendo un proceso de `Hostapd` para comunicar las dos estaciones wireless entre sí. De forma adicional, y por consistencia del caso de uso se ha decidido correr dicho switch dentro de su propia Network Namespace para que no haya lugar a dudas de que el forwarding se está realizando correctamente y no está habiendo "bypasses" de ningun tipo. En este caso el forwarding lo haremos desde la interfaz ``ap1-wlan1`` hacia la interfaz ``ap1-eth2``.


![scenario](../../../../img/use_cases/xdp-wireless/case04/scenario.png)


### Carga del programa  XDP

Antes de realizar la carga del programa **debemos obtener dos datos**, la **``ifindex`` de la interfaz ``ap1-eth2``** a la cual le vamos a mandar los paquetes generados desde la estación wireless `sta1`, y la **MAC** de la interfaz del host1, ya que será necesario que los paquetes que se dirijan a la interfaz ``ap1-wlan1`` lleven como MAC destino la de la ``ap1-eth2`` para que así los paquetes no sean descartados. Una vez tengamos estos datos anotados abriremos el programa xdp (``*.c``) cuan cualquier editor de texto, e iremos a la declaración de variables y hardcoderemos tanto el ``ifindex`` como la MAC. Por ejemplo:

```C 

    /*  Para un ifindex: 6 y una MAC: 9A:DE:AF:EC:18:6E */
    /*  Ojo con los 00's comentar error de validación por escritura de null en una estructura del Kernel*/
    ...
    
    unsigned char dst[ETH_ALEN + 1] = {0x9a,0xde,0xaf,0xec,0x18,0x6e, '\0'} ;
    unsigned ifindex = 6; 

    ...

```

Una vez que tengamos hardcodeado los datos para realizar el forwarding deberemos recompilar el programa XDP para que el bytecode que anclemos a la interfaz ``ap1-wlan1`` haga correctamente el forwarding. Por ello, simplemente tenemos que hacer un **``sudo make``** nuevamente. Ahora si :smile: .. Ya tenemos todo preparado para anclar de nuevo el programa XDP!

```bash
# Antes que nada, debemos lanzar el escenario en caso de que no lo hayamos hecho todavía.
sudo python runenv.py


# Ejecutamos el siguiente comando dentro de la Network Namespace del AP1, cargando así el
# programa XDP en la interfaz 1.
mininet-wifi> ap1 ./xdp_loader -d ap1-wlan1 -F --progsec xdp_case04 -S

```

### Comprobación del funcionamiento


La comprobación de funcionamiento de este programa XDP es bastante básica, vamos a generar paquetes desde la estación wireless `sta1` hacia el host, `h1`. Para ello abriremos dos terminales, en cada una de ellas llevaremos a cabo una tarea:


```bash

# Abrimos las dos terminales
mininet-wifi> xterm h1 sta1

# En la terminal del host1 pondremos a un sniffer a escuchar los paquetes que nos lleguen.
[Terminal:h1] tcpdump -l

# En la terminal de la sta1 lanzaremos pings contra el h1
[Terminal:sta1] ping 10.0.0.2

# Por último, opcionalmente, podemos ejecutar el programa que actuaba como recolector de estadísticas sobre los códigos de retorno XDP
mininet-wifi> ap1 ./xdp_stats -d ap1-wlan1

```
¿Por que no hay conectividad? Buena pregunta, no es que el programa no funcione, está funcionando lo puede ver en los códigos de retorno XDP, solo que la comunicación actualmente solo está soportada en un sentido, ya que solo estamos soportando el forwarding de la interfaz `ap1-wlan1` a la interfaz `ap1-eth2`. Actualmente el proceso de ping está detenido en la resolución ARP de la MAC asociada a la dirección IP 10.0.0.2, llegando los ARP - Request pero los ARP replay nunca llegarán a su destino :joy:.

```bash
# En la terminal de la sta1 lanzaremos pings contra el h1
[Terminal:sta1] arp -s 10.0.0.2 {MAC de la interfaz h1-eth0 del h1}
```

 Podemos de forma adicional, añadir la entrada ARP de forma estática a la Network Namespace de la estación wireless `sta1` pero el ping seguiría sin funcionar, ya que los paquetes ICMP REPLAY asociados a los  ECHO REQUEST recibidos nunca podrán llegar de vuelta a la estación wireless `sta1`. En el siguiente planteamiento del forwarding se abordará esta carencia en la comunicación con un nuevo planteamiento para conseguir un bidireccionalidad en la comunicación, a la par que escalable. 

## Forwarding semi-Hardcodeado (BPF maps)

El escenario levantado es el siguiente, está compuesto de una estación wireless y un host, que corren dentro de su respectivas Network Namespaces, y un punto de acceso corriendo un proceso de `Hostapd` para comunicar las dos estaciones wireless entre sí. De forma adicional, y por consistencia del caso de uso se ha decidido correr dicho switch dentro de su propia Network Namespace para que no haya lugar a dudas de que el forwarding se está realizando correctamente y no está habiendo "bypasses" de ningún tipo. En este caso el forwarding lo haremos desde la interfaz ``ap1-wlan1`` hacia la interfaz ``ap1-eth2`` y viceversa.


![scenario](../../../../img/use_cases/xdp-wireless/case04/scenario_B.png)

### Carga del programa  XDP

Esta manera de hacer el forwarding no requiere de hardcodear datos en el propio programa XDP que irá al Kernel, si no, que se usarán los mapas BPF como medio para guardar datos de forwarding como son las ``ifindex`` y las MAC destino desde espacio de usuario para que posteriormente el programa anclado en el Kernel sea capaz de leer los mapas, obtener la información de forwarding y realizarlo en base a la información percibida de los mapas BPF.


Es importante señalar que los programas anclados previamente deben ser removidos, por lo que una opción sería hacer un clean del escenario haciendo uso del Makefile dado ( ``sudo make clean``) y empezar de nuevo.


```bash

# Lnazamos el script que levanta el escenario
sudo python runenv.py

# Anclamos el programa XDP en cada interfaz para conseguir un comunicación bidireccional 
mininet-wifi> ap1 ./xdp_loader -d ap1-wlan1 -F --progsec xdp_case04_map -S
mininet-wifi> ap1 ./xdp_loader -d ap1-eth2 -F --progsec xdp_case04_map -S

# Almacenamos la información necesaria para realizar el forwarding y populamos los mapas BPF
# con la información útil para llevar a cabo el forwarding en ambas direcciones.
mininet-wifi> ap1 ./redirect.sh


```

### Comprobación del funcionamiento

La comprobación de funcionamiento de este programa puede ser llevada a cabo desde un extremo u otro debido a que, si todo funciona correctamente, existirá una comunicación bidireccional. Por lo que nosotros haremos las pruebas desde la estación wireless `sta1`  hacia el host `h1`.

```bash

# Hacemos un ping desde el h1 a la sta1, o al revés
mininet-wifi> sta1 ping h1

# Comprobamos con el recolector de estadísticas que se están produciendo XDP_REDIRECT
mininet-wifi> ap1 sudo ./xdp_stats -d ap1-wlan1

ó

mininet-wifi> ap1 sudo ./xdp_stats -d ap1-eth2

``` 


## Fuentes

* [Helpers BPF](http://man7.org/linux/man-pages/man7/bpf-helpers.7.html) 
* [Rounting Linux - FIB](https://www.net.in.tum.de/fileadmin/TUM/NET/NET-2015-09-1/NET-2015-09-1_07.pdf)
* [Rounting Linux - FIB (source)](https://github.com/torvalds/linux/blob/master/include/net/fib_rules.h)
