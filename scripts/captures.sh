#!/bin/bash

usage=$(printf "USAGE : ./captures.sh [start] [OPTIONS]\nstart : effectue des captures toutes les secondes\n[OPTIONS]\nset <directory> :  change le repertoire d'enregistrement des captures\nstart -d,--debug exécute et affiche toutes les logs\nlog : cat le fichier log.txt\get prend une capture\nclear :  supprime touts les fichiers du répertoire d'enregistrement\n-h,--help display informations")
error="\e[31merreur :\e[39m"
success="\e[32msuccés :\e[39m"
phelp=": voir --help pour plus d'informations\n"
nbc=59
debug=2
thispath=$(pwd)
path=$PATH;IFS=': ' read -r -a patha <<< $path
name=`basename "$0"`
fname=$(basename -- "$name")
extension="${fname##*.}"
fname="${fname%.*}"
config=1
configfile=${patha[0]}/captures.config


errorh() {
	printf "$error $1 $phelp\n"
	exit 1
}


errore() {
       	printf "$error $1\n"
	exit 1
}

path() {
	for i in $(seq 0 1 ${#patha[@]})
	do 
		if [[ "${patha[$i]}" = "$thispath" ]]||[ -n "$(find "${patha[$i]}/$fname" 2> /dev/null)" ]
		then
			return 0	
		fi
	done
	config
}

toabsolute() {
	if [[ $1 == "~/"* ]]
	then
		printf "to absolute then"
		case $2 in
		l)  pathlog=$( echo $1|sed 's/~//')
			echo $pathlog
			pathlog="/home$pathlog"
			echo "#? = $?"
			echo "pathlog = $pathlog"
			echo "#1 = $1"
			echo $( echo $1|tr ~ "\home" )
			[ -e $pathlog ];;
		d)
			directory=$( echo "$1"|tr "~" "/home" )
			;;
		*) exit 1;;
		esac
	else
		case $2 in
		l) pathlog=$(readlink -f $1);;
		d) directory=$(readlink -f $1);;
		*) exit 1;;
		esac
	fi
}

config() {
	printf "1ère utilisation...\n"
	cp $thispath/$name ${patha[0]}/$fname
	touch $configfile
	printf "Dans quel répertoire voulez-vous conserver le fichier log.txt dans lequel vous trouverez les logs d'erreur des captures effectuées ? "
	read pathlog
	toabsolute $pathlog l
	echo "pathlog = $pathlog;" >> $configfile
	printf "Le fichier log.txt sera conservé dans $pathlog\n"
	printf "Dans quel répertoire voulez vous enregistrer les captures qui seront faites ? "
	read directory
	toabsolute $directory d
	if [ ! -d $directory ]
	then sdir
	fi
	echo "directory = $directory;" >> $configfile
	printf "Les images seront conservées dans $directory\n"
	printf "Captures peut commencé à être utilisé\n"
	printf "$usage\n"
	exit 0
}

pathlog(){
	echo "fonction pathlog"
	if [ ! -e $configfile ]
	then
		config
	fi
	pathlog=$(cat $configfile|grep -P -o "(?<=directory = )\S*")
}

updatedir() {
	sed '1d' $configfile > log; mv log $configfile
	sed -i "1 i\ $1" $configfile
	log
}

#updatefile() {
#	cp -f $configfile $fname&&return 0
#}

sdir() {
	printf "$error le répertoire $directory n'existe pas voulez-vous le créer ? O/n "
	read create
        while [ "$create" != "O" ] || [ "$create" != "o" ] || [ "$create" != "N" ] || [ "$create" != "n" ]
		do
			case $create in
				O|o)
					if [[ ! -z $1 ]]
					then
						updatedir $1||echo "not update"
					fi
					toabsolute $directory d
					echo "directory = $directory"
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
					exit 1
									;;
							*)
									printf  "$error le répertoire $directory n'existe pas voulez-vous le créer ? O/n"
					read create
							;;
				*) errorh "problème"
			esac
		done
}


