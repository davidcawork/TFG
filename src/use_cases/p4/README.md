# P4lang Implementation

For the installation of the P4 environment an installation script has been left under the ``vm`` directory with the name [``install.sh``](https://github.com/davidcawork/TFG/blob/master/src/use_cases/p4/vm/install.sh). In the official repository, there is a similar installation method but focused on a Vagrant provisioning. From the p4lang team they mount a custom virtual machine which in my opinion is too _User Friendly_ which leaves you little room for a more profiled installation to a real development environment. That's why they had to develop their own script for its installation.

It has been decided to respect the directory structure they have implemented in the repository of [p4lang-tutorial](https://github.com/p4lang/tutorials) in order to give a greater ease to people who want to replicate the use cases, since probably their starting point was the same as ours, their tutorials. So in this way all the content generated will be homogenized, except the directory [exercises](https://github.com/p4lang/tutorials/tree/master/exercises), which in our case will be replaced by the directories of the different use cases.



## Difficulties 


* We tried to install the P4 environment under Ubuntu 16.04 with a multi-core compilation type, but failed to compile the ``bmv2`` due to an internal error in the ``g++`` compiler.  Six cores were used for compilation (``make -j6``).

  * Apparently to achieve a multicore compilation it required a lot of RAM memory to achieve a correct synchronization between the different threads. Therefore, the installation script has been modified so that the compilation is done only with two cores or only one.


* In addition, the dependencies of [``BMV2``](https://github.com/p4lang/behavioral-model), [``PI``](https://github.com/p4lang/PI) and [``P4C``](https://github.com/p4lang/p4c) have been updated to the last commits of August 2019 since the creation of the installation script was prior to this date.

* Additionally, we have tried to install the P4 development environment on an Ubuntu 18.04 but as expected there are dependency problems. As we don't have enough time at the moment, we leave it for a future time to see the equivalent dependencies in Ubuntu 18.04 and rewrite the installation script or modify it to do one installation or another depending on the Linux distribution and its versioning.


---


# P4lang Implementaión

Para la instalación del entorno de P4 se ha dejado un script de instalación bajo el directorio ``vm`` con el nombre de [``install.sh``](https://github.com/davidcawork/TFG/blob/master/src/use_cases/p4/vm/install.sh). En el repositorio oficial, hay un método de instalación similar pero enfocado a un aprovisionamiento de Vagrant. Desde el equipo de p4lang montan una máquina virtual custom que a mi parecer es demasiado _User Friendly_ que te deja poco margen de maniobra para hacer una instalación más perfilada a un entorno de desarrollo real. Por ello se ha tenido que desarrollar un script propio para su instalación.

Se ha decidido respetar la estructura de directorios que tienen implantada en el repositorio de [p4lang-tutorial](https://github.com/p4lang/tutorials) para así dar una mayor facilidad a las personas que quieran replicar los casos de uso, ya que probablemente su punto de partida fue el mismo que el nuestro, su tutoriales. Por lo que de esta manera todo el contenido que se genere estará homogeneizado, salvo el directorio [exercises](https://github.com/p4lang/tutorials/tree/master/exercises), que en nuestro caso será sustituido por los directorios de los distintos casos de uso.



## Dificultades 


* Hemos tratado de instalar el entorno de P4 bajo Ubuntu 16.04 con un tipo de compilación multi núcleo, pero ha fallado en la compilación del ``bmv2`` por un error interno del compilador ``g++``.  Se han empleado 6 cores para la compilación (``make -j6``).

  * Por lo visto para conseguir una compilación multicore requería de mucha memoria RAM para conseguir una correcta sincronización entre los distintos threads. Por ello se ha modificado el script de instalación para que la compilación se haga unicamente con dos cores o uno solo.


* Además, se han actualizado las dependencias de [``BMV2``](https://github.com/p4lang/behavioral-model), [``PI``](https://github.com/p4lang/PI) y [``P4C``](https://github.com/p4lang/p4c) a los últimos commits de Agosto de 2019 ya que la creación del script de instalación fue anterior a esta fecha.

* De forma adicional mencionar que también se ha intentado instalar el entorno de desarrollo P4 sobre un Ubuntu 18.04 pero como era de esperar hay problemas de dependencias. Como de momento no nos sobra tiempo, se deja para un futuro ver las dependencias equivalentes en Ubuntu 18.04 y reescribir el script de instalación o modificarlo para que haga un instalación u otra dependiendo de la distribución de Linux y de su versionado.

