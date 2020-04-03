# Wireless Tools 

Herramientas creadas con la finalidad de testear las interfaces en modo monitor creadas a mano en Mininet-Wifi. Generalmente, todas ellas serán utilizadas para inyectar paquetes en el medio, para ello se tiene que construir la totalidad de las cabeceras wireless desde la propia herramienta. Esto es así, ya que la interfaz en modo monitor, unicamente está pensada para la escucha de paquetes, no para su transmisión. Por ello, las cabeceras deberán ser construidas como ya se ha dicho desde de la herramienta, abrir un socket raw a dicha interfaz e inyectar el paquete.


|    Nombre de la herramienta   | Funcionalidad |
|:---------------:|:-------------------:|
| [``wping.py``](./wping.py) |  Generar pings con cabeceras 802.11 |

 
