#!/bin/bash

phelp="Usage : install.sh <répertoire d'enregistrement des captures> <répertoire d'enregistrement du fichier log.txt> <nombre de captures par minutes>\ninstall.sh -i : mode interactif"
success="\e[32msuccés :\e[39m"
error="\e[31merreur :\e[39m"
root="Vérifiez bien que vous exécutez ce script en tant que superutilisateur"
dir=/var/www/html
apacheconf=/etc/apache2/apache2.conf
apacheconf2=/etc/apache2/sites-available/000-default.conf
configfile=/etc/captures/captures.config

errore() {
    printf "$error $1\n"
    exit 1
}

toabsolute() {
	if  [[ $1 == "~/"* ]]
	then
			dirabs=$( echo $1|sed 's/~//')
			dirabs="/home/$(echo $USER)$dirabs"
	else
			dirabs=$(readlink -f $1)
	fi
	echo "$dirabs"
}

direxists() {
	if [ ! -d $dir/$1 ]
	then
		mkdir $dir/$1 && return 0 || return 1 
	fi
	return 0
}

delete() {
	rm -rf $dir/* && return 0 || return 1
}

copy() {
	path=$(realpath "$0" | sed 's|\(.*\)/.*|\1|')
	path=$(sed -E 's/scripts/web/g'<<<$path)
	echo $path
	echo $dir/public_html
	cp -fr $path $dir/public_html/ && return 0 || return 1
}

modifapache() {
	local ret=0
	local db='<Directory \/var\/www\/>'
	local da='<Directory \/var\/www\/html\/>'
	local ob='Options Indexes FollowSymLinks'
	local oa='Options FollowSymLinks'
	local rb='DocumentRoot \/var/\www\/html\/'
	local ra='DocumentRoot \/var\/www\/html\/public_html\/'
	sed -i "s/$db/$da/g" $apacheconf || ret=1
	echo "1 done"
	sed -i "s/Indexes//g" $apacheconf || ret=2
	echo "2 done"
	r=$(grep -i -P -o "(?<=DocumentRoot ).*" $apacheconf2)
	echo "r = $r"
	if [[ "$r" != "/var/www/html/public_html" ]]
	then
		sed -i "s/\/var\/www\/html\//\/var\/www\/html\/public_html/g" $apacheconf2 || ret=3
		echo "3 done"
	fi
	return $ret
}

setdir() {
	if [ "$1" == "c" ]
	then
		printf "Dans quel répertoire voulez-vous enregistrer les captures qui seront faites ? "
		read d
		capturespath=$(toabsolute $d)
		[ -d $capturespath ]&&return 0||createdir $capturespath
		[ $? -eq 0 ] && return 0 || return 1
	else
		printf "Dans quel répertoire voulez-vous enregistrer le fichier log.txt le journal d'erreurs ? "
		read l
		logpath=$(toabsolute $l)
		[ -d $logpath ]&&return 0||createdir $logpath
		[ $? -eq 0 ] && return 0 || return 1
	fi
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

setnbc() {
	local intp='^[+]?[0-9]+$'
	local float='^[+]?[-]?[0-9]+([.,][0-9]+)?$'
	local intn='^[-][0-9]+([.][0-9]+)?$'
	printf "Combien de captures voulez-vous faire par minute ? "
	read nbc
	while [[ ! "$nbc" =~ $intp ]]
	do
		if [[ "$nbc" =~ $intn ]]
		then
			printf "$error le nombre de captures par minute doit être positif\n"
			printf "Combien de captures voulez-vous faire par minute ? "
			read nbc
		elif [[ "$nbc" =~ $float ]]
		then
			printf "$error Le nombre de captures par minute doit être un nombre entier\n"
			printf "Combien de captures voulez-vous faire par minute ? "
			read nbc
		else
			printf "$error un nombre positif et entier est attendu\n"
			printf "Combien de captures voulez-vous faire par minute ? "
			read nbc
		fi
	done
	return 0
}

configfile() {
	if [ ! -d /etc/captures ]
	then
		mkdir /etc/captures || return 1
		touch $configfile && return 0 || return 1
	else
		if [ ! -e $configfile ]
		then
			touch $configfile || return 1
			echo -e "directory = $capturespath\npathlog = $logpath\nnbc=$nbc" > $configfile || return 1
			return 0
		fi
	fi
	echo -e "directory = $capturespath\npathlog = $logpath\nnbc=$nbc\n" > $configfile
	return 0
}

setconfigs() {
	local intp='^[+]?[0-9]+$'
	local float='^[+]?[-]?[0-9]+([.,][0-9]+)?$'
	local intn='^[-][0-9]+([.][0-9]+)?$'
	capturespath=$(toabsolute $1)
	[ ! -d $capturespath ]&&mkdir $capturespath
	logpath=$(toabsolute $2)
	[ ! -d $logpath ]&&mkdir $logpath
	if [[ "$3" =~ $intp ]] 
	then
			nbc=$3
	elif [[ "$3" =~ $intn ]]
	then
		errore "le nombre de captures par minute doit être positif"
	elif [[ "$3" =~ $float ]]
	then
		errore "le nombre de captures par minute doit être un nombre entier"
	else
		errore "un nombre positif et entier est attendu"
	fi
}

permissions() {
	chown -R www-data:www-data $dir || return 1
	chmod 770 $dir || return 1
	chown -R www-data:www-data $capturespath || return 2
	chmod 770 $capturespath || return 2
	chown -R www-data:www-data $logpath || return 3
	chmod 770 $logpath || return 3
	chown -R www-data:www-data $configfile || return 4
	chmod 660 $configfile || return 4
}

asroot() {
	if [ "$EUID" -eq 0 ]
	then
		return 0
	fi
	return 1
}

main() {
	asroot || errore "Veuillez exécutez en root"
	delete || errore "n'a pas réussi à supprimer les fichiers de $dir"
	direxists public_html || errore "n'a pas réussi à créer le dossier $dir/public_html"
	direxists data || errore "n'a pas réussi à créer le dossier $dir/data"
	copy || errore "n'a pas réussi à copier les fichiers du répertoire de install.sh"
	modifapache
	case $? in
		1) errore "n'a pas réussi à modifier '<Directory /var/www/>' par '<Directory /var/www/html/>' dans le fichier $apacheconf";;
		2) errore "n'a pas réussi à modifier 'Options Indexes FollowSymLinks' par 'Options FollowSymLinks' dans le fichier $apacheconf";;
		3) errore "n'a pas réussi à modifier 'DocumentRoot /var/www/html' par 'DocumentRoot /var/www/html/public_html' dans le fichier $apacheconf";;
	esac
	service apache2 restart
	if [ $1 -eq 1 ]
	then
		setdir c || errore "n'a pas réussi à créer le répertoire"
		setdir l || errore "n'a pas réussi à créer le répertoire"
		setnbc
	else
		setconfigs $2 $3 $4
	fi
	configfile || errore "n'a pas réussi à configurer le fichier de configuration"
	permissions
	case $? in
	1) errore "n'a pas pu modifier les droits du répertoire $dir";;
	2) errore "n'a pas pu modifier les droits du répertoire $capturespath";;
	3) errore "n'a pas pu modifier les droits du répetoire $logpath";;
	4) errore "n'a pas pu modifier les droits du fichier de $configfile";;
	esac
	printf "$success les configurations nécessaires ont bien été effectuées\n"
	exit 0
}

if [ $# -gt 3 ]
then 
	errore "Trop d'arguments\n$phelp"
elif [ $# -eq 1 ]
then
	if [[ "$1" ==  "-i" ]]||[[ "$1" == "--interactif" ]]
	then
		main 1
	else
		errore "Pas assez d'arguments\n$phelp"
	fi
elif [ $# -lt 3 ]
then
	errore "Pas assez d'arguments\n$phelp"
else
	main 0 $1 $2 $3
fi
