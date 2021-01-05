#!/bin/bash

usage=$(printf "USAGE : ./captures.sh [start] [OPTIONS]\nstart : effectue des captures toutes les secondes\n[OPTIONS]\n-d,--debug exécute et affiche toutes les logs\nget [capturespath] [logpath] [nbcaptures] affiche la variable désirée\nlog : montre le fichier log.txt\take [one] [nombre de captures] prend x captures \nclear :  supprime touts les fichiers du répertoire d'enregistrement de captures\nreconfig : recharge le fichier de configuration\n-h,--help montre cette page")
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

configfile() {
    if [ ! -e /etc/captures/captures.config ]
    then
        errore "le fichier /etc/captures/captures.config n'existe pas"
    fi
    configfile="/etc/captures/captures.config"
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

run() {
    run=$(cat $configfile|grep -P -o "(?<=run = )\d")
}

reconfig() {
    pathlog=$(cat $configfile|grep -P -o "(?<=directory = )\S*")
    directory=$(cat $configfile|grep -P -o "(?<=directory = )\S*")
    nbc=$(cat $configfile|grep -P -p "(?<=nbc = )\S*")
    run=$(cat $configfile|grep -P -o "(?<=run = )\d*")
}

stop() {
    #sudo sed -i "s/$(grep -P -o '(?<=run = )\d' $configfile)/1/g" $configfile
    ps axf | grep captures | grep -v grep | awk '{print "kill -9 " $1}' | sh
}

#start() {
    #sudo sed -i "s/$(grep -P -o '(?<=run = )\d' $configfile)/0/g" $configfile
#}

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
        errore "Le réperoire $directory n'existe pas"	
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
        errore "Le réperoire $pathlog n'existe pas"	
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

path
configfile
pathlog
log
nbc
pathdirectory
dir

[ ! -f log.txt ]&&touch $pathlog/log.txt

if [ "$#" -gt "2" ]||[ "$#" -eq "0" ]
then
	printf "$usage\n"
	exit 1
elif [[ "$#" -gt "1" ]]
then
	case  $1 in
		get) case $2 in 
             capturespath) printf "$directory\n"
             ;;
             logpath) printf "$pathlog\n"
             ;;
             nbcaptures) printf "$nbc\n"
             ;;
             *) errore "Usage : get [capturespath] [logpath] [nbcaptures] : affiche le répertoires des captures ou du fichier log.txt ou le nombre de captures prise /min";;
             esac
             ;;
        take)
			intp='^[+]?[0-9]+$'
			float='^[+]?[-]?[0-9]+([.,][0-9]+)?$'
			intn='^[-][0-9]+([.][0-9]+)?$'
            if [[ "$2" == "one" ]]
            then
                fswebcam -q --no-banner $directory/$(date '+%Y.%m.%d.%H.%M.%S').jpg 2>>$pathlog/log.txt&&printf "$success capture prise et enregistrée\n"&&exit 0||errore "Un problème est survenu voyez -d ou --debug\n"
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
		-d|--debug)
			errore "Usage : captures start -d,--debug  : affiche des informations supplémentaires";;
		start) 
			if [ "$#" -gt "2" ]
			then
				errorh "trop d'options"
			else
				case $2 in
					-d|--debug)debug=1
                            #start
                            run;;
					*) errorh "Trop d'options";;
				esac
			fi
            ;;
        stop) errore "Usage : captures stop : arrête de prendre des captures";;
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
		log) less $pathlog/log.txt;;
		clear) cleard ;;
		start)
		     #start
            run;;
        stop) stop;;
        get) errore "Usage : get [capturespath] [logpath] [nbcaptures] : affiche le répertoires des captures ou du fichier log.txt ou le nombre de captures prise /min";;
		reconfig) reconfig;;
		-h|--help)
			printf "$usage\n"
			exit 0;;
		*) errorh "option inconnue";;
	esac
fi

if [ "$debug" -eq "0" ]
then
    while [[ "$run" == "0" ]]
    do
        #for i in $(seq 1 1 $nbc)
        #do
        log
        cam
        dir
        fsw
        fswebcam -q --no-banner $directory/$(date '+%Y.%m.%d.%H.%M.%S').jpg 2>>$pathlog/log.txt
        sleep $(echo $((60/$nbc)) | awk '{print int($1+0.5)}')
        if [[ "$run" == "1" ]]
        then
            break
        fi
        #done
    done
else
    while [[ "$run" == "0" ]]
    do
        #for i in $(seq 1 1 $nbc)
            #do
            #echo "------------i = $i--------------"
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