# XDP - Case04: Layer 3 forwarding

In this use case we will explore packet forwarding, at this point we already know how to filter by the packet headers, analyze them and establish a logic associated with that filtering with the XDP return codes. An extra action to be done with the packets will be the forwarding, in XDP it will be implemented by return codes and by [``helpers BPF``](http://man7.org/linux/man-pages/man7/bpf-helpers.7.html), because as we already mentioned in [case02](https://github.com/davidcawork/TFG/tree/master/src/use_cases/xdp/case02), XDP ends up being translated into BPF (eBPF), so certain functions, not all, to work with bpf are available when working with XDP. 

Throughout this use case, the different ways to achieve forwarding with XDP have been explored. We have gone from the simplest way to the most robust and complex way. In order to avoid differences between these ways of forwarding, a single scenario has been created where these paths will be explored without any differences induced by forwarding.

In the case of previous use we were already forwarding, since, with the code ``XDP_TX`` we are forwarding to the interface through which that packet was received. But how do we forward to other interfaces? How can we route a packet that arrives at us through interface A and to another interface B? Well, reading the man-page of the [``helpers BPF``](http://man7.org/linux/man-pages/man7/bpf-helpers.7.html) we find the functions ``bpf_redirect()``, ``bpf_redirect_map()`` which, reading their description, will be the way used to address this need.

```C

int bpf_redirect(u32 ifindex, u64 flags);

int bpf_redirect_map(struct bpf_map *map, u32 key, u64 flags);

```

If we look at their definition, none of them works with the ``sk_buff``, data structure used very frequently in the network stack of the Linux Kernel in [case05](https://github.com/davidcawork/TFG/blob/master/src/use_cases/xdp/case05/), it will be explained what limitations induce some of the _BPF_ helpers to make use of it. The first one, ``bpf_redirect()`` makes use of ``ifindex`` as an identifier element of the interface to which it has to forward. As for the function ``bpf_redirect_map()`` makes use of a BPF map and a _key_, remember that BPF maps are of the key - value type, and based on the key we give it will go to the BPF map to find the value associated with that key, which will be an ``ifindex``. This last function will be explored further in this use case.


## Compilation

To compile the XDP program a Makefile has been left prepared in this directory as well as in the [``case03``](https://github.com/davidcawork/TFG/tree/master/src/use_cases/xdp/case03), so to compile it you only need to make a:

```bash
make
```
If you are in doubt about the process of compiling the XDP program, we recommend that you return to [``case02``](https://github.com/davidcawork/TFG/tree/master/src/use_cases/xdp/case02)] where the flow arranged for compiling the programs is referred to.

## Setting up the scenario

To test the XDP programs we will use the Network Namespaces. If you don't know what the Network Namespaces are, or the concept of namespace in general, we recommend that you read the [``case01``](https://github.com/davidcawork/TFG/tree/master/src/use_cases/xdp/case01) where a short introduction to the Network Namespaces is given, what they are and how we can use them to emulate our Network scenarios. 

As we mentioned before, so that the concept of the Network Namespaces does not pose a barrier to entry, a script has been written to raise the stage, and for its subsequent cleaning. It is important to point out that the script must be launched with root permissions. To raise the scenario we must execute the script in the following way:

```bash
sudo ./runenv.sh -i
```

To clean our machine from the previously recreated scenario we can run the same script indicating now the -c (Clean) parameter. To some bad, and if it is believed that the cleaning has not been done in a satisfactory way, we can make a reboot of our machine obtaining this way that all the not persistent entities(veth, netns..) disappear of our computer.

```bash
sudo ./runenv.sh -c
```


## Hardcoded Forwarding 

The scenario raised is the following, it is composed of two Network Namespaces, and two pairs of ``veth's`` which we will use to communicate the two network namespaces with each other, through the default Network namespace. In this case, we will forward from the ``dos`` interface to the ``uno`` interface.


![scenario](../../../../img/use_cases/xdp/case04/scenario_01.png)

### Loading the XDP program 

Before loading the program **we must obtain two data**, the **``ifindex`` of the ``uno``** interface to which we are going to send the packets generated from the interior of the ``dos`` network namespace, and the **MAC of the internal interface** of the ``uno`` network namespace, since it will be necessary that the packets that go to the ``uno`` interface have as destination MAC that of the ``veth0`` so that the packets are not discarded. Once we have this data noted, we will open the xdp program (``*.c``) like any text editor, and go to the declaration of variables and hardcode both the ``ifindex`` and the MAC. For example:

```C 

    /*  Para un ifindex: 6 y una MAC: 9A:DE:AF:EC:18:6E */

    ...
    
    unsigned char dst[ETH_ALEN + 1] = {0x9a,0xde,0xaf,0xec,0x18,0x6e, '\0'} ;
    unsigned ifindex = 6; 

    ...

```

Once we have hardcoded the data to do the forwarding we will have to recompile the XDP program so that the bytecode we anchor to the ``dos`` interface does the forwarding correctly. Therefore, we simply have to do a **``make``** again. 

Now if :smile: .. We're all set to anchor the XDP program again! Remember that because we are working with a ``veth's`` interface we must anchor a dummy program at the end where the packets will be received, for more information on this limitation we recommend that you go back to [case03](https://github.com/davidcawork/TFG/tree/master/src/use_cases/xdp/case03) or see the [Netdev](https://netdevconf.info) talk called **_Veth XDP: XDP for containers_** where they explain in more detail this limitation, how to deal with it and why it is induced.  [Link to the talk](https://netdevconf.info/0x13/session.html?talk-veth-xdp).

```bash

# We enter the Network Namespace "uno" and anchor the dummy program to the veth0 interface
sudo ip netns exec uno ./xdp_loader -d veth0 -F --progsec xdp_pass

# Then, we anchored the program to interface "dos" as we mentioned before
sudo ./xdp_loader -d dos -F --progsec xdp_case04

```

### Testing


The performance check of this XDP program is quite basic, we are going to generate packets from inside the ``dos`` Network Namespace to the ``veth`` inside the ``uno`` Network Namespace. To do this we will open three terminals, in each of them we will carry out a task:

```bash

# In this terminal we will generate the ping to the Network Namespace "uno" interface from the Network Namespace "dos"
[Terminal:1] sudo ip netns exec dos ping {IP_veth0_uno}

# In this terminal we will put a sniffer to listen to the packages that arrive to us within the Network Namespace "dos"
[Terminal:2] sudo ip netns exec uno tcpdump -l

# Finally, optionally, we can run the program that acted as a collector of statistics on XDP return codes
[Terminal:3] sudo ./xdp_stats -d dos
```


## Forwarding semi-Hardcoded(BPF maps)

The scenario raised is the following, it is composed of two Network Namespaces, and two pairs of ``veth's`` which we will use to communicate the two network namespaces with each other, through the default Network namespace. In this case we will forward from the ``dos`` interface to the ``uno`` interface and vice versa, so the communication will be bidirectional.


![scenario2](../../../../img/use_cases/xdp/case04/scenario_02.png)

### Loading XDP program

This way of doing the forwarding does not require hardcoding data in the XDP program itself that will go to the Kernel, but using the BPF maps as a means to save forwarding data such as the ``ifindex`` and the destination MACs from user space so that later the program anchored in the Kernel will be able to read the maps, obtain the forwarding information and do it based on the perceived information from the BPF maps.

Again, and as in this case the communication will be bidirectional we must anchor two _dummy program_ at the two ends where the packets will arrive, if you are not aware of this limitation come back to this [section](https://github.com/davidcawork/TFG/blob/master/src/use_cases/xdp/case04/README.md#carga-del-programa--xdp) where the limitation is mentioned.


It is important to note that previously anchored programs must be removed, so one option would be to clean up the scenario using the given script ( ``sudo ./runenv.sh -c``) and start over.



```bash

# We go into every Network Namespace and anchor the dummy programs
sudo ip netns exec uno ./xdp_loader -d veth0 -F --progsec xdp_pass
sudo ip netns exec dos ./xdp_loader -d veth0 -F --progsec xdp_pass

# We anchor the XDP program on each interface to achieve two-way communication 
sudo ./xdp_loader -d uno -F --progsec xdp_case04_map
sudo ./xdp_loader -d dos -F --progsec xdp_case04_map

# We store the necessary information for forwarding 
local src="uno"
local dest="dos"
local src_mac=$(ip netns exec $src cat /sys/class/net/veth0/address)
local dest_mac=$(ip netns exec $dest cat /sys/class/net/veth0/address)
 
# We populate the BPF maps with the useful information to carry out the forwarding in both directions
./prog_user -d $src -r $dest --src-mac $src_mac --dest-mac $dest_mac
./prog_user -d $dest -r $src --src-mac $dest_mac --dest-mac $src_mac


```

### Testing

This program can be tested from one end or the other because, if everything works correctly, there will be two-way communication. So we will test from the Network namepsace ``uno`` to the ``dos``.

```bash

# We ping from the inside of the network namespace "uno" to the veth0 of the network namespace "dos"
ping  {IP_veth_dos} [ y viceversa..]

# We check with the statistics collector that they are producing XDP_REDIRECT
sudo ./xdp_stats -d uno

ó

sudo ./xdp_stats -d dos

``` 

## Forwarding auto (Kernel FIBs)

The scenario we will work on will be the same as the previous one so we only have to worry about cleaning the scenario of the XDP programs previously anchored to each interface so that they do not interfere with the new XDP programs we are going to anchor. 

In this case, we'll go one step further and the forwarding will be automatic. Automatic? Yes, we won't hardcode any information to forward the packets. But then, how will we know where to send the packets? Very good question, this information will be obtained from the network stack of the Linux kernel which has a FIB (_Forwarding Information Base_) with very useful rules which we can take advantage of. So we will make a query to the FIB with the _helper_ ``bpf_fib_lookup()`` to get the forwarding information from the network stack itself, this is a clear example where the cooperation with the network stack makes our XDP program more robust and independent from the user space. 




![scenario3](../../../../img/use_cases/xdp/case04/scenario_03.png)

### Loading the XDP program

To load our XDP program we must first enable the forwarding in our Kernel, then we will try to anchor the _dummy program_ and finally anchor the programs in both interfaces both ``uno`` and ``dos`` to get the communication bidirectional.

```bash

# Set the forwarding 
sudo sysctl net.ipv4.conf.all.forwarding=1

# Hook the XDP programs
sudo ./xdp_loader -d uno -F --progsec xdp_case04_fib
sudo ./xdp_loader -d dos -F --progsec xdp_case04_fib

# Lets add the dummy programs
sudo ip netns exec uno ./xdp_loader -d veth0 -F --progsec xdp_pass
sudo ip netns exec dos ./xdp_loader -d veth0 -F --progsec xdp_pass

# We enable ifindex 
sudo ./prog_user -d uno
sudo ./prog_user -d dos

```

### Testing

This program can be tested from one end or the other because, if everything works correctly, there will be two-way communication. So we will test from the Network namepsace ``uno`` to the ``dos``.

```bash

# We ping from the inside of the network namespace "uno" to the veth0 of the network namespace "dos"
ping  {IP_veth_dos} [ y viceversa..]

# We check with the statistics collector that they are producing XDP_REDIRECT
sudo ./xdp_stats -d uno

ó

sudo ./xdp_stats -d dos

```

## References

* [Helpers BPF](http://man7.org/linux/man-pages/man7/bpf-helpers.7.html) 
* [Rounting Linux - FIB](https://www.net.in.tum.de/fileadmin/TUM/NET/NET-2015-09-1/NET-2015-09-1_07.pdf)
* [Rounting Linux - FIB (source)](https://github.com/torvalds/linux/blob/master/include/net/fib_rules.h)


---

# XDP - Case04: Layer 3 forwarding

En este caso de uso exploraremos el forwarding de paquetes, en este punto ya sabemos como filtrar por las cabeceras de los paquetes, analizarlos y establecer una lógica asociada a ese filtrado con los códigos de retorno XDP. Una acción extra a realizar con los paquetes será el forwarding, en XDP vendrá implementado por códigos de retorno y por [``helpers BPF``](http://man7.org/linux/man-pages/man7/bpf-helpers.7.html), por que como ya comentábamos en el [case02](https://github.com/davidcawork/TFG/tree/master/src/use_cases/xdp/case02), XDP se termina traduciendo en BPF (eBPF), por lo que ciertas funciones, no todas, para trabajar con bpf están disponibles a la hora de trabajar con XDP. 

A lo largo de este caso de uso, se han explorado las distintas maneras para lograr el forwarding con XDP. Hemos ido desde la manera más simple a la manera más robusta y compleja. Para que no haya diferencias entre estas formas de realizar el forwarding, se ha creado un mismo escenario donde se explorarán estas vias sin que existan diferencias inducidas por este.

En el caso de uso anterior ya estábamos haciendo un forwarding, ya que, con el código ``XDP_TX`` estamos haciendo un forwarding hacia la interfaz por la cual se recibió dicho paquete. Pero, ¿Cómo hacemos un Forwarding hacia otras interfaces? ¿Cómo podemos encaminar un paquete que nos llega por una interfaz A y hacia otra interfaz B? Bien, leyendo la man-page de los [``helpers BPF``](http://man7.org/linux/man-pages/man7/bpf-helpers.7.html) nos encontramos con las funciones ``bpf_redirect()``, ``bpf_redirect_map()`` las cuales, leyendo su descripción, serán la vía utilizada para abordar esta necesidad.

```C

int bpf_redirect(u32 ifindex, u64 flags);

int bpf_redirect_map(struct bpf_map *map, u32 key, u64 flags);

```

Si nos fijamos en su definición ninguna de ellas opera con los ``sk_buff``, estructura de datos utilizada de forma muy frecuente en el stack de red del Kernel de Linux en el [case05](https://github.com/davidcawork/TFG/blob/master/src/use_cases/xdp/case05/) se explicará que limitaciones nos induce que alguno de los _helpers BPF_ hagan uso de ella. La primera de ellas, ``bpf_redirect()`` hace uso del ``ifindex`` como elemento identificador de la interfaz a la cual tiene que hacer el forwarding. En cuanto a la función ``bpf_redirect_map()`` hace uso de un mapa BPF y una _key_, recordemos que los mapas BPF son del tipo clave - valor, y en base a la key que le demos irá al mapa BPF buscara el valor asociado a esa clave, el cual, será un ``ifindex``. Esta última función la exploraremos más a fondo en este caso de uso.


## Compilación

Para compilar el programa XDP se ha dejado un Makefile preparado en este directorio al igual que en el [``case03``](https://github.com/davidcawork/TFG/tree/master/src/use_cases/xdp/case03), por lo que para compilarlo unicamente hay que hacer un:

```bash
make
```
Si tiene dudas sobre el proceso de compilación del programa XDP le recomendamos que vuelva al [``case02``](https://github.com/davidcawork/TFG/tree/master/src/use_cases/xdp/case02) donde se hace referencia al flow dispuesto para la compilación de los programas.

## Puesta en marcha del escenario

Para testear los programas XDP haremos uso de las Network Namespaces. Si usted no sabe lo que son las Network Namespaces, o el concepto de namespace en general, le recomendamos que se lea el [``case01``](https://github.com/davidcawork/TFG/tree/master/src/use_cases/xdp/case01) donde se hace una pequeña introducción a las Network Namespaces, qué son y cómo podemos utilizarlas para emular nuestros escenarios de Red. 

Como ya comentábamos, para que no suponga una barrera de entrada el concepto de las Network Namespaces, se ha dejado escrito un script para levantar el escenario, y para su posterior limpieza. Es importante señalar que el script debe ser lanzado con permisos de root. Para levantar el escenario debemos ejecutar dicho script de la siguiente manera:

```bash
sudo ./runenv.sh -i
```

Para limpiar nuestra máquina del escenario recreado anteriormente podemos correr el mismo script indicándole ahora el parámetro -c (Clean). A unas malas, y si se cree que la limpieza no se ha realizado de manera satisfactoria, podemos hacer un reboot de nuestra máquina consiguiendo así que todos los entes no persistentes(veth, netns..) desaparezcan de nuestro equipo.

```bash
sudo ./runenv.sh -c
```


## Forwarding Hardcodeado

El escenario levantado es el siguiente, está compuesto de dos Network Namespace, y de dos pares de ``veth's`` las cuales utilizaremos para comunicar las dos network namespaces entre sí, a través del la Network namespace por defecto. En este caso el forwarding lo haremos desde la interfaz ``dos`` hacia la interfaz ``uno``.


![scenario](../../../../img/use_cases/xdp/case04/scenario_01.png)

### Carga del programa  XDP

Antes de realizar la carga del programa **debemos obtener dos datos**, la **``ifindex`` de la interfaz ``uno``** a la cual le vamos a mandar los paquetes generados desde el interior de la network namespace ``dos``, y la **MAC de la interfaz interna** de la Network namespace ``uno``, ya que será necesario que los paquetes que se dirijan a la interfaz ``uno`` lleven como MAC destino la de la ``veth0`` para que así los paquetes no sean descartados. Una vez tengamos estos datos anotados abriremos el programa xdp (``*.c``) cuan cualquier editor de texto, e iremos a la declaración de variables y hardcoderemos tanto el ``ifindex`` como la MAC. Por ejemplo:

```C 

    /*  Para un ifindex: 6 y una MAC: 9A:DE:AF:EC:18:6E */

    ...
    
    unsigned char dst[ETH_ALEN + 1] = {0x9a,0xde,0xaf,0xec,0x18,0x6e, '\0'} ;
    unsigned ifindex = 6; 

    ...

```

Una vez que tengamos hardcodeado los datos para realizar el forwarding deberemos recompilar el programa XDP para que el bytecode que anclemos a la interfaz ``dos`` haga correctamente el forwarding. Por ello, simplemente tenemos que hacer un **``make``** nuevamente. 

Ahora si :smile: .. Ya tenemos todo preparado para anclar de nuevo el programa XDP! Recordemos que por el estar trabajando con interfaz ``veth's`` debemos anclar un dummy program en el extremo donde se vayan a recibir los paquetes, para más información de esta limitación le recomendamos que vuelva al [case03](https://github.com/davidcawork/TFG/tree/master/src/use_cases/xdp/case03) ó ver la charla de la [Netdev](https://netdevconf.info) llamada **_Veth XDP: XDP for containers_** donde explican con un mayor detalle esta limitación, como abordarla y por que está inducida.  [Enlace a la charla](https://netdevconf.info/0x13/session.html?talk-veth-xdp).

```bash

# Entramos a la Network Namespace "uno" y anclamos el dummy program a la interfaz veth0
sudo ip netns exec uno ./xdp_loader -d veth0 -F --progsec xdp_pass

# Acto seguido, anclamos el programa a la interfaz "dos" como ya comentábamos antes
sudo ./xdp_loader -d dos -F --progsec xdp_case04

```

### Comprobación del funcionamiento


La comprobación de funcionamiento de este programa XDP es bastante básica, vamos a generar paquetes desde el interior de la Network Namespace ``dos`` hacia la ``veth`` interna de la Network Namespace ``uno``. Para ello abriremos tres terminales, en cada una de ellas llevaremos a cabo una tarea:


```bash

# En esta terminal generaremos el ping hacia la interfaz de la Network Namespace "uno" desde la Network Namespace "dos"
[Terminal:1] sudo ip netns exec dos ping {IP_veth0_uno}

# En esta terminal pondremos a un sniffer a escuchar los paquetes que nos lleguen dentro de la Network Namespace "dos"
[Terminal:2] sudo ip netns exec uno tcpdump -l

# Por último, opcionalmente, podemos ejecutar el programa que actuaba como recolector de estadísticas sobre los códigos de retorno XDP
[Terminal:3] sudo ./xdp_stats -d dos
```


## Forwarding semi-Hardcodeado (BPF maps)

El escenario levantado es el siguiente, está compuesto de dos Network Namespace, y de dos pares de ``veth's`` las cuales utilizaremos para comunicar las dos network namespaces entre sí, a través del la Network namespace por defecto. En este caso el forwarding lo haremos desde la interfaz ``dos`` hacia la interfaz ``uno`` y viceversa, por lo que la comunicación será bidireccional.


![scenario2](../../../../img/use_cases/xdp/case04/scenario_02.png)

### Carga del programa  XDP

Esta manera de hacer el forwarding no requiere de hardcodear datos en el propio programa XDP que irá al Kernel, si no, que se usarán los mapas BPF como medio para guardar datos de forwarding como son las ``ifindex`` y las MAC destino desde espacio de usuario para que posteriormente el programa anclado en el Kernel sea capaz de leer los mapas, obtener la información de forwarding y realizarlo en base a la información percibida de los mapas BPF.

De nuevo, y como en este caso la comunicación será bidireccional debemos anclar dos _dummy program_ en los dos extremos donde van a llegar los paquetes, si no estás al tanto de esta limitación vuelva a esta [sección](https://github.com/davidcawork/TFG/blob/master/src/use_cases/xdp/case04/README.md#carga-del-programa--xdp) donde se menciona la limitación.

Es importante señalar que los programas anclados previamente deben ser removidos, por lo que una opción sería hacer un clean del escenario haciendo uso del script dado ( ``sudo ./runenv.sh -c``) y empezar de nuevo.


```bash

# Entramos en cada Network Namespace y anclamos los "dummy programs"
sudo ip netns exec uno ./xdp_loader -d veth0 -F --progsec xdp_pass
sudo ip netns exec dos ./xdp_loader -d veth0 -F --progsec xdp_pass

# Anclamos el programa XDP en cada interfaz para conseguir un comunicación bidireccional 
sudo ./xdp_loader -d uno -F --progsec xdp_case04_map
sudo ./xdp_loader -d dos -F --progsec xdp_case04_map

# Almacenamos la información necesaria para realizar el forwarding 
local src="uno"
local dest="dos"
local src_mac=$(ip netns exec $src cat /sys/class/net/veth0/address)
local dest_mac=$(ip netns exec $dest cat /sys/class/net/veth0/address)
 
# Populamos los mapas BPF con la información útil para llevar a cabo el forwarding en ambas direcciones
./prog_user -d $src -r $dest --src-mac $src_mac --dest-mac $dest_mac
./prog_user -d $dest -r $src --src-mac $dest_mac --dest-mac $src_mac


```

### Comprobación del funcionamiento

La comprobación de funcionamiento de este programa puede ser llevada a cabo desde un extremo u otro debido a que, si todo funciona correctamente, existirá una comunicación bidireccional. Por lo que nosotros haremos las pruebas desde la Network namepsace ``uno``  hacia la ``dos``.

```bash

# Hacemos un ping desde el interior de la Network namespace "uno" hacia la veth0 de la Network namespace "dos"
ping  {IP_veth_dos} [ y viceversa..]

# Comprobamos con el recolector de estadísticas que se están produciendo XDP_REDIRECT
sudo ./xdp_stats -d uno

ó

sudo ./xdp_stats -d dos

``` 

## Forwarding auto (Kernel FIBs)

El escenario sobre el cual trabajaremos será el mismo que el anterior por lo que unicamente debemos preocuparnos de limpiar el escenario de los programas XDP anteriormente anclados a cada interfaz para que no interfieran con los nuevos programas XDP que vamos a anclar. 

En este caso, vamos a ir un paso más allá y el forwarding será automático. ¿Automático? Si, no hardcodearemos ningún tipo de información para hacer el forwarding a los paquetes. Pero, entonces, ¿Cómo sabremos a dónde hay que mandar los paquetes? Muy buena pregunta, esta información la conseguiremos del stack de red del kernel de Linux el cual tiene una FIB (_Forwarding Information Base_) con reglas muy útiles las cuales podemos sacar partido. Por lo que haremos una consulta a la FIB con el _helper_ ``bpf_fib_lookup()`` para obtener información de forwarding desde el propio stack de red, este es un claro ejemplo donde la cooperación con el stack de red hace que nuestro programa XDP sea más robusto e independiente del espacio de usuario. 



![scenario3](../../../../img/use_cases/xdp/case04/scenario_03.png)

### Carga del programa  XDP

Para la carga de nuestro programa XDP deberemos primero habilitar el forwarding en nuestro Kernel, acto seguido nos procuraremos de anclar los _dummy program_ y por último anclar los programas en ambas interfaces tanto ``uno`` como ``dos`` para conseguir que la comunicación se bidireccional.

```bash

# Habilitamos el forwarding 
sudo sysctl net.ipv4.conf.all.forwarding=1

# Anclamos los programas XDP a cada interfaz 
sudo ./xdp_loader -d uno -F --progsec xdp_case04_fib
sudo ./xdp_loader -d dos -F --progsec xdp_case04_fib

# Ahora añadimos a cada interfaz destino su "dummy program"
sudo ip netns exec uno ./xdp_loader -d veth0 -F --progsec xdp_pass
sudo ip netns exec dos ./xdp_loader -d veth0 -F --progsec xdp_pass

# Habilitamos los ifindex 
sudo ./prog_user -d uno
sudo ./prog_user -d dos

```

### Comprobación del funcionamiento

La comprobación de funcionamiento de este programa puede ser llevada a cabo desde un extremo u otro debido a que, si todo funciona correctamente, existirá una comunicación bidireccional. Por lo que nosotros haremos las pruebas desde la Network namepsace ``uno``  hacia la ``dos``.

```bash

# Hacemos un ping desde el interior de la Network namespace "uno" hacia la veth0 de la Network namespace "dos"
ping  {IP_veth_dos} [ y viceversa..]

# Comprobamos con el recolector de estadísticas que se están produciendo XDP_REDIRECT
sudo ./xdp_stats -d uno

ó

sudo ./xdp_stats -d dos

```

## Fuentes

* [Helpers BPF](http://man7.org/linux/man-pages/man7/bpf-helpers.7.html) 
* [Rounting Linux - FIB](https://www.net.in.tum.de/fileadmin/TUM/NET/NET-2015-09-1/NET-2015-09-1_07.pdf)
* [Rounting Linux - FIB (source)](https://github.com/torvalds/linux/blob/master/include/net/fib_rules.h)


