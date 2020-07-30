# XDP-wireless implementation

In this directory you will find the implementation of all the use cases developed with XDP. For the compilation of all of them we have provided a Makefile that will generate all the necessary executables to test each use case. In addition, a copy of the libbpf library has been added, which is used by most xdp programs to carry out functions external to XDP (although most XDP programs end up using these functions called _helpers_, it would not be surprising if they are incorporated natively into XDP in the future).

An installation script has been left to provide all the necessary dependencies to carry out the use cases with XDP. 


---

# XDP-wireless implementation

En este directorio se encuentra la implementación de todos los casos de uso desarrollados con XDP. Para la compilación de todos ellos se ha dotado de un Makefile que nos generará todos los ejecutables necesarios para probar cada caso de uso. De forma adicional se ha añadido una copia de la librería de libbpf, la cual es utilizada por la mayoria de programas xdp para llevar a cabo funciones externas a XDP ( Aunque la mayoria de programas XDP terminan haciendo uso de estas funciones denominadas _helpers_ , no sería de extrañar que un futuro se incorporen de forma nativa a XDP).

Se ha dejado un script de instalación para suministrar todas las dependencias necesarias para llevar a cabo los casos de uso con XDP. 
