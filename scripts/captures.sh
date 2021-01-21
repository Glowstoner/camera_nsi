#!/bin/bash

usage=$(printf "USAGE : ./captures.sh [start] [OPTIONS]\nstart : effectue des captures toutes les secondes\n[OPTIONS]\nstart -d,--debug exécute et affiche toutes les logs\nget [capturespath] [logpath] [nbcaptures] [nberreurs] affiche la variable désirée\nset [capturespath] [logpath] [nbcaptures] : modifie le paramètre spécifié\nlog : montre le fichier log.txt\take [one] [nombre de captures] prend x captures \nclear :  supprime touts les fichiers du répertoire d'enregistrement de captures\nreconfig : recharge le fichier de configuration\n-h,--help montre cette page")
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
	if  [[ $1 == "~/"* ]]||[[ $1 == "~" ]]
	then
			dirabs=$( echo $1|sed 's/~//')
			dirabs="/home/$(echo $USER)$dirabs"
	else
			dirabs=$(readlink -f $1)
	fi
	echo "$dirabs"
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
		touch /etc/captures/captures.config
	else
		if [ ! -e /etc/captures/captures.config ]
		then
			touch /etc/captures/captures.config
			printf "directory = /var/www/html/data/captures\npathlog = /var/www/html/data\nnbc = 60\nrefd = /\npdisk = 95\n">/etc/captures/captures.config
		fi
	fi
    configfile=/etc/captures/captures.config
}

pathlog() {
    pathlog=$(cat $configfile|grep -P -o "(?<=pathlog = )\S*")
	pathlog=$(toabsolute $pathlog)
}

pathdirectory() {
    directory=$(cat $configfile|grep -P -o "(?<=directory = )\S*")
	directory=$(toabsolute $directory)
}

nbc() {
    nbc=$(cat $configfile|grep -P -o "(?<=nbc = )\d*")
}

pdisk() {
	pdisk=$(cat $configfile|grep -P -o "(?<=pdisk = )\d*")
}

refd() {
	refd=$(cat $configfile|grep -P -o "(?<=refd = )\S*")
}

config() {
	printf "Configuration...\n"
	starting
	setdir l
	if [ $? -eq 0 ]
	then 
		printf "$success lLe fichier log.txt sera conservé dans $pathlog\n"
	else
		printf "$errore une erreur est survenue la valeur par défaut sera conservée\n"
	fi
	setdir c
	if [ $? -eq 0 ]
	then
		printf "$success les captures seront enregistrées dans le répertoire $directory\n"
	else
		printf "$errore une erreur est survenue la valeur par défaut sera conservée\n"
	fi
	setnumbers nbc
	if [ $? -eq 0 ]
	then
		printf "$succes $nbc captures seront effectuées par minute\n"
	else
		printf "$errore une erreur est survenue la valeur par défaut sera conservée\n"
	fi
	refd
	if [ $? -eq 0 ]
	then
		printf "$succes le calcul du pourcentage de l'espace utilisable utilisé par le répertoire contenant les captures sera $refd\n"
	else
		printf "$errore une erreur est survenue la valeur par défaut sera conservée\n"
	fi
	setnumbers pdisk
	if [ $? -eq 0 ]
	then
		printf "$succes le contenu du dossier contenant les captures sera effacé s'il occupe $pdisk% de $refd\n"
	else
		printf "$errore une erreur est survenue la valeur par défaut sera conservée\n"
	fi
	configuration || return 1
	permissions || return 1
	printf "capture a bien été configuré\n"
	printf "$usage\n"
	return 0
}

setdir() {
	if [ "$1" == "c" ]
	then
		printf "Dans quel répertoire voulez-vous enregistrer les captures qui seront faites ? "
		read d
		while [[ "$d" == "" ]]
		do 
			printf "$error Le répertoire ne peut pas être vide\nDans quel répertoire voulez-vous enregistrer les captures qui seront faites ? "
			read d
		done
		directory=$(toabsolute $d)
		[ -d $directory ]&&return 0||createdir $directory
		[ $? -eq 0 ] && return 0 || return 1
	else
		printf "Dans quel répertoire voulez-vous enregistrer le fichier log.txt le journal d'erreurs ? "
		read l
		while [[ "$l" == "" ]]
		do 
			printf "$error Le répertoire ne peut pas être vide\nDans quel répertoire voulez-vous enregistrer les captures qui seront faites ? "
			read l
		done
		pathlog=$(toabsolute $l)
		[ -d $pathlog ]&&return 0||createdir $pathlog
		[ $? -eq 0 ] && return 0 || return 1
	fi
}

