# Future work: Análisis  de casos de uso sobre el estándar ieee802154

A continuación, se quiere hacer un breve análisis sobre la viabilidad de exportar los casos de uso realizados anteriormente en medios cableados e inalámbrico bajo el estándar wireless de baja capacidad. De esta forma se quiere ver las fortalezas y debilidades, de tanto XDP como el lenguaje P4 para programar el datapath de dispositivos de baja capacidad, en un escenario orientado a un entorno IoT (Internet of Things), con sensores los cuales están bastante limitados en batería, alcance, memoria y procesamiento.


## Herramientas entorno `ieee802154`

¿Por dónde empezamos?¿Qué herramientas de espacio de usuario tenemos para trabajar con el subsistema `ieee802154`? Es una buena pregunta, yo llegue a esta respuesta después de ver que dependencias instala Mininet-Wifi para interactuar con su módulo de Iot. Todas las herramientas que han sido útiles en este análisis se muestran en la siguiente tabla resumen: 

| Herramienta         | Explicación  | Enlace |  
|---------------|-----|----|
| `iwpan`              | Herramienta principal para la configuración del subsistema `ieee802154`, sus interfaces y sus radios. Esta herramienta es muy similar a al herramienta `iw` pensada para controlar el subsistema Wireless del Kernel de Linux.  | [Link al source](https://github.com/linux-wpan/wpan-tools/tree/master/src) |
| ``wpan-hwsim``             | Herramienta para gestionar el modulo `mac802154_hwsim`, permitiendo añadir o eliminar radios, así como añadir enlaces entre distintos radios a través de `netlink`.  | [Link al source](https://github.com/linux-wpan/wpan-tools/tree/master/wpan-hwsim) |
| ``wpan-ping``        | Herramienta para hacer ping directamente con el stack `ieee802154`   | [Link al source](https://github.com/linux-wpan/wpan-tools/tree/master/wpan-ping) |




## Arquitectura

En adelante, se expone un diagrama de la arquitectura del stack `ieee802154`, obtenido del repositorio oficial del desarrollo de las herramientas y de los módulos asociados al estándar `ieee802154` del Kernel de linux. Este esquema nos ha sido de gran utilidad para comparar sus distintos bloques con el módulo `mac80211_hwsim` el cual utilizamos para emular redes inalámbricas bajo el estándar `ieee802.11`.



```text 

              .-------------------------------------------------------------------------------------------------------.
              |                                               Userspace                                               |
              '-----------------^----------------------------------^----------------------------------^---------------'
                                |                                  | socket                           |
                                |                                  v                                  |
                                |                  .------------------------------.                   |
                                | socket           |             IPv6             |                   |
                                |                  '------------------------------'                   | netlink
                                |                                         ^                           |
             .------------------|-----------------------------------------|---------------------------|-----------------.
             |                  |                             ieee802154  |                           |                 |
             |------------------|-----------------------------------------|---------------------------|-----------------|
             |                  v                                         v                           |                 |
             | .---------------------------------. .-----------------------------.                    |                 |
             | |        802.15.4 Sockets         | |      802.15.4 6LoWPAN       |                    |                 |
             | |---------------------------------| |-----------------------------|    .---------------v-------------.   |
             | |.--------------. .--------------.| |                             |    |          nl802154           |   |
             | ||    DGRAM     | |     RAW      || |  .-----------------------.  |    |-----------------------------|   |
             | || data payload | |  full frame  || |  |    Generic 6LoWPAN    |  |    |                             |   |
             | |'------^-------' '--------------'| |  | .-------------------. |  |    |  .----------. .-----------. |   |
             | |       |                | ^      | |  | |        NHC        | |  |    |  |   mlme   | | cmd, etc. | |   |
             | |       |                | |      | |  | '-------------------' |  |    |  |----------| |-----------| |   |
             | |       v                | |      | |  '-------------^---------'  |    |  | assoc.   | | panid     | |   |
             | | .------------.         | |      | |                |            |    |  | deassoc. | | channel   | |   |
             | | | dataframes |       tx| | rx   | |       .--------v--------.   |    |  | ...      | | ...       | |   |
             | | '------------'         | |      | |       |   dataframes    |   |    |  '----------' '-----------' |   |
             | |     |    ^             | |      | |       '-------^-|-------'   |    |       |             ^       |   |
             | '-----|----|-------------|-|------' '---------------|-|-----------'    |       |             |       |   |
             |       |    |             | |-----------.            | |                |       |             |       |   |
             |    tx |    |rx           '-------|     |            | |                '-------|-------------|-------'   |
             |       |    |---------------------|-----|------.   rx| |tx                      |             |           |
             |       v                          |     |      |     | |                        |             |           |
             | .------------------------------. |     |      |     | |                        |             |           |
             | |        frame creation        | |     |      |     | |                        |             |           |
             | |------------------------------| |     |      |     | |                        |             |           |
             | | generic functions            <-|-----|--------------'                        |             |           |
             | | - wpan_dev callbacks struct? | |     |      |     |                          |             |           |
             | |   instead dev_hard_header    | |     |      |     |   .-------------------.  |             |           |
         ******|   different HardMAC/SoftMAC  | |     |      |     |   |  mlme operations  |  |             |           |
         *   | | - data                       | |     |      |     |   |                   |<-'             |           |
         *   | | --- for mlme ---             | |     |      |     |   '-------------------'                |           |
         *   | | - beacon                     | |     |      |     |                |                       |           |
         *   | | - cmd                        | |     |      |     |                |                       |           |
         *   | | - ack? -> (slotted mode)     | |     |      |     |                |                       |           |
         *   | '--------------|---------------' |.-------------------------.        |                       |           |
         *   |                v                 ||  802.15.4 packet_layer  |        |             ----------'           |
         *   |       .----------------.         |'-------------------------'        |             |                     |
         *   |       | dev_queue_xmit |<--------'            ^                      |             |                     |
         *   |       '----------------'                      |                      |             |                     |
         *   '----------------|------------------------------|----------------------|-------------|---------------------'
         *              .-----|------------------------------|----------------------|-------------|------------.
         *              |     |                              | mac802154            |             |            |
         *              |-----|------------------------------|----------------------v-------------v------------|
         *              |     |                              |               .-------------..-----------.      |
         *******************************************************************>| do mlme ops || cfg802154 |      |
can use frame creation  |     |   .--------------------------|-------------. '-------------'|-----------|      |
                        |     |   | Frame parsing (call netif_receive_skb) |        |       | panid     |--------|
                        |     |   |----------------------------------------|        |       | shortaddr |      | |
                        |     |   | again check if 802.15.4 compliant      |        |       | etc.      |      | |
                        |     |   | different handling coordinator/node    |        |       '-----------'      | |
                        |     |   | set packet type (e.g. PACKET_HOST)     |        |                          | |
                        |     |   '---------------------^------------------'        |                          | |
                        |     |                         |                           | tx workqueue             | |
                        |     |ndo_start_xmit           |   |-----------------------'                          | |  .--------------.
                        |     |      .------------------|---|--------------------------------------.           | |  | e.g. tcpdump |
                        |     |      |                  |   |interface types                       |           | |  '--------------'
                        |     |      |------------------|---|--------------------------------------|           | |          ^
                        |     |      |                  |   |                                      |           | |          |
                        |     |      | .----------------|---v-----------.  .---------------------. |           | |          |
                        |     |      | |             frames             |  |       frames        | | mac sett. | |    .-----------.
                        |     '-------->    for rx, filtered by phy     |  | non-filtered by phy | |<------------|    | af_packet |
                        |            | |--------------------------------|  |---------------------| |           | |    '-----------'
                        |        .---| |                                |  |                     |----.        | |          ^
                        |        |   | | .-------------.  .-----------. |  | .-----------.       | |  |        | |          |
                        |        |   | | | coordinator |  |   node    | |  | |  monitor  |-----------------------|----------'
                        |        |   | | '------^------'  '-----^-----' |  | '-----------'       | |  |        | |
                        |        |   | '--------|---------------|-------'  '-------^-------------' |  |        | |
                        |        |   '----------|---------------|------------------|---------------'  |        | |
                        |        |              | rx/tx         | rx/tx            |rx/tx not possible(no AACK)| |
                        |        |              |               |         |--------|                  |        | |
                        '--------|--------------|---------------|---------|--------|------------------|--------' |
                                 |              v               v         |        |                  |          |
                                 |         ===================================     |                  |          |
                                 |               ^          ^          ^           |                  |          |
                                 |        .------|----------|----------|-----------|------.           |          |
    each interface type has      |        |      |          |  Frames  |           |      |           |     if AACK, ack frames are handled   
    different phy address filters|        |------|----------|----------|-----------|------|           |     by phy layer, not driver.         
    - sets mac settings on ifup  |        | .----v----..----v----..----v----. .---------. |  AACK ----|--->                                   
                                 |        | |  data   ||   cmd   || beacon  | |   ack   |------.      |     AACK disabled if promiscuous mode.
                                 |        | '----^----''----^----''----^----' '----^----' |    |      |     Then driver receives ack frames.  
                                 |        '------|----------|----------|-----------.------'    |      |          |
                                 |               |          |          |           .           |      |          |
                                 |               |          |          |           .           |      | sets promiscuous mode
                                 |        .------v----------v----------v-----------v------.    |      |          |
                                 |        |            802.15.4 SoftMAC Driver            |    |      |          |
                                 |        |-----------------------------------------------|    |      |          |
                                 |        | - supports always AACK handling               |    |      |          |
                                 -------->|   - ACK handling is done by phy (AACK)        |<-----------          |
                                          |   - on AACK, ACK frames doesn't reach driver  |<----------------------
                                          | - filtering (CRC, address, what phy can do..) |    |   phy settings
                                          '-----------------------------------------------'    |
                                                                  ^                            |
                                                                  |                            |
                                                                  v                            |
                                                      .----------------------.                 |
                                                      | 802.15.4 SoftMAC PHY |<----------------'
                                                      '----------------------'


```

Tras analizar la arquitectura nos hemos dado cuenta que este módulo, a diferencia del módulo `mac80211_hwsim` no conecta a la capa física (phy) interfaces del tipo Ethernet. Recordemos que cuando se trabaja con Wifi nos preguntábamos por que se hacía un parseo de paquetes con cabeceras 802.11 hacia cabeceras 802.3 y viceversa en el Kernel. 


Al generalizar hacia interfaces ethernet, las aplicaciones que trabajan a nivel de interfaz son muy extrapolables, ya que pueden ser portadas a distintos tipos de dispositivos con distintas características. Es verdad que se pierde en performance, ya que el paquete se encola hasta tres veces en el Kernel y requiere procesamiento adicional, pero por otro lado se gana muchísima versatilidad. 


## Viabilidad de los casos de uso 

Teniendo en cuenta que no se emplean interfaces de Ethernet para comunicar la capa física con las capas superiores, los casos de uso no serían extrapolables de forma inmediata, ya que en las etapas de parseo de todos los casos de uso, se parseaba a una cabecera de Ethernet, tanto en XDP haciendo accesos a memoria, como en p4 con las distintas etapas de parseamiento.


Por tanto, en vez de parsear los paquetes hacia estructuras de Ethernet habría que hacerlo hacia estructuras que definieran la estructura de la cabecera `ieee802154`. Además, buscando en el [Kernel](https://elixir.bootlin.com/linux/latest/source/include/net/ieee802154_netdev.h) se ha encontrado que dicha estructura ya está definida por lo que solo habría que hacer uso de ella en los casos de uso de XDP, y en los casos de uso de P4 habría que declarar la estructura análoga y sustituir el parser de Ethernet por el parser de cabeceras 802.15.4. 

```C
struct ieee802154_hdr {
	struct ieee802154_hdr_fc fc;
	u8 seq;
	struct ieee802154_addr source;
	struct ieee802154_addr dest;
	struct ieee802154_sechdr sec;
};
```

No obstante, se ha probado a añadir un programa XDP a una interfaz generada por el módulo `mac802154_hwsim`, ya que se entiende que el BVM2 no debe suponerle un problema para hacer uso de las interfaces suministradas, ya que este hace uso de la librería [`pcap`](https://github.com/p4lang/behavioral-model/blob/master/src/BMI/bmi_interface.c) para gestionar el envío y recepción de los paquetes. Esta librería se ha visto que hace uso de la interfaz de `sockets` en última instancia, se puede ver [aquí](https://github.com/the-tcpdump-group/libpcap/blob/master/pcap.c) en el source, por lo que no supondría ninguna incompatibilidad con la arquitectura de subsistema `ieee802154` que admite la operabilidad con distintas familias de sockets.


### Prueba de carga con XDP

Como ya se ha comentado, la viabilidad a futuro de replicar los casos de uso sobre el módulo `mac802154_hwsim` pasan por si son capaces de gestionar la carga de programas XDP en sus interfaces, ya que, como se ha indicado con el BMV2 no habría ningún problema ya que iría sobre la interfaz de sockets del Kernel, por lo que la arquitectura del propio módulo lo contempla. 


Se ha buscado información al respecto sobre si el modulo era compatible con la carga de programas BPF, que al final es en lo que se traduce un programa XDP, pero no se ha encontrado información precisa al respecto, por lo que se ha decidido hacer una prueba simple de carga de programas XDP ya hechos. Como ya dijimos los programas XDP no son extrapolables directamente al subsistema 802.15.4, por esto se hará uso del [`case01`](https://github.com/davidcawork/TFG/tree/master/src/use_cases/xdp/case01) donde únicamente se implementaba una funcionalidad del datapath haciendo uso de los códigos de retorno XDP.



De esta forma no será necesario parsear las cabeceras `ieee802154`, y podremos ver de una forma rápida si dichas interfaces asociadas a los radios con la capa física 802.15.4 SoftMAC soportan la carga de un programa XDP genérico. Esta prueba en primera instancia se hizo directamente cargando el módulo y creando las interfaces, pero ya que Mininet-Wifi da soporte para gestionar dicho módulo se pensó que daría cierta continuidad el desarrollo de los distintos casos de uso en dicha herramienta de emulación.



A partir de este punto solo puede continuar si usted poseé una versión del Kernel `v4.18.x` o superior, ya es a partir de esta donde se incluye el módulo `mac802154_hwsim`. Lo primero que haremos es volver a nuestra instalación de Mininet-Wifi e instalar las dependencias necesarias para la gestión del módulo `mac802154_hwsim` (Spoiler: Serán las herramientas mencionadas en la sección anterior :smile: )

```bash

# Entramos en el directorio de mininet-wifi
cd mininet-wifi


# Añadimos las dependencias para la gestión del módulo mac802154_hwsim
sudo util/install.sh -6

```
Ahora con las dependencias ya añadidas, vamos a hacer uso del ejemplo disponible en Mininet-wifi para probar la carga del programa XDP desarrollado en el [`case01`](https://github.com/davidcawork/TFG/tree/master/src/use_cases/xdp/case01). Dicho ejemplo puede ser encontrado bajo el directorio `examples` con el nombre de `6LoWPan.py`. Comentar que en este ejemplo se añade una interfaz auxiliar que añade la capa de gestión del estándar `6LoWPan`, a nosotros nos vale, ya que la carga del programa la haremos sobre la interfaz nativa de subsistema `ieee802154`.
```bash

# Entramos al directorio de los ejemplos
cd examples

# Ejecutamos el ejemplo
sudo python 6LoWPan.py
```

Una vez cargado el ejemplo, tendremos la CLI de Mininet-Wifi abierta, y lo siguiente que haremos será compilar un caso de uso XDP. Como ya comentamos anteriormente, será el [`case01`](https://github.com/davidcawork/TFG/tree/master/src/use_cases/xdp/case01).

```bash

# Nos movemos de directorio y compilamos el case01
mininet-wifi> sh cd ~/TFG/src/use_cases/xdp/case01 && sudo make
```

Ya tendríamos compilado el caso de uso XDP y listo para ser cargado sobre la interfaz. Pero, ¿Sobre qué interfaz debemos cargar el programa XDP? Bien, para contestar esta pregunta debemos inspeccionar antes las interfaces de uno de los sensores. Como los sensores corren en su propia Network namespace, tendremos que abrir una xterm o indicar el nombre de nodo previamente en la CLI de Mininet-Wifi para que dicho comando se ejecute dentro de la Network Namespace indicada.

```bash
# Como se puede apreciar la interfaz que añade la capa 6LoWPan es la interfaz sensor1-pan0
# Nos centraremos en la interfaz que comunica de forma directa con el subsistema 802.15.4
mininet-wifi> sensor1 ip a s

1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
2: sensor1-pan0@sensor1-wpan0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1280 qdisc noqueue state UNKNOWN group default qlen 1000
    link/6lowpan 9e:7b:c7:68:bb:9c:31:56 brd ff:ff:ff:ff:ff:ff:ff:ff
    inet6 2001::1/64 scope global
       valid_lft forever preferred_lft forever
248: sensor1-wpan0: <BROADCAST,NOARP,UP,LOWER_UP> mtu 123 qdisc fq_codel state UNKNOWN group default qlen 300
    link/ieee802.15.4 9e:7b:c7:68:bb:9c:31:56 brd ff:ff:ff:ff:ff:ff:ff:ff

# De forma adicional, podremos utilizar la herramienta iwpan para ver que interfaces (dev)
# están disponibles y sobre que radio, están conectadas.
mininet-wifi> sensor1 iwpan dev
phy#24
        Interface sensor1-wpan0
                ifindex 248
                wpan_dev 0x1800000002
                extended_addr 0x9e7bc768bb9c3156
                short_addr 0xffff
                pan_id 0xbeef
                type node
                max_frame_retries 3
                min_be 3
                max_be 5
                max_csma_backoffs 4
                lbt 0
                ackreq_default 0


```

Por tanto, sabiendo sobre que interfaz operar, en nuestro caso trabajaremos sobre el `sensor1` en la interfaz `sensor1-wpan0`, solo queda cargar el programa y ver si realmente soporta la funcionalidad del mismo. Comentar que unicamente que si no se monta el sistema de archivos bpf bajo el path `/sys/fs/bpf/` no será posible la recolección de estadísticas mediante mapas BPF.

```bash
# Montamos el fs BPF
mininet-wifi> sensor1 mount -t bpf bpf /sys/fs/bpf


# Cargamos el programa XDP en la interfaz 
mininet-wifi> sensor1 cd /home/n0obie/TFG/src/use_cases/xdp/case01 && sudo ./xdp_loader -S -d sensor1-wpan0 -F --progsec xdp_case01
Success: Loaded BPF-object(prog_kern.o) and used section(xdp_case01)
 - XDP prog attached on device:sensor1-wpan0(ifindex:248)
 - Pinning maps in /sys/fs/bpf/sensor1-wpan0/
mininet-wifi>
```

Se puede ver como el programa ha sido correctamente cargado en la interfaz, además, los mapas se anclaron de manera satisfactoria en sistema de archivos por lo que nos habilitar a recolectar estadísticas relativas a los códigos de retorno XDP. Se puede comprobar que la funcionalidad del programa XDP está operando según lo esperado haciendo ping entre dos sensores, ya que al implementar un código de retorno `XDP_DROP` no habrá conectividad entre ellos.

```bash

# Ojo! Con el programa XDP cargado en la interfaz
mininet-wifi> sensor1 ping sensor2
PING 2001::2(2001::2) 56 data bytes
From 2001::1 icmp_seq=1 Destination unreachable: Address unreachable
From 2001::1 icmp_seq=2 Destination unreachable: Address unreachable
From 2001::1 icmp_seq=3 Destination unreachable: Address unreachable
^CsendInt: writing chr(3)

--- 2001::2 ping statistics ---
4 packets transmitted, 0 received, +3 errors, 100% packet loss, time 3072ms

mininet-wifi>

```


Como se puede apreciar el comportamiento es el esperado, pero aun así, cabría pensar que la falla de conectividad entre ambos sensores es debida a otra razón, por ello se ánima al lector hacer un unload del programa XDP y probar de nuevo la conectividad entre ambos sensores.

```bash
# Quitamos el programa XDP de la interfaz 
mininet-wifi> sensor1 cd /home/n0obie/TFG/src/use_cases/xdp/case01 && sudo ./xdp_loader -S -U -d sensor1-wpan0
INFO: xdp_link_detach() removed XDP prog ID:677 on ifindex:248
mininet-wifi>


# Probamos de nuevo la conectividad entre ambos sensores
 mininet-wifi> sensor1 ping sensor2
PING 2001::2(2001::2) 56 data bytes
64 bytes from 2001::2: icmp_seq=1 ttl=64 time=0.053 ms
64 bytes from 2001::2: icmp_seq=2 ttl=64 time=0.044 ms
64 bytes from 2001::2: icmp_seq=3 ttl=64 time=0.044 ms
64 bytes from 2001::2: icmp_seq=4 ttl=64 time=0.106 ms
^CsendInt: writing chr(3)

--- 2001::2 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3049ms
rtt min/avg/max/mdev = 0.044/0.061/0.106/0.027 ms
mininet-wifi>

```


## Conclusiones

Teniendo en cuenta todos los aspectos comentados en este análisis de viabilidad, se concluye diciendo que los casos de uso no son extrapolables directamente, ya que las interfaces no son del tipo Ethernet. Esto implicaría rehacer el módulo de parsing de capa dos, algo admisible y factible. 


Por tanto, se propone a futuro llevar a cabo dicho desarrollo, además de estudiar y analizar distintas variables que entran en juego en un entorno inalámbrico de baja capacidad. Como son la batería, la memoria, el numero de transmisión y recepciones, entre otras. De esta forma se pretende ver que tecnología, si p4 ó XDP, nos permitirá programar dispositivos IoT con una mayor eficiencia en redes 802.15.4.




## Fuentes y enlaces de interés

*   [Source `ieee802154` en el Kernel de Linux](https://elixir.bootlin.com/linux/latest/source/drivers/net/ieee802154)
*   [Doc   `ieee802154` en el Kernel de Linux](https://www.kernel.org/doc/Documentation/networking/ieee802154.txt)
*   [Linux WPAN network development - github.org](https://github.com/linux-wpan)
*   [Linux WPAN network development - webpage](https://linux-wpan.org/)
*   [Herramientas de espacio de usuario para el stack `ieee802154`](https://github.com/linux-wpan/wpan-tools)




