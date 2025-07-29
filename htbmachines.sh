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
	echo -e "\n\t${purpleColour}m)${endColour}${greyColour} Busca por dirección IP de máquina${endColour}"
	echo -e "\n\t${purpleColour}u)${endColour}${greyColour} Actualiza el listado${endColour}"
	echo -e "\n\t${purpleColour}i)${endColour}${greyColour} Busca el nombre de una máquina por IP${endColour}"
	echo -e "\n\t${purpleColour}y)${endColour}${greyColour} Muestra el enlace al vídeo resolviendo la máquina mencionada${endColour}"
	echo -e "\n\t${purpleColour}d)${endColour}${greyColour} Muesta la lista de máquinas asociadas a una dificultad (Fácil, Media, Difícil o Insane)${endColour}"
	echo -e "\n\t${purpleColour}o)${endColour}${greyColour} Muesta la lista de máquinas asociadas a un sistema operativo (Windows, Linux)${endColour}"
	echo -e "\n\t${purpleColour}s)${endColour}${greyColour} Muesta la lista de máquinas asociadas a una habilidades necesarias sin comas (Abusing krb5.keytab file, Active Directory, etc)${endColour}"
	echo -e "\n\t${purpleColour}h)${endColour}${greyColour} Muestra el panel de ayuda${endColour}"
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


function searchMachine(){
	machineName="$1"
	if [ ! -f machine_list.txt ]
	then
		echo -e "\n${yellowColour}[+]${endColour}${greyColour}Lista no encontrada${endColour}"
		updateList
	fi
	machineData="$(cat machine_list.txt | awk "/name: \"${machineName}\"/,/resuelta:/"  | grep -vE "id:|sku:|resuelta" | tr -d '"' | tr -d ',' | sed 's/^ *//')"
	if [ "$machineData" ]
	then
		echo -e "\n${yellowColour}[+]${endColour} ${greyColour}Los datos de la maquina${endColour} ${purpleColour}${machineName}${endColour} ${rgeyColour}son:${endColour} \n\n${machineData}"
	else
		echo -e "${redColour}[!]${endColour} ${greyColour}No se ha encontrado ninguna máquina con el nombre${endColour} ${yellowColour}${machineName}${endColour}"
	fi
}

function getNameByIP(){
	IP_Address="$1"
	machineName="$(cat machine_list.txt | grep "ip: \"$IP_Address\"" -B 3 | grep "name: " | awk 'NF{print $NF}' | tr -d '"' | tr -d ',')"
	if [ "$machineName" ]
	then
		echo -e "\n${yellowColour}[+]${endColour} ${greyColour}La IP${endColour} ${blueColour}${IP_Address}${endColour} ${greyColour}pertenece a la máquina${endColour} ${purpleColour}$machineName${endColour}"
	else	
		echo -e "${redColour}[!]${endColour} ${greyColour}No se ha encontrado ninguna máquina con el la IP${endColour} ${yellowColour}${IP_Address}${endColour}"
	fi
}

function getNameByDifficulty(){
	difficulty="$1"
	machines="$(cat machine_list.txt | grep -B 5 "dificultad: \"$difficulty\"" | grep name | awk 'NF {print $NF}' | tr -d '"' | tr -d ',' | column)" 
	if [ "$machines" ]
	then
		echo -e "\n${yellowColour}[+]${endColour} ${greyColour}Lista de máquinas con dificultad${endColour} ${purpleColour}$difficulty${endColour}"
		echo -e "\n${blueColour}${machines}${endColour}"
	else	
		echo -e "${redColour}[!]${endColour} ${greyColour}No se ha encontrado ninguna máquina con el la dificultad${endColour} ${yellowColour}${difficulty}${endColour}"
	fi
}

function getNameByOperatingSystem(){
	system="$1"
	machines="$(cat machine_list.txt | grep -B 5 "so: \"$system\"" | grep name | awk 'NF {print $NF}' | tr -d '"' | tr -d ',' | column)" 
	if [ "$machines" ]
	then
		echo -e "\n${yellowColour}[+]${endColour} ${greyColour}Lista de máquinas con sistema operativo${endColour} ${purpleColour}$sytem${endColour}"
		echo -e "\n${blueColour}${machines}${endColour}"
	else	
		echo -e "${redColour}[!]${endColour} ${greyColour}No se ha encontrado ninguna máquina con el sistema operativo${endColour} ${yellowColour}${system}${endColour}"
	fi

} 

function getNameBySkill(){
	skill="$1"
	machines="$(cat machine_list.txt | grep -B 6 "skills: \"$skills\"" | grep name | awk 'NF {print $NF}' | tr -d '"' | tr -d ',' | column)" 
	if [ "$machines" ]
	then
		echo -e "\n${yellowColour}[+]${endColour} ${greyColour}Lista de máquinas con skill${endColour} ${purpleColour}$skill${endColour}"
		echo -e "\n${blueColour}${machines}${endColour}"
	else	
		echo -e "${redColour}[!]${endColour} ${greyColour}No se ha encontrado ninguna máquina con la skill${endColour} ${yellowColour}${skill}${endColour}"
	fi

} 

function getVideoLink(){
	machineName="$1"
	youtubeLink="$(cat machine_list.txt | awk "/name: \"${machineName}\"/, /resuelta:/" | grep -vE 'id:|sku:|resuelta' | tr -d '",' | grep youtube | awk 'NF { print $NF }')"
	echo $youtubeLink
	if [ "$youtubeLink" ]
	then
		echo -e "\n${yellowColour}[+]${endColour} ${greyColour}Enlace al vídeo${endColour} ${blueColour}${youtubeLink}${endColour} ${greyColour}de la máquina${endColour} ${purpleColour}$machineName${endColour}"
	else	
		echo -e "${redColour}[!]${endColour} ${greyColour}No se ha encontrado ningún vídeo de la máquina con el nombre${endColour} ${yellowColour}${machineName}${endColour}"
	fi
}

while getopts "m:huri:y:d:o:s:" arg; do
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
	   i)
		IP_Address=$OPTARG; let parameter_counter+=5
		;;
	   y)
		machineName=$OPTARG; let parameter_counter+=7
		;;
	   d)
		difficulty=$OPTARG; let parameter_counter+=11
		;;
	   o)
		system=$OPTARG; let parameter_counter+=13
		;;
	   s)
		skill=$OPTARG; let parameter_counter+=17
		;;
	   h)
		;;

	esac
done

#Table of values to control data management
if [ $parameter_counter -eq 1 ]
then
   searchMachine $machineName
elif [ $parameter_counter -eq 2 ]
then
	updateList
elif [ $parameter_counter -eq 3 ]
then
	recoverBackup
elif [ $parameter_counter -eq 5 ]
then
	getNameByIP $IP_Address
elif [ $parameter_counter -eq 7 ]
then
	getVideoLink $machineName
elif [ $parameter_counter -eq 11 ]
then
	getNameByDifficulty $difficulty
elif [ $parameter_counter -eq 13 ]
then
	getNameByOperatingSystem $system
elif [ $parameter_counter -eq 17 ]
then
	getNameBySkill $skill
else
	helpPanel
fi

#Table of values to control output msg





