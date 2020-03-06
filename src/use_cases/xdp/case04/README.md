# XDP - Case04: Layer 3 forwarding

En este caso de uso exploraremos el forwarding de paquetes, en este punto ya sabemos como filtrar por las cabeceras de los paquetes, analizarlos y establecer una lógica asociada a ese filtrado con los códigos de retorno XDP. Una acción extra a realizar con los paquetes será el forwarding, en XDP vendrá implementado por códigos de retorno y por [``helpers BPF``](http://man7.org/linux/man-pages/man7/bpf-helpers.7.html), por que como ya comentábamos en el [case02](https://github.com/davidcawork/TFG/tree/master/src/use_cases/xdp/case02), XDP se termina traduciendo en BPF (eBPF), por lo que ciertas funciones, no todas, para trabajar con bpf están disponibles a la hora de trabajar con XDP. 

A lo largo de este caso de uso, se han explorado las distintas maneras para lograr el forwarding con XDP. Hemos ido desde la manera más simple a la manera más robusta y compleja. Para que no haya diferencias entre estas formas de realizar el forwarding, se ha creado un mismo escenario donde se explorarán estas vias sin que existan diferencias inducidas por este.

En el caso de uso anterior ya estábamos haciendo un forwarding, ya que, con el código ``XDP_TX`` estamos haciendo un forwarding hacia la interfaz por la cual se recibió dicho paquete. Pero, ¿Cómo hacemos un Forwarding hacia otras interfaces? ¿Cómo podemos encaminar un paquete que nos llega por una interfaz A y hacia otra interfaz B? Bien, leyendo la man-page de los [``helpers BPF``](http://man7.org/linux/man-pages/man7/bpf-helpers.7.html) nos encontramos con las funciones ``bpf_redirect()``, ``bpf_redirect_map()`` las cuales, leyendo su descripción, serán la vía utilizada para abordar esta necesidad.

```C

int bpf_redirect(u32 ifindex, u64 flags);

int bpf_redirect_map(struct bpf_map *map, u32 key, u64 flags);

```

Si nos fijamos en su definición ninguna de ellas opera con los ``sk_buff``, estructura de datos utilizada de forma muy frecuente en el stack de red del Kernel de Linux en el [case05](https://github.com/davidcawork/TFG/blob/master/src/use_cases/xdp/case05/) se explicará que limitaciones nos induce que alguno de los _helpers BPF_ hagan uso de ella. La primera de ellas, ``bpf_redirect()`` hace uso del ``ifindex`` como elemento identificador de la interfaz a la cual tiene que hacer el forwarding. En cuanto a la función ``bpf_redirect_map()`` hace uso de un mapa BPF y una _key_, recordemos que los mapas BPF son del tipo clave - valor, y en base a la key que le demos irá al mapa BPF buscara el valor asociado a esa clave, el cual, será un ``ifindex``. Esta última función la exploraremos más a fondo en este caso de uso.






## Puesta en marcha del escenario

Para testear los programas XDP haremos uso de las Network Namespaces. Por ello, se ha dejado escrito un script para levantar el escenario haciendo uso de las network namespaces, y para su posterior limpieza. Para levantar el escenario hacemos un:

```bash
sudo ./runenv.sh -i
```

Para limpiar nuestra máquina del escenario hacemos un:

```bash
sudo ./runenv.sh -c
``` 






## Forwarding Hardcodeado

![scenario](../../../../img/use_cases/xdp/case04/scenario_01.png)

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
## Forwarding semi-Hardcodeado (BPF maps)

![scenario2](../../../../img/use_cases/xdp/case04/scenario_02.png)

### Carga del programa  XDP

> Añadir literatura

```bash
sudo ip netns exec uno ./xdp_loader -d veth0 -F --progsec xdp_pass
sudo ip netns exec dos ./xdp_loader -d veth0 -F --progsec xdp_pass
sudo ./xdp_loader -d uno -F --progsec xdp_case04_map
sudo ./xdp_loader -d dos -F --progsec xdp_case04_map


 local src="uno"
 local dest="dos"
 local src_mac=$(ip netns exec $src cat /sys/class/net/veth0/address)
 local dest_mac=$(ip netns exec $dest cat /sys/class/net/veth0/address)
 
 # set bidirectional forwarding
 ./xdp_prog_user -d $src -r $dest --src-mac $src_mac --dest-mac $dest_mac
 ./xdp_prog_user -d $dest -r $src --src-mac $dest_mac --dest-mac $src_mac

```

### Comprobación del funcionamiento

> Añadir literatura

```bash
ping from veth0(uno) to veth0(dos) [ y viceversa..]

sudo ./xdp_stats -d uno

ó

sudo ./xdp_stats -d dos

``` 

## Forwarding auto (Kernel FIBs)

![scenario3](../../../../img/use_cases/xdp/case04/scenario_03.png)

### Carga del programa  XDP

> Añadir literatura

```bash
sudo sysctl net.ipv4.conf.all.forwarding=1
sudo ./xdp_loader -d uno -F --progsec xdp_case04_fib
sudo ./xdp_loader -d dos -F --progsec xdp_case04_fib

sudo ip netns exec uno ./xdp_loader -d veth0 -F --progsec xdp_pass
sudo ip netns exec dos ./xdp_loader -d veth0 -F --progsec xdp_pass

sudo ./prog_user -d uno
sudo ./prog_user -d dos

```

### Comprobación del funcionamiento

> Añadir literatura

```bash 
sudo ./xdp_stats -d uno

ó
sudo ./xdp_stats -d dos

ping from veth0(uno) to veth0(dos) [ y viceversa..]
```

## Fuentes

* [Helpers BPF](http://man7.org/linux/man-pages/man7/bpf-helpers.7.html) 
* [Rounting Linux - FIB](https://www.net.in.tum.de/fileadmin/TUM/NET/NET-2015-09-1/NET-2015-09-1_07.pdf)
* [Rounting Linux - FIB (source)](https://github.com/torvalds/linux/blob/master/include/net/fib_rules.h)
