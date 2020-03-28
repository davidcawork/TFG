# P4lang-wireless Implementation 

La motivación de esta implementación viene dada para el estudio de los distintos datapaths en entornos wireless. La única plataforma consolidada para la emulación de entornos SDN-wireless es Mininet-Wifi, por ello, se empezó la búsqueda por su repositorio. Por desgracia no se encontró ninguna mención del lenguaje p4 en dicho repositorio. Investigando más, se encontró que el creador de Mininet-Wifi y profesor de la IFBA, [Ramon Fontes](https://github.com/ramonfontes), había hecho un [fork](https://github.com/ramonfontes/tutorials)  de los tutoriales de p4 y los había adaptado a Mininet-Wifi, aunque como según recoge el [aquí](https://github.com/p4lang/tutorials/issues/301) en este issue abierto en p4lang-tutorials, aun le queda mucho desarrollo por delante, es solo un primer paso. 

Viendo la actividad de dicho repositorio se entiende que de momento el desarrollo no ha progresado mucho más, ya que no hay actividad en él desde el 2019. Por tanto, como se tiene la necesidad de procesar paquetes con la cabeceras WiFi, y viendo que en todos los programas desarrollados en p4 por Ramon el BMV2 trabaja sobre Ethernet, nos vamos a aventurar a montar un escenario donde el BMV2 posea interfaces wireless, para así, poder procesar las cabeceras que necesitamos.

Por tanto, se propone el siguiente plan para abordar el desarrollo:

*   Entender y analizar la interfaz creada desde la organización P4Lang, del BMV2 con Mininet.
*   Entender y analizar la integración realizada por Ramon de la interfaz creada por P4Lang y Mininet-Wifi.
*   Una vez entendidas ambas interfaces vez si es posible conseguir que el BMV2 corra en una netns y posea interfaces wireless.   

Si la magnitud de ambas interfaces fuera inaccesible por su gran complejidad, se propone ir directamente al bajo nivel de Mininet-Wifi, hacer uso de ``wmediumd`` y del modulo del kernel ``mac80211_hwsim`` para montar escenarios custom para llevar a cabo nuestros casos de uso.


## P4Switch (BMV2) - Mininet Interface

Desde la organización de P4lang se quiso suministrar un entorno de pruebas donde se pudiera probar los programas p4 desarrollados. El soft-switch donde iban a cargar el programa p4 ya lo tenían, que es el [``BMV2``](https://github.com/p4lang/behavioral-model), pero les faltaba una plataforma donde poder desplegar dicho "switch" e interconectarlo con otras entidades de red. Esta plataforma sería Mininet, una herramienta de emulación de redes. 

Mininet generalmente se utiliza para emular entornos SDN con switches y controladores, por ello, para lograr la integración de su nuevo switch con los switches ya disponibles en Mininet, tuvieron que añadir una nueva clase llamada [``P4Switch``](https://github.com/p4lang/tutorials/blob/master/utils/p4_mininet.py#L57). Esta nueva clase, heredaría de la clase ``Switch`` de Mininet, añadiendo así todos los métodos y atributos necesarios para la orquestación del  [``BMV2``](https://github.com/p4lang/behavioral-model).

Usualmente, cuando se trabaja con Mininet se desarrollan scripts donde se define la topologia de la red a emular. En este caso para brindar de una mayor facilidad a los users de los tutoriales de P4, las topologias se definen en archivos ``*.json``, los cuales definen toda la topología de red y toda la información del plano de control de cada "switch" P4. Un ejemplo de dicho archivo pueden encontrarse [aquí](https://github.com/davidcawork/TFG/blob/master/src/use_cases/p4/case01/scenario/topology.json). 


De esta forma también se consigue abstraer el la definición de la topología del propio script de orquestación de la misma. El script de orquestación de la topología, el cual hará uso de la API de Python de Mininet será el famoso script llamado [``run_exercise.py``](https://github.com/davidcawork/TFG/blob/master/src/use_cases/p4/utils/run_exercise.py). De esta manera tendremos tantos ficheros ``*.json`` como topologías queramos, pero un único script de orquestación.

El script [``run_exercise.py``](https://github.com/davidcawork/TFG/blob/master/src/use_cases/p4/utils/run_exercise.py) inicializa un objeto de la clase ``ExerciseRunner`` el cual parseará el fichero ``*.json``, procesará la topología con la ayuda de la clase ``ExerciseTopo`` y levantará la topologia haciendo uso de la API de Python de Mininet. A continuación, se puede apreciar un diagrama UML donde se indica la relación de clases desde nuestro _entrypoint_ en el levantamiento de los distintos casos de uso.


![UML_no_extendido](../../../img/p4-wireless/run_exercise_pertenencia.png)

Como ya se comentaba anteriormente, para logar la integración del [``BMV2``](https://github.com/p4lang/behavioral-model) en Mininet se tuvo que crear la clase [``P4Switch``](https://github.com/p4lang/tutorials/blob/master/utils/p4_mininet.py#L57). Esta nueva clase, heredaría de la clase ``Switch`` de Mininet. A su vez, se crearían nuevas clases hijas de la clase [``P4Switch``](https://github.com/p4lang/tutorials/blob/master/utils/p4_mininet.py#L57), la más importante [``P4RuntimeSwitch``](https://github.com/p4lang/tutorials/blob/master/utils/p4runtime_switch.py#L27) la cual se utilizaría para configurar dicho "switch" via [``P4Runtime``](https://github.com/p4lang/PI) :smile: . Si se desea ver una vista más amplia de este mismo UML, mostrando métodos y atributos, ir [aquí](../../../img/p4-wireless/run_exercise.png).

![UML_no_extendido](../../../img/p4-wireless/run_exercise_class_names_only.png)

### Ejemplo traza de ejecución - case01

Para una mejor compresión del funcionamiento interno de la interfaz del [``BMV2``](https://github.com/p4lang/behavioral-model) con Mininet, se va analizar exhaustivamente la traza de ejecución del [case01](https://github.com/davidcawork/TFG/tree/master/src/use_cases/p4/case01). Se han obtenido distintas modos de trazas de ejecución con el fin de obtener un mejor entendimiento de cual es el workflow de la interfaz. A continuación, dejamos los enlaces a dichas trazas por si se quisieran consultar:

*   [System trace ](./analysis/p4-Mininet/strace_case01.log) [ traza de llamadas al sistema del [case01](https://github.com/davidcawork/TFG/tree/master/src/use_cases/p4/case01) ]
*   [Mininet debug trace ](./analysis/p4-Mininet/trace_case01_debug.log)[ traza de ejecución del [case01](https://github.com/davidcawork/TFG/tree/master/src/use_cases/p4/case01), con el nivel de log a debug ]
*   [Pyreverse execution trace](./analysis/p4-Mininet/trace_case01_run_exer_raw.log) [ traza de ejecución del [case01](https://github.com/davidcawork/TFG/tree/master/src/use_cases/p4/case01), obtenido con el módulo pyreverse ]
*   [Pyreverse execution trace - cleaned](./analysis/p4-Mininet/trace_case01_run_exer.log) [ traza de ejecución del [case01](https://github.com/davidcawork/TFG/tree/master/src/use_cases/p4/case01), obtenido con el módulo pyreverse ]

*   [Fuctions list](./analysis/p4-Mininet/trace_case01_run_exer_functions.log) [ traza de ejecución del [case01](https://github.com/davidcawork/TFG/tree/master/src/use_cases/p4/case01), se obtiene las funciones impactadas durante el workflow ]

| Descripción        | Operación     | Clase           | Método |
| -------------      |:-------------:| :-------------: | :-------------: |
| Inicializa atributos y lee la topología del json.  |     Reading topology file.            | [`ExerciseRunner`](https://github.com/davidcawork/TFG/blob/master/src/use_cases/p4/utils/run_exercise.py#L122) | [`__init__`](https://github.com/davidcawork/TFG/blob/master/src/use_cases/p4/utils/run_exercise.py#L152) |
| Se asegura de que los dir. (build, logs, pcap) estén creados y los asigna. | - | [`ExerciseRunner`](https://github.com/davidcawork/TFG/blob/master/src/use_cases/p4/utils/run_exercise.py#L122) | [`__init__`](https://github.com/davidcawork/TFG/blob/master/src/use_cases/p4/utils/run_exercise.py#L175) |
| Método principal donde se parsea la topología del JSON, levanta la instancia de Mininet, configura los nodos y por último corre la CLI. | - | [`ExerciseRunner`](https://github.com/davidcawork/TFG/blob/master/src/use_cases/p4/utils/run_exercise.py#L122) |  [`run_exercise`](https://github.com/davidcawork/TFG/blob/master/src/use_cases/p4/utils/run_exercise.py#L187) | 
| Crea el obj Mininet, y lo guarda en `self.net`. | Building mininet topology. | [`ExerciseRunner`](https://github.com/davidcawork/TFG/blob/master/src/use_cases/p4/utils/run_exercise.py#L122) | [`create_network`](https://github.com/davidcawork/TFG/blob/master/src/use_cases/p4/utils/run_exercise.py#L237) |
| Función Aux. para inicializar correctamente la clase del "switch". (Generalmente `ConfiguredP4RuntimeSwitch`) | - | - | [`configureP4Switch`](https://github.com/davidcawork/TFG/blob/master/src/use_cases/p4/utils/run_exercise.py#L35) |
| Se crea un obj de la clase `ExerciseTopo` para así generar el obj `Topo` de Mininet con toda la información necesaria para su posterior generación. Se guardará en `self.topo` | - | [`ExerciseTopo`](https://github.com/davidcawork/TFG/blob/master/src/use_cases/p4/utils/run_exercise.py#L67) |  [`__init__`](https://github.com/davidcawork/TFG/blob/master/src/use_cases/p4/utils/run_exercise.py#L70) |
| Se crea el obj Mininet llamando a su constructor. Se le pasa el obj `Topo`, el tipo de link `TCLink`, el tipo de host `P4Host`, el tipo de switch `ConfiguredP4RuntimeSwitch` | - | [`ExerciseRunner`](https://github.com/davidcawork/TFG/blob/master/src/use_cases/p4/utils/run_exercise.py#L122) | [`create_network`](https://github.com/davidcawork/TFG/blob/master/src/use_cases/p4/utils/run_exercise.py#L254) |
| Se inicializan los atributos del obj `Mininet`, entre ellos obtiene el num. de cores | `grep -c processor /proc/cpuinfo` | [`Mininet`](https://github.com/mininet/mininet/blob/master/mininet/net.py#L113) | [`__init__`](https://github.com/mininet/mininet/blob/master/mininet/net.py#L116) |
| Inicializa Mininet, es decir, se asegura que tiene [permisos de root](https://github.com/mininet/mininet/blob/2b8d254cc0c99f823fdea91c442cf0365761d469/mininet/util.py#L660) y establece unos [límites mínimos](https://github.com/mininet/mininet/blob/2b8d254cc0c99f823fdea91c442cf0365761d469/mininet/util.py#L507) para poder llevar a cabo la emulación. ( Incrementa el num. de archivos abiertos al mismo tiempo, aumenta los buffers del stack red, aumenta el cache arp más tamaño de tabla de rutas, añade más intf PTYs para los nodos). |  *** Setting resource limits | [`Mininet`](https://github.com/mininet/mininet/blob/master/mininet/net.py#L113) | [`init`](https://github.com/mininet/mininet/blob/master/mininet/net.py#L925) |
| Construye la topología a emular. | - | [`Mininet`](https://github.com/mininet/mininet/blob/master/mininet/net.py#L113) | [`build`](https://github.com/mininet/mininet/blob/master/mininet/net.py#L499) |
| Este método es llamado desde el anterior al detectar que existe un obj.  `Topo`. | *** Creating network | [`Mininet`](https://github.com/mininet/mininet/blob/master/mininet/net.py#L113) | [`buildFromTopo`](https://github.com/mininet/mininet/blob/master/mininet/net.py#L446) |
| Añade los host a la topología.  | *** Adding hosts | [`Mininet`](https://github.com/mininet/mininet/blob/master/mininet/net.py#L113) | [`buildFromTopo`](https://github.com/mininet/mininet/blob/master/mininet/net.py#L472) |
| Añade un host a la topología (Este método es llamado repetidamente por el número de host que haya en la topología). Posteriormente, en función de tipo de host que le habíamos pasado al obj `Mininet` inicializa dicha clase con los parámetros dados en el obj. `Topo`, o en su defecto, los toma por defecto. | - | [`Mininet`](https://github.com/mininet/mininet/blob/master/mininet/net.py#L113) | [`addHost`](https://github.com/mininet/mininet/blob/master/mininet/net.py#L206) |
| Como el tipo de host que pasamos era [`P4Host`](https://github.com/davidcawork/TFG/blob/162dfea6a4af544d8f1db64c27553dc4be1e967c/src/use_cases/p4/utils/p4_mininet.py#L30), se debe inicializar. No tiene constructor por lo que hace uso del heredado de su clase padre, [`Host`](https://github.com/mininet/mininet/blob/2b8d254cc0c99f823fdea91c442cf0365761d469/mininet/node.py#L667), que a su vez lo hereda de su clase padre [`Node`](https://github.com/mininet/mininet/blob/2b8d254cc0c99f823fdea91c442cf0365761d469/mininet/node.py#L72). | - | [`Node`](https://github.com/mininet/mininet/blob/2b8d254cc0c99f823fdea91c442cf0365761d469/mininet/node.py#L72) | [`__init__`](https://github.com/mininet/mininet/blob/2b8d254cc0c99f823fdea91c442cf0365761d469/mininet/node.py#L78) |
| Levanta un proceso de bash para el host en cuestión, el cual soportará la Network Namespace de dicho host. Hará uso del programa `mnexec`. | `mnexec -cdn env PS1=\x7f bash --norc --noediting -is mininet:hX` | [`Node`](https://github.com/mininet/mininet/blob/2b8d254cc0c99f823fdea91c442cf0365761d469/mininet/node.py#L72) | [`startShell`](https://github.com/mininet/mininet/blob/2b8d254cc0c99f823fdea91c442cf0365761d469/mininet/node.py#L132) |
| Añade los switches a la topología. | *** Adding switches | [`Mininet`](https://github.com/mininet/mininet/blob/master/mininet/net.py#L113) | [`buildFromTopo`](https://github.com/mininet/mininet/blob/master/mininet/net.py#L477) |
| Añade un switch a la topología. (Este método es llamado repetidamente por el número de switches que haya en la topología). Posteriormente, en función de tipo de switch que le habíamos pasado al obj `Mininet` inicializa dicha clase con los parámetros dados en el obj. `Topo`, o en su defecto, los toma por defecto. | - | [`Mininet`](https://github.com/mininet/mininet/blob/master/mininet/net.py#L113) | [`addSwitch`](https://github.com/mininet/mininet/blob/master/mininet/net.py#L249) |
|||||



## Fuentes 

*   [Mininet-Wifi](https://github.com/intrig-unicamp/mininet-wifi)
*   [P4 tutorials - Mininet-Wifi fork](https://github.com/ramonfontes/tutorials)
*   [BMV2](https://github.com/p4lang/behavioral-model)
*   [Medium and mobility behaviour insertion for 802.11 emulated networks -  wmediumd](https://core.ac.uk/download/pdf/41810121.pdf)
*   [Design and implementation of a wireless network tap device for IEEE 802.11 wireless network emulation](https://ieeexplore.ieee.org/abstract/document/8330098)
