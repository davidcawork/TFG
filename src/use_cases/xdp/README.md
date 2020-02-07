# XDP implementation

En este directorio se encuentra la implementación de todos los casos de uso desarrollados con XDP. Para la compilación de todos ellos se ha dotado de un Makefile que nos generará todos los ejecutables necesarios para probar cada caso de uso. De forma adicional se ha añadido una copia de la librería de libbpf, la cual es utilizada por la mayoria de programas xdp para llevar a cabo funciones externas a XDP ( Aunque la mayoria de programas XDP terminan haciendo uso de estas funciones denominadas _helpers_ , no sería de extrañar que un futuro se incorporen de forma nativa a XDP).

