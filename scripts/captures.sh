#!/bin/bash

usage=$(printf "USAGE : ./captures.sh [OPTIONS]\neffectue des captures toutes les secondes\n[OPTIONS]\n-s,--set <directory> change le repertoire d'enregistrement des captures\n-d,--debug exécute et affiche toutes les logs\n-l,--log cat le fichier log.txt\n-g,--get prend une capture\n-c,--clear supprime toutes les captures\n-h,--help display informations")
error="\e[31merror :\e[39m"
success="\e[32msuccess :\e[39m"
phelp=": see --help for more informations\n"
date=$(date '+%Y.%m.%d.%H.%M.%S')
dated=$(date '+%H:%M:%S')
nbc=59
debug=0

updatedir() {
	directory=sed -i "1s/.*/"$(pwd)$1"/"log.txt
}


errorh() {
	printf "$error $1 $phelp\n"
	exit 1
}


errore() {
       	printf "$error $1\n"
	exit 1
}


sdir() {
	read -p "$error le répertoire spécifié n'existe pas voulez-vous le créer ? O/n " create
        while [ "$create" != "O" ] || [ "$create" != "o" ] || [ "$create" != "N" ] || [ "$create" != "n" ]
	do
		case $create in
			O|o)
                        	mkdir $create
                        	if [ "$?" -eq 0 ]
                        	then
					updatedir $2
                                	printf "$success répertoire créé et mis à jour\n"
                                	exit 0
                        	else
                                	errore "une erreur est survenue"
                        fi
                        ;;
                        N|n)
				printf "Le répertoire n'a pas été mis à jour\n"
                                ;;
                        *)
                                read -p "$error le répertoire spécifié n'existe pas voulez-vous le créer ? O/n" create
                        ;;
               	esac
      	done
}


catlog() {
	if [ -f log.txt ]
        then
		cat log.txt
                exit 0
        else
            	printf "$usage\n"
                exit 1
	fi
}


cleard() {
	directory=$(head -n 1 log.txt)
	rm $directory/* && exit 
}


log() {
	if [ ! -f log.txt ]
        then
		read -p "$error Veuillez définir un répertoire où enregistrer les captures : " directory
                echo $directory>log.txt
        else
		directory=$(head -n 1 log.txt)
        fi
}


logd() {
	if [ ! -f log.txt ]
        then
               read -p "$error répertoire non défini le définir : " directory
               echo $directory>log.txt
        else
               directory=$(head -n 1 log.txt)
        fi
}


cam() {
	if [ ! -e /dev/video0 ]
        then
		echo "$date -> la caméra n'est pas branchée">>log.txt
                exit 1
        fi
}


camd() {
	if [ ! -e /dev/video0 ]
        then
        printf "$error $dated -> /dev/video0 n'existe pas\n"
        exit 1
        fi

}


dir() {
	if [ ! -d $directory ]
        then
        	echo "$date -> le dossier $directory n'existe pas">>log.txt
        	exit 1
        fi
}


dird() {
	if [ ! -d $directory ]
        then
                printf "$error $dated -> le dossier $directory n'existe pas\n"
                exit 1
        fi
}


fsw() {
	fswebcam 2>/dev/null
	a=$?
	if [ "$(apt list 2>/dev/null|grep -o fswebcam)" != "fswebcam" ] || [ "$a" -eq "127" ]
        then
                printf "$error Vous n'avez pas fswebcam\n"
		exit 1
        fi
}


fswd() {
	fswebcam 2>/dev/null
	a=$?
        if [ "$(apt list 2>/dev/null|grep -o fswebcam)" != "fswebcam" ]
        then
                printf "$error fswebcam non trouvé dans l'apt list\n"
		exit 1
	elif [ "a" -eq "127" ]
	then
		printf "$error commmand not found\n"
		exit 1
	fi
}


if [ "$#" -gt "2" ]
then
	printf "$usage\n"
	exit 1
elif [[ "$#" -gt "1" ]]
then
	case  $1 in
		-s|--set)
			if [ "$#" -gt "2" ]
			then
				errorh "trop d'arguments"
			else
				if [ "$2" = "" ]
                        	then
                                	errorh "mauvais usage de l'option -s, --set"
                        	fi

                        	if [ -d $2 ]
                        	then
                                	updatedir $2&&printf "$success répertoire mis à jour\n"
                        	else
					sdir	
					exit 0
				fi
			fi
		;;
		-g|--get) errorh "Mauvais usage de l'option -g,--get";;
		-d|--debug) errorh "Mauvais usage de l'option -d,--debug";;
		-l|--log) errorh "mauvais usage de l'option -l,--log";;
		-c|--clear) errorh "mauvais usage de l'option -c,--clear";;
		-h|--help)
			printf "$usage\n"
			exit 0;;
		*)errorh "options inconnues";;
	esac
elif [ "$#" -eq "1" ]
then
	case $1 in 
		-g|--get) nbc=1;;
		-d|--debug) debug=1;;
		-l|--log) catlog;;
		-c|--clear) cleard;;
		-h|--help)
			printf "$usage\n"
			exit 0;;
		*)errorh "option inconnue";;
	esac
fi

if [ "$debug" -eq "0" ]
then
	for i in $(seq 1 1 $nbc)
	do
		log
		camd
		dir
		fsw
		fswebcam -q $directory/$date.jpg&
		sleep 1
	
	done
else
	for i in $(seq 1 1$nbc)
        do
		printf "------------i = $i--------------\n"
		logd&& printf "	directory = $directory\n"
		camd&& printf "	/dev/video0 trouvé\n"
		dird&& printf "	directory $directory existe\n"
		fswd&& printf "	fswebcam installé\n"
                fswebcam -q $directory/$date.jpg&
		printf "$success $dated -> capture prise\n"
                sleep 1
	done
fi
