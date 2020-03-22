# P4 - Case01: Drop

En este test probaremos que es posible descartar todos los paquetes recibidos con un programa p4. Como tal el programa p4 no es suficiente para probar esta funcionalidad ya que requiere de una plataforma que sea capaz de soportar el lenguaje p4. Nosotros haremos uso de software switch llamado [``behavioral-model``](https://github.com/p4lang/behavioral-model), [``BMV2``](https://github.com/p4lang/behavioral-model) en adelante, para testear nuestros programas p4, y de [``Mininet``](https://github.com/mininet/mininet) como escenario para recrear nuestras topologías de Red. 

Antes de continuar con el caso de uso quiero remarcar una cosa. Continuamente nos estaremos refiriendo al [``BMV2``](https://github.com/p4lang/behavioral-model) como un "switch", pero debemos entender que con el lenguaje p4 estamos definiendo el datapath que tendrá la entidad que cargue con nuestro programa p4, en este caso el  [``BMV2``](https://github.com/p4lang/behavioral-model). Por lo que la denominación de switch puede ser un errónea, ya que depende del programa p4 que porte para comportarse como un switch. 

Debido a esto, el [``BMV2``](https://github.com/p4lang/behavioral-model) puede actuar como un hub, como un switch, un router o un firewall.. Dependerá de la funcionalidad implementada en el programa p4. Aprovecharemos la interfaz implementada del [``BMV2``](https://github.com/p4lang/behavioral-model) con [``Mininet``](https://github.com/mininet/mininet) desarrollada desde la organización de [P4Lang](https://p4.org/) para conseguir integrar estos nodos en el escenario de red y así poder comprobar el funcionamiento del programa p4 desarrollado.

## Compilación

Para la compilación de nuestro programa p4 se hará uso del compilador [``p4c``](https://github.com/p4lang/p4c). Este es el compilador de referencia para el lenguaje p4, es modular y permite escoger distintos targets para llevar a cabo la compilación. ¿Targets? Si, la compilación de los programas p4 se lleva a cabo en **dos etapas**, una etapa de compilación de frontend donde se genera un archivo ``*.p4info`` el cual recoge todos los atributos necesarios del programa p4 en tiempo de ejecución ( identificadores de tablas, su estructura, actions.. ), y una etapa de backend en el cual, se hace uso del archivo generado ``*.p4info`` para generar los archivos necesarios para atacar al target en cuestión.


<p align="center">
    <img width="50%" src="../../../../img/use_cases/p4/case01/compilation_bmv2.png">
</p>

Por ejemplo el compilador de backend que ataca al [``BMV2``](https://github.com/p4lang/behavioral-model) genera un fichero ``*.json``. Este fichero será suficiente para establecer todo el datapath según lo programado en el programa p4. El target del compilador [``p4c``](https://github.com/p4lang/p4c) que utilizaremos es el [``p4c-bm2-ss``](https://github.com/p4lang/p4c/tree/master/backends/bmv2), P4 simple_switch - bmv2 , el cual soporta la arquitectura ``v1model``.

## Puesta en marcha del escenario 

Con la finalidad de poner en marcha del escenario, se ha dejado escrito un Makefile el cual  compilará nuestro programa p4, generando los ficheros ``*.p4info`` y ``*.json``. Acto seguido se lanzará un script llamado [``run_exercise.py``](https://github.com/davidcawork/TFG/blob/master/src/use_cases/p4/utils/run_exercise.py), el cual levantará toda la topología descrita en el fichero [``scenario/topology.json``](scenario/topology.json). Cada "switch" de la topología tendrá implementada toda la lógica descrita en nuestro programa p4 dentro de una instancia del [``BMV2``](https://github.com/p4lang/behavioral-model). A continuación se puede ver una imagen resumen del levantamiento de un único "switch".

<p align="center">
    <img src="../../../../img/use_cases/p4/case01/setup.png">
</p>


## Fuentes 
