#!/bin/bash

usage=$(printf "USAGE : ./captures.sh [start] [OPTIONS]\nstart : effectue des captures toutes les secondes\n[OPTIONS]\nstart -d,--debug exécute et affiche toutes les logs\nget [capturespath] [logpath] [nbcaptures] [nberreurs] affiche la variable désirée\nlog : montre le fichier log.txt\take [one] [nombre de captures] prend x captures \nclear :  supprime touts les fichiers du répertoire d'enregistrement de captures\nreconfig : recharge le fichier de configuration\n-h,--help montre cette page")
error="\e[31merreur :\e[39m"
success="\e[32msuccés :\e[39m"
phelp=": voir --help pour plus d'informations\n"
thispath=$(pwd)
path=$PATH;IFS=': ' read -r -a patha <<< $path
name=`basename "$0"`
fname=$(basename -- "$name")
extension="${fname##*.}"
fname="${fname%.*}"
debug=0
take=-1

errorh() {
	printf "$error $1 $phelp"
	exit 1
}


errore() {
    printf "$error $1\n"
    exit 1
}

toabsolute() {
	if  [[ $1 == "~/"* ]]
	then
		case $2 in
		l)  pathlog=$( echo $1|sed 's/~//' )
			pathlog="/home/$(echo $USER)$pathlog"
			;;
		d)	directory=$( echo "$1"|tr "~" "/home" )
			directory="/home/$(echo $USER)$directory";;
		*)  exit 1;;
		esac
	else
		case $2 in
		l) pathlog=$(readlink -f $1);;
		d) directory=$(readlink -f $1);;
		*) exit 1;;
		esac
	fi
}

path() {
	for i in $(seq 0 ${#patha[@]})
	do
		if [[ "${patha[$i]}" = "$thispath" ]]||[ -n "$(find "${patha[$i]}/$fname" 2> /dev/null)" ]
		then
			return 0	
		fi
	done
	cp $thispath/$name ${patha[0]}/$fname
}

asroot() {

	if getent group video | grep -q "\b$USER\b";then
    	return 0
	elif [ "$EUID" -eq 0 ]
	then
		return 0
	fi
	errore "Veuillez exécutez en root"
}

configfile() {
	if [ ! -d /etc/captures ]
	then
		mkdir /etc/captures
	else
		if [ ! -e /etc/captures/captures.config ]
		then
			touch captures.config
			printf "directory = /var/www/html/data/captures\npathlog = /var/www/html/data\nnbc=60\n">captures.config
		fi
	fi
    configfile=/etc/captures/captures.config
}

pathlog() {
    pathlog=$(cat $configfile|grep -P -o "(?<=pathlog = )\S*")
	toabsolute $pathlog l
}

pathdirectory() {
    directory=$(cat $configfile|grep -P -o "(?<=directory = )\S*")
	toabsolute $directory d
}

nbc() {
    nbc=$(cat $configfile|grep -P -o "(?<=nbc = )\S*")
}

config() {
	printf "Configuration...\n"
	[ ! -d /etc/captures ]&&mkdir /etc/captures
	[ ! e /etc/captures/captures.config ]&&touch captures.config
	printf "Dans quel répertoire voulez-vous conserver le fichier log.txt dans lequel vous trouverez les logs d'erreur des captures effectuées ? "
	read pathlog
	toabsolute $pathlog l
	[[ -d $pathlog ]]||sdir $pathlog l 1
	echo "pathlog = $pathlog" >> $configfile
	printf "Le fichier log.txt sera conservé dans $pathlog\n"
	printf "Dans quel répertoire voulez vous enregistrer les captures qui seront faites ? "
	read directory
	toabsolute $directory d
	if [ ! -d $directory ]
	then sdir $directory d 1
	fi
	echo "directory = $directory" >> $configfile
	if [ "$?" -ne "0" ]
	then rm $configfile
		exit 1
	fi
	printf "Les images seront conservées dans $directory\n"
	cp $thispath/$name ${patha[0]}/$fname
	printf "Captures peut commencé à être utilisé\n"
	printf "$usage\n"
	exit 0
}

updatedir() {
	if [ "$#" -lt "3" ]
	then
		echo "update dir in then\n"
		case $2 in 
			d)
				echo "update dir in case d\n"
				r=$(grep -i -P "(?<=directory = \S*")
				sed -E -i 's/(?<=directory = )\S*/$2/gm;t;d' <<< $r $configfile;;
			l)
				sed s/$(cat /home/esther/.local/bin/captures.config|grep -P -o "(?<=directory = )\S*")//g -i $configfile
				echo $1>>configfile
				echo "logpath = $1">>configfile
				[ -e $configfile ]&&pathlog=$(cat $configfile|grep -P -o "(?<=pathlog = )\S*")
		esac
	else
		case $2 in
		d) echo "directory = $1">>$configfile;;
		l) echo "logpath = $1">>$configfile;;
		esac
		cat $configfile
	fi
}


