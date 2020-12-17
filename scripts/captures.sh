#!/bin/bash

usage=$(printf "Usage : ./captures.sh [OPTIONS]\neffectue des captures toutes les secondes\n[OPTIONS]\n-s,--set <directory> change le repertoire d'enregistrement des captures\n-d,--debug exécute et affiche toutes les logs\n-l,--log cat le fichier log.txt\n-g,--get prend une capture")
date=$(date '+%Y.%m.%d.%H.%M.%S')
dated=$(date '+%H:%M:%S')
nbc=59
directory="/media/pi/NAS/captures/"
debug=0

if [ "$#" -gt "3" ]
then
	printf "$usage\n"
	exit 1
elif [[ "$#" -ne "1" && "$1" !=  "-s" ]]
then
	printf "$usage\n"
	exit 1
elif [ "$#" -ne "0" ]
then
	case $1 in 
		-g|--get)
			nbc=1
		;;
		-d|--debug)
			debug=1
		;;
		-l|--log)
			if [ -f log.txt ]
			then 
				cat log.txt
				exit 0
			else
				echo "Le fichier log.txt n'existe pas"
				exit 1
			fi
		;;
		-s|--set)
			if [ "$2" = "" ]
			then
				printf "$usage\n"
				exit 1
			fi
			directory="$2"
			if [ -d $directory ]
			then
				printf "Répertoire mis à jour\n"
			else
				printf "\e[31mLe répertoire spécifié n'existe pas\n"
			fi
		;;	
		*)
			printf "$usage\n"
			exit 1
		;;
	esac
fi

if [ "$debug" -eq "0" ]
then
	for i in {1..$nbc}
	do
		if [ ! -f log.txt ]
		then
			touch log.txt
		fi
	
		if [ ! -e /dev/video0 ]
		then
			echo "$date -> la caméra n'est pas branchée">>log.txt
			exit 1
		fi
	
		if [ ! -d /media/pi/NAS/captures ]
		then
			echo "$date -> le dossier /media/pi/NAS/captures n'existe pas">>log.txt
			exit 1
		fi
	
		fswebcam -q /media/pi/NAS/captures/$date.jpg&
		sleep 1
	
	done
else
	for i in {1..$nbc}
        do
                if [ ! -e /dev/video0 ]
                then
                        printf "\e[31m$dated -> la caméra n'est pas branchée\n"
                        exit 1
                fi

                if [ ! -d /media/pi/NAS/captures ]
                then
                        printf "\e[31m$dated -> le dossier /media/pi/NAS/captures n'existe pas\n"
			iebug=1
                        exit 1
                fi

                fswebcam -q /media/pi/NAS/captures/$date.jpg&
		echo "$dated -> capture prise"
                sleep 1
	done
fi