catlog() {
	if [ -f $pathlog/log.txt ]
        then
		more log.txt
                exit 0
        else
            	errorh "Le fichier log n'existe pas il sera défini automatiquement lors de la première utilisation"
                exit 1
	fi
}


cleard() {
	if [ ! -e $configfile ]
	then
		printf "$error Le fichier de configuration n'a pas été trouvé\n"
		config
	else
		directory=$(cat $configfile|grep -P -o "(?<=directory = )\S*")
		if [ ! -d $directory  ]
		then
			errore "$directory n'existe pas\n"
		else
			rm -r $directory/* &&printf "$success repertoire $directory vidé\n"&&exit 0
		fi
	fi
}


log() {
	if [ ! -e $configfile ]
        then
			config
        else
		directory=$(cat $configfile|grep -P -o "(?<=directory = )\S*")
        fi
}


logd() {
	if [ ! -e $configfile ]
        then
               printf "Le fichier cde configuration n'a pas été trouvé\n"
			   config
        else
               	directory=$(cat $configfile|grep -P -o "(?<=directory = )\S*")
        fi
}


cam() {
	if [ ! -e /dev/video0 ]
        then
		echo "$(date '+%Y.%m.%d.%H.%M.%S') -> la caméra n'est pas branchée">>log.txt
                exit 1
        fi
}


camd() {
	if [ ! -e /dev/video0 ]
        then
        printf "$error $(date '+%H:%M:%S') -> /dev/video0 n'existe pas\n"
        exit 1
        fi

}


dir() {
	if [ ! -d $directory ]
        then
		echo "$(date '+%Y.%m.%d.%H.%M.%S') -> le dossier $directory n'existe pas">>log.txt
        	sdir||exit 1
        fi
}


dird() {
	if [ ! -d $directory ]
        then
                printf "$error $(date '+%H:%M:%S') -> le dossier $directory n'existe pas\n"
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
		set)
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
		get) errore "Usage : -./captures.sh get : prend une capture\n";;
		log) errore "Usage : ./captures.sh log : lis le fichier log.txt";;
		clear) errore "Usage : ./captures.sh clear : supprime toutes les fichiers du repertoire où sont stockées les captures\n";;
		-d|--debug)
			errore "Usage : ./captures.sh start -d,--debug  : affiche des informations supplémentaires";;
		start) 
			if [ "$#" -gt "2" ]
			then
				errorh "trops d'options"
			else
				case $2 in
					-d|--debug)debug=1;;
					*) errorh "Trop d'options";;
				esac
			 fi;;
		-h|--help)
			printf "$usage\n"
			exit 0;;
		*)errorh "options inconnues";;
	esac
elif [ "$#" -eq "1" ]
then
	case $1 in 
		get) nbc=1;;
		-d|--debug)errore "Usage : ./captures.sh start -d,--debug  : affiche des informations supplémentaires";;
		set) errore "Usage captures -s, --set <repertoire>";;
		log) catlog;;
		clear) cleard ;;
		start) debug=0;;
		-h|--help)
			printf "$usage\n"
			exit 0;;
		*)errorh "option inconnue";;
	esac
fi

path
pathlog


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
			fswebcam -q --no-banner $directory/$(date '+%Y.%m.%d.%H.%M.%S').jpg 2>>$pathlog/log.txt&&printf "$success capture prise et enregistrée\n"||errore "Un problème est survenu voyez -d ou --debug\n"
		fi
		fswebcam -q --no-banner $directory/$(date '+%Y.%m.%d.%H.%M.%S').jpg& 2>>$pathlog/log.txt
		sleep 1
	
	done
else
	for i in $(seq 1 1$nbc)
        do
		echo "------------i = $i--------------"
		logd&& printf "répertoire = $directory\n"
		camd&& printf "/dev/video0 trouvé\n"
		dird&& printf "repertoire  $directory existe\n"
		fswd&& printf "fswebcam installé\n"
                fswebcam --no-banner -q  $directory/$(date '+%H:%M:%S').jpg&
		printf "$(ls -l $directory|wc -l) images dans $directory\n"
		printf "$success $(date '+%H:%M:%S') -> capture prise\n"
                sleep 1
	done
fi
