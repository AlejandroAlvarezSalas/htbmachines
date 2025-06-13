#!/bin/bash

#Colours
greenColour="\e[0;32m\033[1m"
endColour="\033[0m\e[0m"
redColour="\e[0;31m\033[1m"
blueColour="\e[0;34m\033[1m"
yellowColour="\e[0;33m\033[1m"
purpleColour="\e[0;35m\033[1m"
turquoiseColour="\e[0;36m\033[1m"
grayColour="\e[0;37m\033[1m"

#Global variables
main_url="https://htbmachines.github.io/bundle.js"
parameter_counter=0
missing_dependencies=()

function ctrl_c(){
	echo -e "\n${redColour}[!]${endColour} Exitting..."
	exit 1
}
#Ctrl+C
trap ctrl_c INT


function helpPanel(){
	echo -e "\n${yellowColour}[+]${endColour}${greyColour}Uso:${endColour}"
	echo -e "\n\t${purpleColour}m)${endColour}${greyColour} Busca por nombre de máquina${endColour}"
	echo -e "\n\t${purpleColour}u)${endColour}${greyColour} Actualiza el listado${endColour}"
	echo -e "\n\t${purpleColour}h)${endColour}${greyColour} Muestra el panel de ayuda${endColour}"
}

function searchMachine(){
	machineName="$1"
	if [ ! -f machine_list.txt ]
	then
		echo -e "\n${yellowColour}[+]${endColour}${greyColour}Lista no encontrada${endColour}"
		updateList
	fi
	cat machine_list.txt | grep $machineName | head -n 3
}

function dependenciesChecker(){
        if ! command -v sponge 1>/dev/null
        then 
                missing_dependencies[0]='sponge'
        fi
        if ! command -v js-beautify 1>/dev/null
        then
		missing_dependencies+=('beautify')
        fi

}

function versionChecker(){

	if [ -f machine_list.tmp ]
	then
		
		currentMd5=$(md5sum machine_list.txt | awk '{print $1}')
		newMd5=$(md5sum machine_list.tmp | awk '{print $1}')

		if [ "$currentMd5" == "$newMd5" ]
		then
			echo -e "No hay actualizaciones pendientes"
		else
			cp machine_list.txt machine_list.backup
			cp machine_list.tmp machine_list.txt
		fi

	fi

	rm machine_list.tmp

}
	
function recoverBackup(){
	if [ -f machine_list.backup ]
	then
		cp machine_list.backup machine_list.txt
	else
		echo -e "No se han encontrado backups accesibles"

	fi
}

function updateList(){

	dependenciesChecker

	if (( ! ${#missing_dependencies[@]} ))
	then
		curl -s -X GET $main_url > machine_list.tmp
		js-beautify ./machine_list.tmp | sponge machine_list.tmp
		echo -e "${yellowColour}[+]${endColour}${greyColour}Lista actualizada${endColour}"
	else
		echo -e "${yellowColour}[+]${endColour}${greyColour}Por favor instale las dependencias no encontradas (${#missing_dependencies[*]}) :${endColour} ${redColour} ${missing_dependencies[@]}${endColour}"
	fi

	versionChecker
	
}

while getopts "m:hur" arg; do
	case $arg in
	   m)
		machineName=$OPTARG; let parameter_counter+=1
		;;
	   u)
		let parameter_counter+=2
		;;
	   r)
		let parameter_counter+=3
		;;
	   h)
		helpPanel
		;;

	esac
done

if [ $parameter_counter -eq 1 ]
then
   searchMachine $machineName
elif [ $parameter_counter -eq 2 ]
then
	updateList
elif [ $parameter_counter -eq 3 ]
then
	recoverBackup
else
	helpPanel
fi
