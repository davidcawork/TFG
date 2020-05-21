# Use cases xdp - p4

En este directorio se encuentran distintos casos de uso, a replicar con cada tecnología xdp - p4 para así conocer sus limitaciones y ventajas. Todos estos casos de uso se desarrollarán para los siguientes medios:

- Ethernet (cableado)
- Wireless


| Cases         | xdp | p4 |  p4-wireless | xdp-wireless    |
|---------------|-----|----|---| --- |
| case01 - Drop               | :white_check_mark:    | :white_check_mark:   |  :white_check_mark:  | :white_check_mark: |
| case02 - Pass               | :white_check_mark:    | :white_check_mark:   |  :white_check_mark:  | :white_check_mark: |
| case03 - Echo server        | :white_check_mark:    | :white_check_mark:   |  :white_check_mark:  | :white_check_mark: |
| case04 - Layer 3 forwarding | :white_check_mark:    | :white_check_mark:   |  :white_check_mark:  | :white_check_mark: |
| case05 - Broadcast          | :white_check_mark:    | :white_check_mark:   |  :white_check_mark:  | :white_check_mark: |


<br />
<br />


De forma adicional, se quiere explorar la viabilidad de hacer uso del modulo `mac802154_hwsim` para replicar los casos de uso y ver las limitaciones, y puntos fuertes que tendrían P4 y XDP en ese medio inlámbrico de baja capacidad. 

<br />


| Escenario         | Viabilidad |
|---------------|-----|
| Modulo del kernel `mac802154_hwsim` para replicar un medio inalámbrico de baja capacidad. | No es viable ya que este modulo sigue otra arquitectura, además de no ofrecer interfaces de Ethernet conectadas a la "tarjeta 802.15.4 emulada", por lo que habría que rehacer las distintas etapas de parsing en cada caso de uso. |

