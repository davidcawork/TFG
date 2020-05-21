# Future work: Analisis  de casos de uso sobre el estandar ieee802154




## Herramientas entorno `ieee802154`

| Herramienta         | Explicación  | Enlace |  
|---------------|-----|----|
| `iwpan`              | Herramienta principal para la configuración del subsistema `ieee802154`, sus interfaces y sus radios. Esta herramienta es muy similar a al herramienta `iw` pensada para controlar el subsistema Wireless del Kernel de Linux.  | [Link al source](https://github.com/linux-wpan/wpan-tools/tree/master/src) |
| ``wpan-hwsim``             | Herramienta para gestionar el modulo `mac802154_hwsim`, permitiendo añadir o eliminar radios, así como añadir enlaces entre distintos radios a través de `netlink`.  | [Link al source](https://github.com/linux-wpan/wpan-tools/tree/master/wpan-hwsim) |
| ``wpan-ping``        | Herramienta para hacer ping directamente con el stack `ieee802154`   | [Link al source](https://github.com/linux-wpan/wpan-tools/tree/master/wpan-ping) |


No obstante se ha probado a añadir un programa XDP a una interfaz generada por el modulo `mac802.154_hwsim` y tanto la carga como su funcionalidad a nivel de códigos de retorno han sido satisfactoria.


## Fuentes y enlaces de interés

*   [Source `ieee802154` en el Kernel de Linux](https://elixir.bootlin.com/linux/latest/source/drivers/net/ieee802154)
*   [Doc   `ieee802154` en el Kernel de Linux](https://www.kernel.org/doc/Documentation/networking/ieee802154.txt)
*   [Linux WPAN network development - github.org](https://github.com/linux-wpan)
*   [Linux WPAN network development - webpage](https://linux-wpan.org/)
*   [Herramientas de espacio de usuario para el stack `ieee802154`](https://github.com/linux-wpan/wpan-tools)