sdir() {
	printf "$error le répertoire $1 n'existe pas voulez-vous le créer ? O/n "
	read create
        while [ "$create" != "O" ] || [ "$create" != "o" ] || [ "$create" != "N" ] || [ "$create" != "n" ]
		do
			case $create in
				O|o)
					if [[ ! -z $1 ]]
					then
						updatedir $1 $2 $3
						if [ "$?" -ne "0"]
						then 
							echo "not update"
							exit 1
						fi
					fi
					case $2 in
						d) toabsolute $1 d&&echo "$1 = $directory\n"&&mkdir $directory;;
						l) toabsolute $1 l&&echo "$1 = $pathlog\n"&&mkdir $pathlog;;
						*) exit 1;;
					esac
						if [ "$?" -eq 0 ]
							then
								if [ "$#" -lt "3" ]
								then
									printf "$success répertoire créé et mis à jour\n"
									exit 0
								else
									printf "$success répertoire créé et mis à jour\n"
									return 0
									
								fi
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
			esac
		done
}

reconfig() {
    pathlog=$(grep -i -P -o "(?<=directory = )\S*" $configfile)
    directory=$(grep -i -P -o "(?<=directory = )\S*" $configfile)
    nbc=$(grep -i -P -o "(?<=nbc = )\S*" $configfile)
	rm /tmp/captures_reconfig
}

stop() {
    ps axf | grep captures | grep -v grep | awk '{print "kill -9 " $1}' | sh
}

take() {
	for i in $(seq 1 1 $1)
		do
		log
		cam
		dir
		fsw
		fswebcam -q --no-banner $directory/$(date '+%Y.%m.%d.%H.%M.%S').jpg 2>>$pathlog/log.txti
	done
	printf "$success les captures ont été effectuées\n"
}