setrefd() {
	printf "Veuillez entrer un répertoire : "
		read r
		while [[ "$r" == "" ]]
		do 
			printf "$error Le répertoire ne peut pas être vide\nveuillez entrer un répertoire : "
			read r
		done
		refd=$(toabsolute $r)
		[ $? -eq 0 ] && return 0 || return 1
}

createdir() {
	printf "Le répertoire spécifié n'existe pas, voulez-vous le créer ? [O/n] "
	read create
        while [ "$create" != "O" ] || [ "$create" != "o" ] || [ "$create" != "N" ] || [ "$create" != "n" ]
		do
			case $create in
				O|o) mkdir $1
					if [ $? -eq 0 ]
					then
						printf "$success le répertoire $1 a été créé\n"
						return 0
					else
						return 1
					fi
					;;
				N|n)
					printf "Le répertoire $1 ne sera pas créé\n"
					return 1
					;;
				*)
					printf  "$error le répertoire $1 n'existe pas voulez-vous le créer ? [O/n] "
					read create
					;;
			esac
		done
}

setnumbers() {
	local intp='^[+]?[0-9]+$'
	local float='^[+]?[-]?[0-9]+([.,][0-9]+)?$'
	local intn='^[-][0-9]+([.][0-9]+)?$'
	if [[ "$1" == "nbc" ]]
	then
		printq="Combien de captures voulez-vous faire par minute ? "
	else
		printq="À partir de quel pourcentage d'occupation de l'espace libre de $refd par le répertoire $directory le contenu de ce répertoire doit être supprimé ? "
	fi
	printf "$printq"
	read n
	while [[ ! "$n" =~ $intp ]]
	do
		if [[ "$n" =~ $intn ]]
		then
			printf "$error le nombre doit être positif\n"
			printf "$printq"
			read n
		elif [[ "$n" =~ $float ]]
		then
			printf "$error le nombre doit être un nombre entier\n"
			printf "$printq"
			read n
		else
			printf "$error un nombre positif et entier est attendu\n"
			printf "$printq"
			read n
		fi
	done
	if [[ "$1" == "nbc" ]]
	then
		nbc=$n
	else
		pdisk=$n
	fi
	return 0
}

configuration() {
	rm -f $configfile
	echo -e "directory = $directory\npathlog = $pathlog\nnbc = $nbc\nrefd = $refd\npdisk = $pdisk\n" > $configfile || return 1
	return 0
}

permissions() {
	case $1 in
	c) chown -R www-data:www-data $directory || return 1
	   chmod 770 $directory || return 1 
	   ;;
	l) chown -R www-data:www-data $pathlog || return 1
	   chmod 770 $pathlog || return 1
	   ;;
	conf) chown -R www-data:www-data $configfile || return 1
		  chmod 660 $configfile || return 1
		;;
	esac
	return 0
}

reconfig() {
    pathlog=$(grep -i -P -o "(?<=pathlog = )\S*" $configfile)
    directory=$(grep -i -P -o "(?<=directory = )\S*" $configfile)
    nbc=$(grep -i -P -o "(?<=nbc = )\S*" $configfile)
	pdisk=$(cat $configfile|grep -P -o "(?<=pdisk = )\d*")
	refd=$(cat $configfile|grep -P -o "(?<=refd = )\S*")	
	rm /tmp/captures_reconfig
}

stop() {
    ps axf | grep captures | grep -v grep | awk '{print "kill -9 " $1}' | sh
}

sizeof() {
	local s=$(du -m $1)
	echo $s | grep -P -o '(\d*(?=\s*total))'
}

checksize() {
	local sd=$(sizeof $directory)
	local dl=$(diskspaceleft)
	local p=$(echo $(echo "$(echo "$sd/$dl"|bc -l)*100"|bc -l) | awk '{print int($1)}')
	if [[ "$p" == "$pdisk" ]]||[[ "$p" > "$pdisk" ]]
	then
		cleard || return 1
	fi
	return 0
}

diskspaceleft() {
	s=$(df -h $refd)
	echo $s | grep -P -o '\d*(?=M\s*\d*%)'
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
    fi
}

logd() {
    	if [ ! -d "$pathlog" ]
        then
            printf "$error $(date '+%H:%M:%S') -> le dossier $pathlog n'existe pas\n"
            setdir l ||exit 1
			permissions l
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
	#configfile
	#pathlog
	log
	nbc
	pathdirectory
	dir
	pdisk
	refd
}

asroot
configfile
path
if [[ "$1" != "set" ]]
then
	pathlog
	log
	[ ! -f $pathlog/log.txt ]&&touch $pathlog/log.txt
fi

if [ "$#" -gt "2" ]||[ "$#" -eq "0" ]
then
	printf "$usage\n"
	exit 1
