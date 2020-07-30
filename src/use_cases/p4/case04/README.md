# P4 - Case04: Layer 3 Forwarding


In this case of use we will try to implement a network level forwarding, layer 3, so our hypothetical "switch" will now be a very basic router with very few functionalities :smirk:. For this reason it is convenient to remember the notes we made about the [``BMV2``](https://github.com/p4lang/behavioral-model) and why we should not define it only as a soft-switch, since it depends on the p4 program it carries to define its datapath and its interface with the control plane. 

The motivation for this use case is to see the relationship that the XDP return code called ``XDP_REDIRECT`` has with p4, and thus see its equivalent. In the previous [use case](https://github.com/davidcawork/TFG/blob/master/src/use_cases/p4/case03/) we already used the metadata information to choose the outgoing port of the packet. This is the direct equivalent of forwarding on XDP, but here on p4 it is easier, since we only specify the port number, while on XDP we have to obtain the ``ifindex`` of the interface to which we are forwarding. We leave the sentence here: 

```C


standard_metadata.egress_spec = port

```

But to all this, **Port numbers? When did we establish these numbers?** :joy: 

Good question. These port numbers are set when the [``BMV2`` instance is lifted](https://github.com/p4lang/behavioral-model). A real interface is associated with an identifying number, these identifying numbers will be the port numbers of each "switch". In this way, the switch has all its possible ports within reach. The collection of the instances of [``BMV2``](https://github.com/p4lang/behavioral-model) is carried out by loading the script [``run_exercise.py``](https://github.com/davidcawork/TFG/blob/master/src/use_cases/p4/utils/run_exercise.py). The script uses the [``P4RuntimeSwitch``](https://github.com/davidcawork/TFG/blob/master/src/use_cases/p4/utils/p4runtime_switch.py#L100) class to raise the switch with the appropriate parameters. We can pick up an instance of [``BMV2``](https://github.com/p4lang/behavioral-model) ourselves by making a:

```bash

sudo simple_switch_grpc --log-console --dump-packet-data 64 \
                        –i 0@veth0 -i 1@veth2 … [--pcap] --no-p4 \
                        --grpc-server-addr 0.0.0.0:50051 --cpu-port 255 \
                        test.json

```

Once we understand where the port numbers come from we can ask ourselves the following question, **How is a p4 program able to know the possible ports it may have available to forward a packet? 

It can't, and it's not logical that a p4 program where you define the datapath already has the possible port numbers to handle. If that were so, we would have to have different p4 programs for each entity with a different number of ports (only to implement a single datapath). This is not feasible. Therefore, all the information related to the ports (associated to the forwarding) usually comes from the control plane who has a record of the ports of that "switch". 

For example, if I want to forward a packet to a specific port given its IP, we will need the control plane to tell us the criteria to follow, which IPs are associated with which ports. This interface between the data plane and the control plane is defined by **tables**.

From the program p4 we have to define the skeleton of the table, indicating that _actions_ are available, which parameters receive those _actions_, which criteria of _match_ the table will have, on _keys_ the _lookup_ will be done and which is the maximum number of entries in that table. Next, a [figure](https://github.com/p4lang/tutorials/blob/master/P4_tutorial.pdf) that summarizes quite well the functionality of the tables: 

![table](../../../../img/use_cases/p4/case04/table.png)

And from the control plane, via P4Runtime or via json with the ``sX-runtime.json`` files (which will be loaded through the CLI-BMV2), the entries of that table and the parameters of the actions to be carried out when there is a hit with that entry will be popular. In our case, IPs will be associated to a forwarding action where we will pass through which port the packet must leave and which destination MAC must carry.

Once we understand the port numbers, and the concept of the tables, we must approach how to do a forwarding action to resend our packets. This forwarding action should be able to update the outbound port, update the destination MAC and decrease the ``ttl`` field in the IP header by one. The following is the proposed action to perform this task:

```C

/*
 * We wanted to use the '-=' operator but the syntax of P4 does not allow it :(
 */

action ipv4_forward(macAddr_t dstAddr, egressSpec_t port) {
        standard_metadata.egress_spec = port;
        hdr.ethernet.srcAddr = hdr.ethernet.dstAddr;
        hdr.ethernet.dstAddr = dstAddr;
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
}

```

Having the action already available, we would only have to apply the table in our p4 program pipeline and we would already be doing a forwarding in layer 3 :smile:.

## Compilation and setting up the scenario 

For the compilation of our p4 program we will use the compiler [``p4c``](https://github.com/p4lang/p4c). If you are not familiar with this compiler or do not know how to compile a p4 program, we recommend that you return to [case01](https://github.com/davidcawork/TFG/tree/master/src/use_cases/p4/case01) where it is explained how the compilation is done and which steps it takes. 

Since people who want to replicate the use cases may not be very familiar with this whole compilation and upload process in the [``BMV2``](https://github.com/p4lang/behavioral-model) process, a Makefile has been provided to automate the compilation and upload tasks, and the cleanup tasks of the use case. Then for the implementation of the use case we must make a:

```bash
sudo make run
```

Once we have finished checking the correct functioning of the use case, we must use another Makefile target to clean the directory. In this case we must use :

```bash
sudo make clean
```

It is important to note that this target will clean up both the auxiliary files for loading the p4 program into the [``BMV2``](https://github.com/p4lang/behavioral-model), and the directories of ``pcaps``, ``log``, and ``build`` generated at the start of the scenario. So if you want to keep the captures of the different interfaces of the different [BMV2](https://github.com/p4lang/behavioral-model), copy them or clean the scenario by hand as follows:

```bash

# Clean Mininet
sudo mn -c

# We clean dynamically generated directories on the stage load
sudo rm -rf build logs

```

## Testing 

Once the ``make run`` is done in this directory, we will have the topology described for this use case, which can be seen in the following figure. As our datapath does not contemplate the handling of ARP, the ARP entry has been added from the file [``topology.json``](scenario/topology.json) so that the ARP resolution is not generated in the ICMP Request submission. This is a bit of a "botched" arrangement as we are telling you a hypothetical gateway that does not exist, and we are adding an ARP entry with the MAC of that gateway, this way all the packets will go out with the destination MAC indicated in the entry and the ARP resolution will not be produced. When the packet arrives at the "switch" it will be modified to its destination MAC, so the "botch" will not go any further! :joy: 

![scenario](../../../../img/use_cases/p4/case04/scenario.png)


Going back to the use case check, we'll have the CLI of [``Mininet``](https://github.com/mininet/mininet) open, so we'll just test the connectivity between all the hosts. This can be done as follows:

```bash

mininet> pingall
```

Additionally, a sniffer could be used to check that the packets arrive with the ``ttl`` field modified, depending on the jumps the packet has made. :smile:

## References  

*   [P4 tutorial](https://github.com/p4lang/tutorials)


---

# P4 - Case04: Layer 3 Forwarding


En este caso de uso trataremos de implementar un forwarding a nivel de red, capa 3, por ello nuestro hipotético "switch" será ahora un un router muy básico y con muy pocas funcionalidades :smirk:. Por ello conviene recordar las anotaciones que hicimos sobre el [``BMV2``](https://github.com/p4lang/behavioral-model) y por que no debemos definirlo únicamente como un soft-switch, ya que depende del programa p4 que porte para definir su datapath y su interfaz con el plano de control. 

La motivación de este caso de uso es ver la relación que tiene el código de retorno XDP llamado ``XDP_REDIRECT`` con p4, y así ver su equivalente. En el anterior [caso de uso](https://github.com/davidcawork/TFG/blob/master/src/use_cases/p4/case03/) ya hacíamos uso de la información de metadatos para eligir el puerto de salida del paquete. Por lo que podríamos afirmar que este es el equivalente directo al  forwarding en XDP, solo que aquí en p4 nos resulta más sencillo ya que únicamente indicamos por número de puerto mientras que XDP debíamos obtener el ``ifindex`` de la interfaz a la cual íbamos hacer el reenvío. Dejamos aquí la sentencia: 

```C


standard_metadata.egress_spec = port

```

Pero a todo esto, **¿Números de puerto? ¿Cúando hemos establecido estos números?** :joy: 

Buena pregunta.. Estos números de puerto se establecen cuando se levanta la instancia del [``BMV2``](https://github.com/p4lang/behavioral-model). Se asocia interfaz real con un número identificativo, serán estos números identificativos los números de puerto de cada "switch". De esta manera el "switch" tiene a su alcance todos sus posibles puertos. El levantamiento de las instancias de [``BMV2``](https://github.com/p4lang/behavioral-model) se llevan a cabo con la carga del script [``run_exercise.py``](https://github.com/davidcawork/TFG/blob/master/src/use_cases/p4/utils/run_exercise.py). Este a su vez hace uso de la clase [``P4RuntimeSwitch``](https://github.com/davidcawork/TFG/blob/master/src/use_cases/p4/utils/p4runtime_switch.py#L100) para levantar dicho "switch" pasándole los parámetros adecuados. Podemos levantar una instancia del [``BMV2``](https://github.com/p4lang/behavioral-model) nosotros mismos haciendo un:

```bash

sudo simple_switch_grpc --log-console --dump-packet-data 64 \
                        –i 0@veth0 -i 1@veth2 … [--pcap] --no-p4 \
                        --grpc-server-addr 0.0.0.0:50051 --cpu-port 255 \
                        test.json

```

Una vez entendido de donde salen los números de puerto podemos preguntarnos lo siguiente, **¿Cómo un programa p4 es capaz de conoces los posibles puertos de los que puede disponer para reenviar un paquete?** 

No puede, y tampoco es lógico que en un programa p4 donde defines el datapath ya estén preestablecidos los números de puerto posibles a manejar. Ya que si eso fuera así, tendríamos que tener distintos programas p4 por cada entidad con un número de puertos distintos ( unicamente para implementar un único datapath). No es viable. Por ello, toda la información relativa a los puertos (asociada al forwarding) generalmente suele venir desde el plano de control quien tiene constancia de los puertos de dicho "switch". 

Por ejemplo, si yo quiero hacer forwarding de un paquete a un puerto en especifico dado su IP, necesitaremos que el plano de control nos indique el criterio a seguir, que IPs están asociadas a según que puertos. Esta interfaz entre el plano de datos y el plano de control esta definidas por **tablas**.

Desde el programa p4 tenemos que definir el esqueleto de la tabla, indicando que _actions_ están disponibles, que parámetros reciben esas _actions_, que criterio de _match_ tendrá la tabla, sobre _keys_ se realizará el _lookup_ y cual es el número máximo de entradas en dicha tabla. A continuación, una [figura](https://github.com/p4lang/tutorials/blob/master/P4_tutorial.pdf) que resume bastante bien la funcionalidad de las tablas: 

![table](../../../../img/use_cases/p4/case04/table.png)

Y desde el plano de control, vía P4Runtime ó vía json con los ficheros ``sX-runtime.json`` ( que se cargarán a través de la CLI-BMV2), se popularán las entradas de dicha tabla y los parámetros de las acciones a llevar a cabo cuando haya un hit con dicha entrada. En nuestro caso se asociarán IPs, a una acción de forwarding donde le pasaremos por que puerto tiene que salir el paquete y que MAC destino debe llevar.

Una vez entendidos los números de puerto, y el concepto de las tablas, debemos abordar el cómo hacer una acción de forwarding para reenviar nuestros paquetes. Esta acción de forwarding deberá se capaz de actualizar el puerto de salida, actualizar la MAC destino y decrementar en uno el campo ``ttl`` de la cabecera IP. A continuación se indica la acción propuesta para llevar a cabo dicho cometido:

```C

/*
 * Se quiso hacer uso del operador '-=' pero la sintaxis de P4 no lo permite :(
 */

action ipv4_forward(macAddr_t dstAddr, egressSpec_t port) {
        standard_metadata.egress_spec = port;
        hdr.ethernet.srcAddr = hdr.ethernet.dstAddr;
        hdr.ethernet.dstAddr = dstAddr;
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
}

```

Teniendo la acción ya disponible, solo nos quedaría aplicar la tabla en nuestra pipeline de nuestro programa p4 y ya estaríamos haciendo un forwarding en capa 3 :smile:.

## Compilación y puesta en marcha del escenario

Para la compilación de nuestro programa p4 se hará uso del compilador [``p4c``](https://github.com/p4lang/p4c). Si usted no conoce dicho compilador o desconoce el proceso de compilación de un programa p4 le recomendamos que vuelva al [case01](https://github.com/davidcawork/TFG/tree/master/src/use_cases/p4/case01) donde se explica como se lleva a cabo la compilación y por que etapas transcurre. 

Dado que las personas que quieran replicar los casos de uso puede que no estén muy familiarizadas con todo este proceso de compilación y carga en los procesos de [``BMV2``](https://github.com/p4lang/behavioral-model), se ha dispuesto un de un Makefile para automatizar las tareas de compilación y carga, y las tareas de limpieza del caso de uso. Entonces para la puesta en marcha del caso de uso debemos hacer un:

```bash
sudo make run
```

Una vez hayamos finalizado la comprobación del correcto funcionamiento del caso de uso debemos hacer uso de otro target del Makefile para limpieza del directorio. En este caso debemos hacer uso de:

```bash
sudo make clean
```

Es importante señalar que este target limpiará tanto los ficheros auxiliares para la carga del programa p4 en el [``BMV2``](https://github.com/p4lang/behavioral-model), como los directorios de ``pcaps``, ``log``, y ``build`` generados en la puesta en marcha del escenario. Por lo que si se desea conservar las capturas de las distintas interfaces de los distintos  [``BMV2``](https://github.com/p4lang/behavioral-model), cópielas o haga la limpieza del escenario a mano de la siguiente manera:

```bash

# Limpiamos Mininet
sudo mn -c

# Limpiamos los directorios generados dinámicamente en la carga del escenario
sudo rm -rf build logs

```

## Comprobación del funcionamiento

Una vez realizado el ``make run`` en este directorio, tendremos levantada la topología descrita para este caso de uso, la cual se puede apreciar en la siguiente figura. Como en nuestro datapath no se contempla el manejo de ARP se ha añadido el ARP entry a pelo desde el fichero [``topology.json``](scenario/topology.json) consiguiendo así que no se genere la resolución ARP en el envión de los ICMP Request. Este arreglo es un poco "chapuzero" ya que le estamos indicándole un hipotético gateway que no existe, y estamos añadiendo un ARP entry con la MAC de dicho gateway, de esta forma todos los paquetes saldrán con la MAC destino indicada en la entry y no se producirá la resolución ARP. Al llegar al "switch" el paquete verá modificada su MAC destino en función de su IP destino, por lo que la "chapuza" no irá a más! :joy: 

![scenario](../../../../img/use_cases/p4/case04/scenario.png)


Volviendo de nuevo a la comprobación del funcionamiento del caso de uso, tendremos la CLI de [``Mininet``](https://github.com/mininet/mininet) abierta, por lo que simplemente probaremos la conectividad entre todos los host. Esto lo podemos hacer de la siguiente manera:

```bash

mininet> pingall
```

De forma adicional, se podría hacer uso de un sniffer para comprobar que los paquetes llegan con el campo ``ttl`` modificado, en función de los saltos que ha dado el paquete. :smile:

## Fuentes 

*   [P4 tutorial](https://github.com/p4lang/tutorials)




