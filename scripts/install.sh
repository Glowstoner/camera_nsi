#!/bin/bash

success="\e[32msuccés :\e[39m"
error="\e[31merreur :\e[39m"
root="Vérifiez bien que vous exécutez ce script en tant que superutilisateur"
dir=/var/www/html
apacheconf=/etc/apache2/apache2.conf
apacheconf2=/etc/apache2/sites-available/000-default.conf

errore() {
    printf "$error $1\n"
    exit 1
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
	sed -i "s/$db/$da/g" $apacheconf || ret=1i
	sed -i "s/$ob/$a/g" $apacheconf || ret=2
	sed -i "s/$rb/$ra/g" $apacheconf2 || ret=3
	return $ret
}

permissions() {
	chown -R www-data:www-data /var/www/html && return 0 || return 1
	chmod 770 /var/www/html/ && return 0 || return 1
}

main() {
	delete || errore "n'a pas réussi à supprimer les fichiers de $dir $root"
	direxists public_html || errore "n'a pas réussi à créer le dossier $dir/public_html $root"
	direxists data || errore "n'a pas réussi à créer le dossier $dir/data $root"
	copy || errore "n'a pas réussi à copier les fichiers du répertoire de install.sh $root"
	modifapache 
	case $? in
		1) errore "n'a pas réussi à modifier '<Directory /var/www/>' par '<Directory /var/www/html/>' dans le fichier $apacheconf $root";;
		2) errore "n'a pas réussi à modifier 'Options Indexes FollowSymLinks' par 'Options FollowSymLinks' dans le fichier $apacheconf $root";;
		3) errore "n'a pas réussi à modifier 'DocumentRoot /var/www/html' par 'DocumentRoot /var/www/html/public_html' dans le fichier $apacheconf $root";;
	esac
	permissions || errore "n'a pas pu modifier les droits du répertoire /var/www/html $root"
	service apache2 restart
	printf "$success les configurations nécessaires ont bien été effectuées\n"
	exit 0
}

main