elif [[ "$#" -gt "1" ]]
then
	case  $1 in
		get)
			case $2 in 
             capturespath) pathdirectory
							printf "$directory\n"&&exit 0
             ;;
             logpath) 
			 		printf "$pathlog\n"&&exit 0
             ;;
             nbcaptures) nbc
			 			printf "$nbc\n"&&exit 0
             ;;
			 nberreurs)
			 	printf "Il y a : $(grep -c "erreur" $pathlog/log.txt) erreurs dans le fichier $pathlog/log.txt\n"&&exit 0
			 ;;
			 foldersize)
			 	pathdirectory 
			 	printf "La taille du dossier d'enregistrement des captures est $(sizeof $directory) Mo\n"&&exit 0
			 ;;
			 percentdisk)
				pdisk
				pathdirectory
				printf "Le pourcentage d'occupation maximale possible du dossier $directory sur l'espace utilisable du dossier refd défini est de $pdisk\n"&&exit 0
			;;
			refd)
				refd
				printf "Le répertoire utilisé pour la comparaison de l'espace utilisable utilisé dessus par le dossier d'enregistrement des captures est $refd\n"&&exit 0
			;;
             *) errore "Usage : get [capturespath] [logpath] [nbcaptures] [nberreurs] [percentdisk] [refd] : affiche le répertoires des captures ou du fichier log.txt ou le nombre de captures prises par min ou le nombre d'erreurs dans le fichier log.txt ou le peramètre spécifié";;
             esac
			 ;;
		set) #starting
			 case $2 in			 
			 capturespath) refd
			 			   pathlog
			 			   nbc
						   pdisk
			 			   setdir c || errore "n'a pas réussi à mettre à jour le répertoire"
			 			   permissions c || errore "n'a pas réussi à changer les permissions de ce répertoire";;
			 logpath) pathdirectory
			 		  nbc
					  pdisk
					  refd
			 		  setdir l || errore "n'a pas réussi à mettre à jour le répertoire"
			 		  permissions l || errore "n'a pas réussi à changer les permissions de ce répertoire";;
			 nbcaptures) pathlog
			 			 pathdirectory
						 pdisk
						 refd
			 			setnumbers nbc || errore "n'a pas réussi à mettre à jour le nombre de captures";;
			percentdisk) pathlog
						 nbc
						 pathdirectory
						 refd
						 setnumbers p || errore "n'a pas réussi à mettre à jour le pourcentage";;
			refd) pathlog
				  nbc
				  pdisk
				  pathdirectory
				  setrefd 
				  ;;
			 *) errore "Usage : captures set [capturespath] [logpath] [nbcaptures] [percentdisk] [refd] : modifie le paramètre spécifié";;
			 esac
			 configuration || errore "n'a pas réussi à configurer le fichier de configuration"
			 permissions conf || errore "n'a pas réussi à modifier les droits du fichier de configuration mis à jour"
			 printf "$success les modifications ont bien été enregistrées\n"
			 exit 0
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
		set) errore "Usage : captures set [capturespath] [logpath] [nbcaptures] : modifie le paramètre spécifié";;
		log) configfile
			pathlog
			log
			less -f -r $pathlog/log.txt;;
		clear) starting cleard ;;
        stop) stop;;
        get) errore "Usage : get [capturespath] [logpath] [nbcaptures] [nberreurs] [percentdisk] [refd] : affiche le répertoires des captures ou du fichier log.txt ou le nombre de captures prises par min ou le nombre d'erreurs dans le fichier log.txt ou le peramètre spécifié";;
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
		[ -e /tmp/captures_reconfig ]&&reconfig
		checksize
        log
        cam
        dir
        fswd
		printf "erreur datant du $(date '+%d/%m/%Y à %Hh%Mm%Ss') :\n{$(fswebcam -q --no-banner $directory/$(date '+%Y.%m.%d.%H.%M.%S').jpg 2>&1)}\n">>$pathlog/log.txt
		displaylogs
        sleep $(echo $((60/$nbc)) | awk '{print int($1+0.5)}')
    done
else
    while true
    do
			[ -e /tmp/captures_reconfig ]&&reconfig
			checksize&& printf "la taille "
            logd&& printf "répertoire log = $pathlog\n"
            camd&& printf "/dev/video0 trouvé\n"
            dird&& printf "repertoire  $directory existe\n"
            fswd&& printf "fswebcam installé\n"
            fswebcam --no-banner -q  $directory/$(date '+%Y.%m.%d.%H.%M.%S')jpg&
            printf "$(ls -l $directory|wc -l) images dans $directory\n"
            printf "$success $(date '+%Hh%Mm%Ss') -> capture prise\n"
			echo "nbc = $nbc"
            sleep $(echo $(( 60/$nbc )) | awk '{print int($1+0.5)}')
    done
fi
