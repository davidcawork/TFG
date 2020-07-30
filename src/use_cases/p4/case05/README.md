# P4 - Case05: Broadcast

In this test we will develop a p4 program that will make Broadcast. In this case we will only make a broadcast at the link level, layer 2. The motivation for this use case is to see the difference in difficulty with respect to the XDP environment where we had to anchor an additional eBPF bytecode in the [``TC``](http://man7.org/linux/man-pages/man8/tc.8.html) as well as our own XDP program anchored in the interface to achieve a broadcast.

In order to make a broadcast of the packages on p4 we will make use of the so called **multicast groups**. Multicast groups are used to broadcast over a series of port numbers on the switch, if you don't know where these port numbers come from go back to [case04](https://github.com/davidcawork/TFG/tree/master/src/use_cases/p4/case04). Each multicast group has a unique identifier, and in it a series of mirrors are defined, i.e. how many copies of the packet will be made and which port numbers will be affected.


Multicast groups are defined in the switch's control plane information, either via P4Runtime or via json with the ``sX-runtime.json`` files. We will now leave the definition of the multicast group used for this use case.

```json

"multicast_group_entries" : [
    {
      "multicast_group_id" : 1,
      "replicas" : [
        {
          "egress_port" : 1,
          "instance" : 1
        },
        {
          "egress_port" : 2,
          "instance" : 1
        },
        {
          "egress_port" : 3,
          "instance" : 1
        }
      ]
    }
  ]

```

With this definition we are indicating that all the packets that belong to the multicast group whose identifier is **1**, will generate a copy of the packet by the ports of the "switch" 1, 2 and 3. Therefore the broadcast/multicast action will be the following:

```C
action multicast() {
        standard_metadata.mcast_grp = 1;
}
```
We just assigned the package to that multicast group, and that's it. In my opinion it is much simpler than with XDP, so if you need to test protocols that implement diffusion as part of their logic it is much more advisable and feasible to make use of p4. 

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



Once the ``make run`` in this directory, we will have raised the topology described for this use case, which can be seen in the following figure.


![scenario](../../../../img/use_cases/p4/case05/scenario.png)

Going back to the use case check, we will have the CLI of [``Mininet``](https://github.com/mininet/mininet) open, so we will open three terminals for each host in the topology. This can be done in the following way:

```bash

mininet> xterm h1 h2 h3 
```

When we have the three terminals open, we will proceed to listen to the interfaces of host2 and host3. We will do this by using the ``tcpdump`` tool, we could also use Wireshark.

```bash

# We do the same on host2 and host3
tcpdump -l

```

Once we are listening from host2 and host3, we are going to generate ARP Request from host1 so that, when going with MAC destination to FF's, it will propagate through all possible ports of the "switch" except the one through which it arrived. Therefore, we make a:

```bash
# From host1
arping 10.0.2.2
```

If it worked correctly, the ARP Request package should have reached both host2 and host3. But it will only be host2, in this case, that will answer since it was addressed to it. You will see that host3 only gets one ARP Request, and then stops, why :sweat_smile:? This is because when the ARP resolution is completed, host1 already knows the MAC address of host2, so the ARP Requests generated later will have the destination MAC address of host2, so our "switch" will not broadcast it through all its ports, it will be passed directly to host2. 

## References 

* [P4 Tutorials](https://github.com/p4lang/tutorials)
* [Multicas issue](https://github.com/p4lang/tutorials/issues/337)
* [Multicast Execise](https://github.com/p4lang/tutorials/tree/master/exercises/multicast)

---


# P4 - Case05: Broadcast

En este test desarrollaremos un programa p4 que haga Broadcast. En este caso unicamente haremos Broadcast a nivel de enlace, capa 2. La motivación de este caso de uso es ver la diferencia de dificultad respecto del entorno XDP donde tuvimos que anclar de manera adicional un bytecode eBPF en el [``TC``](http://man7.org/linux/man-pages/man8/tc.8.html) además de propio programa XDP anclado en la interfaz para lograr hacer un broadcast.

Para conseguir hacer una difusión de los paquetes en p4 haremos uso de los llamados **grupos multicast**. Los grupos multicast se utilizan para difundir por una serie de números de puertos del "switch", si no sabe de donde salen estos números de puerto vuelva al [case04](https://github.com/davidcawork/TFG/tree/master/src/use_cases/p4/case04). Cada grupo multicast tiene un identificador único, y en él se definen una serie de replicas, es decir, cuantas copias del paquete se llevarán a cabo y que números de puertos se verán afectados.

Los grupos multicast se definen en la información del plano de control del "switch", bien via P4Runtime ó via json con los ficheros ``sX-runtime.json``. A continuación, dejamos la definición del grupo multicast utilizado para este caso de uso.

```json

"multicast_group_entries" : [
    {
      "multicast_group_id" : 1,
      "replicas" : [
        {
          "egress_port" : 1,
          "instance" : 1
        },
        {
          "egress_port" : 2,
          "instance" : 1
        },
        {
          "egress_port" : 3,
          "instance" : 1
        }
      ]
    }
  ]

```

Con esta definición estamos indicando que todos los paquetes que pertenezcan al grupo multicast cuyo identificador sea **1**, generarán una copia del paquete por los puertos del "switch" 1, 2 y 3. Es decir por todos los puertos de nuestro "switch" para este caso de uso. Por tanto la acción de broadcast/multicast será la siguiente:

```C
action multicast() {
        standard_metadata.mcast_grp = 1;
}
```
Unicamente asignamos el paquete a dicho grupo multicast, y ya estaría. A mi parecer mucho más sencillo que con XDP, por tanto de necesitar probar protocolos que implementen la difusión como parte de su lógica es mucho más recomendable y viable hacer uso de p4. 

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



Una vez realizado el ``make run`` en este directorio, tendremos levantada la topología descrita para este caso de uso, la cual se puede apreciar en la siguiente figura.


![scenario](../../../../img/use_cases/p4/case05/scenario.png)

Volviendo de nuevo a la comprobación del funcionamiento del caso de uso, tendremos la CLI de [``Mininet``](https://github.com/mininet/mininet) abierta, por lo que nos dispondremos a abrir tres terminales para cada host de la topología. Esto lo podemos hacer de la siguiente manera:

```bash

mininet> xterm h1 h2 h3 
```

Cuando ya tengamos las tres terminales abiertas, procederemos a escuchar las interfaces de los host2 y host3. Esto lo haremos haciendo uso de la herramienta ``tcpdump``, podríamos utilizar también Wireshark.

```bash

# Hacemos lo mismo en el host2 y host3
tcpdump -l

```

Una vez que estamos escuchando desde el host2 y host3, vamos a generar ARP Request desde el host1 para que así, al ir con MAC destino a FF's se propague por todos los posibles puertos del "switch" menos por aquel por el cual le llegó. Por tanto, hacemos un:

```bash
# Desde el host1
arping 10.0.2.2
```

Si funciona correctamente se el paquete ARP Request debería haber llego tanto al host2 como el host3. Pero solo será el host2, en este caso, el que contestará ya que iab dirigido a este. Verá que al host3 solo le llega un ARP Request, y después se detiene, ¿El por qué :sweat_smile:? Esto es así ya que al completarse la resolución ARP el host1 ya conoce la dirección MAC del host2, por tanto los ARP Request que se generen a posteriori llevarán la MAC destino la del host2, entonces nuestro "switch" no lo difundirá por todos su puertos, se lo pasará directamente al host2. 

## Fuentes

* [P4 Tutorials](https://github.com/p4lang/tutorials)
* [Multicas issue](https://github.com/p4lang/tutorials/issues/337)
* [Multicast Execise](https://github.com/p4lang/tutorials/tree/master/exercises/multicast)

