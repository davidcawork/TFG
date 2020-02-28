#!/bin/bash


NEEDED_TOOLS="ip"

error(){
	echo -e "\e[31m$1\e[0m"
}

ok(){
	echo -e "\e[92m$1"
}

function check_prereq()
{

    for tool in $NEEDED_TOOLS; do
        which "$tool" > /dev/null || error "No se encuentra la herramienta: $tool"
    done

    if [ "$EUID" -ne "0" ]; then
        error "Este script necesita permisos de root para levantar el escenario."
    fi


}

function install {
	printf 'Levantando escenario...\n' >&2
		
	check_prereq
	
	# Let's create netns
	sudo ip netns add uno
	sudo ip netns add dos
	sudo ip netns add switch

	# We've to create each interface and set into right netns
	sudo ip link add uno type veth peer name veth0
	sudo ip link set veth0 netns uno
	sudo ip link set uno netns switch
	sudo ip link add dos type veth peer name veth0
	sudo ip link set veth0 netns dos
	sudo ip link set dos netns switch
	sudo ip link add switch type veth peer name gateway
	sudo ip link set switch netns switch

	# Finally assign Ip's, and raise each one of them.
	sudo ip link set gateway up
	sudo ip addr add 10.0.0.1/24 dev gateway
	sudo ip netns exec switch ip link set switch up
	sudo ip netns exec switch ip link set uno up
	sudo ip netns exec switch ip link set dos up
	sudo ip netns exec uno ip link set veth0 up
	sudo ip netns exec uno ip addr add 10.0.0.2/24 dev veth0
	sudo ip netns exec dos ip link set veth0 up
	sudo ip netns exec dos ip addr add 10.0.0.3/24 dev veth0
}

function clean {

	printf 'Limpiando el escenario...\n' >&2
	check_prereq
	
	if $(ip netns del uno; ip netns del dos; ip netns del switch; ip link del uno; ip link del dos; ip link del gateway); then 
		ok "Completado :)" 
	fi
}

function usage {
    printf '\nUso: %s [-ich?]\n\n' $(basename $0) >&2
    printf 'Para testear el correcto funcionamiento de los programas desarrollados\n' >&2
    printf 'se ha hecho uso de las netns, por lo que podría ser un barrera de entrada\n' >&2
    printf 'para aquellas personas que nunca han trabajado con ellas y quisieran replicar los test.\n' >&2
    printf '\n\nPor ello, se decidió escribir este script, para que la puesta en marcha de\n' >&2
    printf 'escenario y su limpieza, no sean un impedimento para corroborar el funcionamiento\n' >&2
    printf 'de los casos de uso.\n\n' >&2

    printf 'Cualquier consulta sobre como llevar a cabo los test, o duda generica,\n' >&2
    printf 'pueden ponerse en contacto conmigo <david.carrascal@edu.uah.es>\n\n\n' >&2

    printf 'Opciones:\n\n' >&2
    printf -- ' -i: (I)nstall scenario\n' >&2
    printf -- ' -c: (C)lean scenario\n' >&2
    printf -- ' -h: (H)elp\n' >&2

    printf '\n\n' >&2
}

if [ $# -eq 0 ]
then
    usage
else
    while getopts 'ich?' OPTION
    do
      case $OPTION in
	c)    clean;;
	i)    install;;
      	h)    usage;;
      	?)    usage;;
      esac
    done
    shift $(($OPTIND - 1))
fi
