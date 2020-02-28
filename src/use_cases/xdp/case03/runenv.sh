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
	ip netns add uno

	# We've to create each interface and set into right netns
	ip link add uno type veth peer name veth0
	ip link set veth0 netns uno
	
	# Finally assign Ip's, and raise each one of them.
	ip link set uno up
	ip addr add 10.0.0.1/24 dev uno
	ip netns exec uno ip link set veth0 up
	ip netns exec uno ip addr add 10.0.0.2/24 dev veth0
}

function clean {

	printf 'Limpiando el escenario...\n' >&2
	check_prereq
	
	if $(ip netns del uno; ip link del uno;); then 
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
