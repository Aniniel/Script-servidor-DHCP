# Script-servidor-DHCP
#! /bin/env bash
. ./libreria.sh


#El objetivo de este script es instalar y configurar un servidor dhcp Ipv4 plenamente
#operativo en un sistema operativo Debian 10. Solo se ha probado en este sistema,
#por lo que no puedo asegurar su correcto funcionamiento en otros sistemas operativos
#u otras versiones de debian. Para su correcto funcionamiento es recomendable ejecutar el script #desde la misma carpeta en la que se encuentra.


#Para empezar es necesario ser root para ejjecutar la mayoría de instrucciones de este
#script, por lo que la siguiente función se asegurará de ello.

f_soyroot

#A continuación, debemos asegurarnos que el paquete necesario "isc-dhcp-server", esta instalado,
#y si no es así instalarlo. Se le dará opción al usuario de no instalarlo si no quiere,
#pero si no quieres instalarlo se le echará del script, puesto no que no tendría sentido continuar.

paquete=isc-dhcp-server
f_comprobar_paquete $paquete

#Ahora vemos a mostrar por pantalla las interfaces que tenemos disponibles, para que el 
#usuario pueda elegir a la que quiera aplicar el servidor dhcp. Si el usuario se equivoca
#al escribir la interfaz o la interfaz no existe, te vuelve a pregutar hasta que elijas una
#que exista

echo "De las siguientes interafaces, escribe el nombre de a la que le quieras aplicar el servidor dhcp:"
echo ""
f_mostrar_interfaces
echo ""
read interfaz

while [[ $(f_comprobar_interfaz $interfaz;echo $?) != 0 ]]
	do
		echo "Esa interfaz no existe"
		echo "Compruebe la sintaxis e introduzca de nuevo la interfaz"
		read interfaz
	done

#Lo siguiente es comprobar si la interfaz elegida está levantada o bajada. Para ello usaremos 
#la siguiente función. Si está levantada no hace nada, pero si no lo está pregunta al usuario
#si desea levantarla. Si no es así, sale del script.

f_levantar_interfaz


#Con la siguiente función modificaremos el archivo /etc/default/isc-dhcp-server para añadir
#la interfaz elegida antes. Si ya está añadida no hace nada, y si no es así, la añade.

f_modificar_isc-dhcp-server


#La siguiente función modifica la configuración global del dns y la autoridad del servidor en la red. Primero muestra cual es la que está configurada
#y después pregunta al usuario si desea cambiarla. Si es así la cambia según lo que el usuario responda.
f_modificar_configuracion_global


#La siguiente función comprueba si ya hay alguna subred configurada y pregunta al usuario en caso de haberla si 
#desea usar esa configuración. Si es así, inicia el servicio. Si no es asi, llama a otra función para crear la subred
#y después inicia el servicio. Si el servicio no se inicia con éxito avisa de ello al usuario y le da recomendaciones para encontrar el error.

f_comprobar_subnet
if [[ $(echo $?) != 1 ]];then
	f_anadir_subnet
	echo "La cofiguración creada es la siguiente:"
	cat axklmldhcp.txt
	echo "¿Es correcta? (s/n)"
	read confirmacion
	while [[ $confirmacion != "s" ]]
		do
			f_anadir_subnet
			echo "La cofiguración creada es la siguiente:"
			cat axklmldhcp.txt
			echo "¿Es correcta? (s/n)"
			read confirmacion
		done;
	cat axklmldhcp.txt >> /etc/dhcp/dhcpd.conf
	rm -rf axklmldhcp.txt
fi

systemctl start isc-dhcp-server.service

if [[ $(echo $?) != 0 ]];then
	echo "Se ha producido algún error al inicar el servicio"
	echo "Revise la dirección ip de la tarjeta de red o ejecute el comando \"systemctl status isc-dhcp-server.service\" para revisar el problema y vuelva a intentarlo"
else
	echo "Servidor dhcp iniciado"
fi
