# P4lang Implementation

Para la instalación del entorno de P4 se ha dejado un script de instalación bajo el directorio ``vm`` con el nombre de ``install.sh``.

## Dificultades 

Hemos tratado de instalar el entorno de p4 bajo Ubuntu 16.04 con un tipo de compilación multi nucleo, pero ha fallado en la compilación del ``bmv2`` por un error interno del compilador ``g++``. 

Se han empleado 6 cores para la compilación (``make -j6``).

