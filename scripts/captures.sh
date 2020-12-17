#!/bin/bash

usage=$(printf "USAGE : ./captures.sh [start] [OPTIONS]\nstart : effectue des captures toutes les secondes\n[OPTIONS]\n-s,--set <directory> change le repertoire d'enregistrement des captures\n-d,--debug exécute et affiche toutes les logs\n-l,--log cat le fichier log.txt\n-g,--get prend une capture\n-c,--clear supprime toutes les captures\n-h,--help display informations")
error="\e[31merror :\e[39m"
success="\e[32msuccess :\e[39m"
phelp=": see --help for more informations\n"
nbc=59
debug=2
updatedir() {
	sed '1d' log.txt > log; mv log log.txt
	sed -i "1 i\ $1" log.txt
	log
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
	printf "$error le répertoire spécifié n'existe pas voulez-vous le créer ? O/n "
	read create
        while [ "$create" != "O" ] || [ "$create" != "o" ] || [ "$create" != "N" ] || [ "$create" != "n" ]
	do
		case $create in
			O|o)
				if [[ ! -z $1 ]]
				then
					updatedir $1||echo "not update"
				fi
                        	mkdir $directory
                        	if [ "$?" -eq 0 ]
                        	then
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
	rm -r $directory/* &&printf "$success directory $directory cleared\n"&&exit 0
}


log() {
	if [ ! -f log.txt ]
        then
		printf  "$error Veuillez définir un répertoire où enregistrer les captures : " 
		read directory
                echo $directory>log.txt
        else
		directory=$(head -n 1 log.txt)
        fi
}


logd() {
	if [ ! -f log.txt ] || [[ ! -s log.txt ]]
        then
               printf "$error répertoire non défini le définir : " 
	       read directory
               echo $directory>log.txt
        else
               	directory=$(head -n 1 log.txt)
		echo "log else directory = $directory"
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
        	sdir||exit 1
        fi
}


dird() {
	if [ ! -d $directory ]
        then
                printf "$error $dated -> le dossier $directory n'existe pas\n"
                sdir||exit 1
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
	elif [ "$a" -eq "127" ]
	then
		printf "$error commmand not found\n"
		exit 1
	fi
}

if [ "$#" -gt "2" ]||[ "$#" -eq "0" ]
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
					sdir $2	
					exit 0
				fi
			fi
		;;
		-g|--get) errorh "Mauvais usage de l'option -g,--get";;
		-d|--debug) errorh "Mauvais usage de l'option -d,--debug";;
		-l|--log) errorh "mauvais usage de l'option -l,--log";;
		-c|--clear) errorh "mauvais usage de l'option -c,--clear";;
		start) errorh "mauvais usage de start";;
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
		-s|--set) errorh "Mauvais usage de l'option -s, --set";;
		-l|--log) catlog;;
		-c|--clear) cleard;;
		start) debug=0;;
		-h|--help)
			printf "$usage\n"
			exit 0;;
		*)errorh "option inconnue";;
	esac
fi

if [ "$debug" -eq "0" ]||[ "$debug" -eq "2" ]
then
	for i in $(seq 1 1 $nbc)
	do
		log
		camd
		dir
		fsw
		if [ $nbc = 1 ]
		then
			fswebcam -q --no-banner $directory/$(date '+%Y.%m.%d.%H.%M.%S').jpg& 2>>log.txt&&printf "$success capture prise et enregistrée\n"||errore "une erreur est survenue essayez -d ou --debug\n"
		fi
		sleep 1
	
	done
else
	for i in $(seq 1 1$nbc)
        do
		echo "------------i = $i--------------"
		logd&& printf "directory = $directory\n"
		camd&& printf "/dev/video0 trouvé\n"
		dird&& printf "directory $directory existe\n"
		fswd&& printf "fswebcam installé\n"
                fswebcam --no-banner -q  $directory/$(date '+%H:%M:%S').jpg&
		printf "$(ls -l $directory|wc -l) images dans $directory\n"
		printf "$success $(date '+%H:%M:%S') -> capture prise\n"
                sleep 1
	done
fi
