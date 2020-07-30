# P4 Wireless - Case02: Pass

As you can see in this directory there is no p4 program. This is because there is no equivalent in p4 of the return code XDP_PASS, so nothing can be done in this case of use. The following is an indication of why there is no equivalent between the two technologies.

The return code in XDP is a way to carry out an action with the packet arriving at the interface, in which an XDP program is anchored. For more information on return codes, see the following [README](https://github.com/davidcawork/TFG/tree/master/src/use_cases/xdp/case03) which indicates in detail how many there are, what they are for, and what limitations they have. 

In this case the ``XDP_PASS`` return code implies that the packet is passed to the next point in the network stack processing in the Linux Kernel. That is, if the program is anchored to the NIC, the packet will be passed to the [``TC``](http://man7.org/linux/man-pages/man8/tc.8.html), from there to the network stack itself to parse its headers, and then fed to the socket interface.

On p4, the environment for the use cases will be [``Mininet Wifi``](https://github.com/davidcawork/mininet_wifi) with "APs" ([``BMV2``](https://github.com/p4lang/behavioral-model)) and host. The "APs" ([``BMV2``](https://github.com/p4lang/behavioral-model)) is a switch software that allows us to inject p4 code, with which we can define the datapath of it.

Now, here comes the big difference between both technologies: with XDP you can always pass the packet to the Kernel to take care of the processing, but on p4, we must define exclusively the whole datapath, so there is no one to delegate the packet to, we have to take care of it ourselves. Then, as such, there would be no equivalent of the ``XDP_PASS`` on p4.

---


# P4 Wireless - Case02: Pass

Como se puede apreciar en este directorio no hay ningún programa p4. Esto se debe a que no hay equivalente en p4 del código de retorno XDP_PASS, por ello, no se puede hacer nada en este caso de uso. A continuación, se indica el por qué no se encuentra un equivalente entre ambas tecnologías.

El código de de retorno en XDP es una forma para llevar a cabo una acción con el paquete que llega a la interfaz, en la cual hay anclado un programa XDP. Para más información sobre los códigos de retorno consultar el siguiente [README](https://github.com/davidcawork/TFG/tree/master/src/use_cases/xdp/case03) donde se indica en detalle cuantos hay, para qué sirven y qué limitaciones tienen. 

En este caso el código de retorno ``XDP_PASS`` implica que el paquete se pasa al siguiente punto del procesamiento del stack de red en el Kernel de Linux. Es decir, si el programa está anclado a la NIC, se dejará pasar el paquete al [``TC``](http://man7.org/linux/man-pages/man8/tc.8.html), de ahí al propio stack de red para parsear sus cabeceras, y más adelante, dárselo de comer a la interfaz de sockets.

En p4, el entorno donde se llevaran a cabo los casos de uso será [``Mininet Wifi``](https://github.com/davidcawork/mininet_wifi) con "APs" ([``BMV2``](https://github.com/p4lang/behavioral-model)) y host. Los "APs" ([``BMV2``](https://github.com/p4lang/behavioral-model)) es un software switch que nos permite inyectarle código p4, con el cual podemos definir el datapath del mismo.

Ahora bien, aquí viene la gran diferencia entre ambas tecnologías: con XDP siempre puedes pasarle el paquete al Kernel para que se encargue el del procesamiento, pero en p4, debemos definir nosotros de forma exclusiva todo el Datapath, por lo que no hay a quien delegar el paquete, nos tenemos que encargar nosotros. Entonces, como tal, no habría equivalente del ``XDP_PASS`` en p4.