cleard() {
	if [ ! -e $configfile ]
	then
		printf "$error Le fichier de configuration n'a pas été trouvé\n"
		#config
	else
		directory=$(cat $configfile|grep -P -o "(?<=directory = )\S*")
		if [ ! -d $directory  ]
		then
			errore "$directory n'existe pas\n"
		else
			rm -rf $directory/* &&printf "$success repertoire $directory vidé\n"&&exit 0
		fi
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
	if [ ! -d "$directory" ]
    then
		echo "$(date '+%Y.%m.%d.%H.%M.%S') -> le dossier $directory n'existe pas">>log.txt
        errore "Le répertoire des captures $directory n'existe pas"	
        #sdir||exit 1
    fi
}

dird() {
	if [ ! -d "$directory" ]
        then
            printf "$error $(date '+%H:%M:%S') -> le dossier $directory n'existe pas\n"
            #sdir||exit 1
        fi
}

log() {
    if [ ! -d "$pathlog" ]
    then
		echo "$(date '+%Y.%m.%d.%H.%M.%S') -> le dossier $pathlog n'existe pas">>log.txt
        errore "Le répertoire de logs $pathlog n'existe pas"	
        #sdir||exit 1
    fi
}

logd() {
    	if [ ! -d "$pathlog" ]
        then
            printf "$error $(date '+%H:%M:%S') -> le dossier $pathlog n'existe pas\n"
            #sdir||exit 1
        fi
}

fsw() {
	fswebcam 2>/dev/null
	a=$?
	if [ "$(apt list 2>/dev/null|grep -o fswebcam)" != "fswebcam" ] || [ "$a" -eq "127" ]
        then
                errore "Vous n'avez pas fswebcam"
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

displaylogs() {
	IFS=$'\n' read -r -d '' -a lines < <( awk '/{}/{ print NR }' $pathlog/log.txt && printf '\0' )
	for l in "${lines[@]}"
	do
		lines="$(echo $l)d;$(( $l-1 ))d"
		sed -i -e $lines $pathlog/log.txt
	done
	sed -i 's/{//g' $pathlog/log.txt
	sed -i 's/}//g' $pathlog/log.txt
}

starting() {
	configfile
	pathlog
	log
	nbc
	pathdirectory
	dir
}

asroot
configfile
pathlog
[ ! -f $pathlog/log.txt ]&&touch $pathlog/log.txt
path

if [ "$#" -gt "2" ]||[ "$#" -eq "0" ]
then
	printf "$usage\n"
	exit 1
elif [[ "$#" -gt "1" ]]
then
	case  $1 in
		get) configfile
			case $2 in 
             capturespath) pathdirectory
							printf "$directory\n"
             ;;
             logpath) 
			 			printf "$pathlog\n"
             ;;
             nbcaptures) nbc
			 			printf "$nbc\n"
             ;;
			 nberreurs) 
			 	printf "Il y a : $(grep -c "erreur" $pathlog/log.txt) erreurs dans le fichier $pathlog/log.txt\n"&&exit 0
			 ;;
             *) errore "Usage : get [capturespath] [logpath] [nbcaptures] : affiche le répertoires des captures ou du fichier log.txt ou le nombre de captures prise /min";;
             esac
             ;;
        take) starting
			intp='^[+]?[0-9]+$'
			float='^[+]?[-]?[0-9]+([.,][0-9]+)?$'
			intn='^[-][0-9]+([.][0-9]+)?$'
            if [[ "$2" == "one" ]]
            then
                fswebcam -q --no-banner $directory/$(date '+%Y.%m.%d.%H.%M.%S').jpg 2 >> $pathlog/log.txt && printf "$success capture prise et enregistrée\n"&&exit 0||errore "Un problème est survenu : $(fswebcam -v --no-banner $directory/$(date '+%Y.%m.%d.%H.%M.%S').jpg)"
				#echo $directory
				#fswebcam -v $directory/$(date '+%Y.%m.%d.%H.%M.%S').jpg
			elif [[ "$2" =~ $intp ]] 
			then
					take $2
			elif [[ "$2" =~ $intn ]]
			then
				errore "Le nombre de captures par minute doit être positif"
			elif [[ "$2" =~ $float ]]
			then
				errore "Le nombre de captures par minute doit être un nombre entier"
			else
				errore "Usage : captures take <nombre de captures par minutes>"
            fi;;
		log) errore "Usage : captures log : lis le fichier log.txt";;
		clear) errore "Usage : captures clear : supprime toutes les fichiers du repertoire où sont stockées les captures";;
		-d|--debug) errore "Usage : captures start -d,--debug  : affiche des informations supplémentaires";;
		start)
			if [ "$#" -gt "2" ]
			then
				errorh "Trop d'options"
			else
				case $2 in
					-d|--debug)
							starting
							debug=1
                            ;;
					*) errorh "Trop d'options";;
				esac
			fi
			starting
            ;;
        stop) errore "Usage : captures stop : arrête de prendre des captures";;
		reconfig) errore "Usage : captures reconfig : recharge le fichier de configuration";;
		-h|--help)
			printf "$usage\n"
			exit 0;;
		*) errorh "options inconnues";;
	esac
elif [[ "$#" -eq "1" ]]
then
	case $1 in 
		-d|--debug) errore "Usage : ./captures.sh start -d,--debug  : affiche des informations supplémentaires";;
		set) errore "Usage captures -s, --set <repertoire>";;
		log) configfile
			pathlog
			log
			less -f -r $pathlog/log.txt;;
		clear) starting cleard ;;
        stop) stop;;
        get) errore "Usage : get [capturespath] [logpath] [nbcaptures] [nberreurs] : affiche le répertoires des captures ou du fichier log.txt ou le nombre de captures prise /min";;
		reconfig)touch /tmp/captures_reconfig
				 exit 0;;
		start) starting;;
		status) 
			s=$(ps -aux | grep captures | grep -v grep | grep -v status)
			if [ "$s" == "" ] 
			then
				errore "processus arreté"
			fi
				printf "$success processus en marche"
				exit 0;;
		-h|--help)
			printf "$usage\n"
			exit 0;;
		*) errorh "option inconnue";;
	esac
fi

if [ "$debug" -eq "0" ]
then
    while true
    do
        #for i in $(seq 1 1 $nbc)
        #do
		[ -e /tmp/captures_reconfig ]&&reconfig
        log
        cam
        dir
        fsw
        #fswebcam -q --no-banner $directory/$(date '+%Y.%m.%d.%H.%M.%S').jpg 2>>$pathlog/log.txt
		printf "erreur datant du $(date '+%d/%m/%Y à %Hh%Mm%Ss') :\n{$(fswebcam -q --no-banner $directory/$(date '+%Y%m.%d.%H.%M.%S').jpg 2>&1)}\n">>$pathlog/log.txt
		displaylogs
        sleep $(echo $((60/$nbc)) | awk '{print int($1+0.5)}')
        #done
    done
else
    while true
    do
        #for i in $(seq 1 1 $nbc)
            #do
            #echo "------------i = $i--------------"
			[ -e /tmp/captures_reconfig ]&&reconfig
            logd&& printf "répertoire log = $pathlog\n"
            camd&& printf "/dev/video0 trouvé\n"
            dird&& printf "repertoire  $directory existe\n"
            fswd&& printf "fswebcam installé\n"
            fswebcam --no-banner -q  $directory/$(date '+%Y.%m.%d.%H.%M.%S')jpg&
            printf "$(ls -l $directory|wc -l) images dans $directory\n"
            printf "$success $(date '+%Hh%Mm%Ss') -> capture prise\n"
            sleep $(echo $((60/$nbc)) | awk '{print int($1+0.5)}')
        #done
    done
fi
