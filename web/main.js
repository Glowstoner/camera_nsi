$(document).ready(function () {
    console.log("Page chargée.");

    var asec = "#mainsecctl";
    var token = getToken();
    
    checkToken(token);

    $('#mainclickcontrol').click(function () {
        if(asec != "#mainsecctl") {
            console.log("change click control act=" + asec);
            $(asec).hide();
            $('#mainsecctl').show();
            asec = "#mainsecctl";
            updateTitle("État du programme");
            updateControlStatus(token);
        }
    });

    $('#mainclickcaptures').click(function () {
        if(asec != "#mainseccaptures") {
            console.log("change click captures act=" + asec);
            $(asec).hide();
            $('#mainseccaptures').show();
            asec = "#mainseccaptures";
            updateTitle("Captures");
            backgroundProcess(token);
        }
    });

    $('#mainclicksettings').click(function () {
        if(asec != "#mainsecsettings") {
            console.log("change click settings act=" + asec);
            $(asec).hide();
            $('#mainsecsettings').show();
            asec = "#mainsecsettings";
            updateTitle("Paramètres");
            backgroundProcess(token);
        }
    });

    $('#mainsearchbutton').click(function () {
        var date = new Date($('#mainsearchdate').val());
        var fdate = date.getDate() + "/" + (date.getMonth() + 1)+ "/" + date.getFullYear();
        console.log("date:" + fdate);
        var hours = Number($('#mainhourselect').val());
        var minutes = Number($('#mainminuteselect').val());
        console.log("hours: " + hours + ", minutes: " + minutes);

        if(isNaN(date)) {
            showSearchError("Veuillez spécifier une date !");
        }else if(isNaN(hours) || !Number.isInteger(hours)) {
            showSearchError("Veuillez spécifier une heure valide !");
        }else if(isNaN(minutes) || !Number.isInteger(minutes)) {
            showSearchError("Veuillez spécifier une minute valide !");
        }else {
            if(hours >= 24) {
                showSearchError("Veuillez spécifier une heure inférieure à 24 !");
            }else if(minutes >= 60) {
                showSearchError("Veuillez spécifier une minute inférieure à 60 !");
            }else {
                if($('#mainhourselect').val().trim() === "") hours = -1;
                if($('#mainminuteselect').val().trim() === "") minutes = -1;
                console.log("Valide. recherche ...");
                $('#maincaptureserror').hide();
                var data = {message: 'Recherche en cours ...', timeout: 1000};
                document.querySelector("#maincapturesloading").MaterialSnackbar.showSnackbar(data);
                var jdate = {
                    year: date.getFullYear(),
                    month: (date.getMonth() + 1),
                    day: date.getDate(),
                    hour: hours,
                    minute: minutes
                };

                let jdateenc = JSON.stringify(jdate);
                console.log("JSON envoyé : " + jdateenc);
                controlCaptures(jdateenc, token);
            }
        }
    });

    $('#mainsettingsbutton').click(function () {
        updateSettings(token);
    });

    $('#mainctlstart').click(function () {
        controlService(true, token);
    });

    $('#mainctlstop').click(function () {
        controlService(false, token);
    });

    updateControlStatus(token);
});

function backgroundProcess(token) {
    setControlServiceLoadingScreen();
    updateLocalServerSettings(token);
}

function updateSettings(sessiontoken) {
    let capturesPath = document.getElementById("mainsettingspath");
    let logPath = document.getElementById("mainsettingspathlog");
    let nbCapt = document.getElementById("mainsettingsnumber");
    
    if(capturesPath.value === "" || !capturesPath.checkValidity()) {
        showSettingsError("Le dossier spécifié pour les captures est invalide !");
    }else if(logPath.value === "" || !logPath.checkValidity()) {
        showSettingsError("Le dossier spécifié pour contenir le journal d'erreur est invalide !");
    }else if(nbCapt.value === "" || !nbCapt.checkValidity()) {
        showSettingsError("Le nombre de captures spécifié est invalide, la valeur doit être un nombre supérieur à 0 !");
    }else {
        var data = {message: 'Chargement ...', timeout: 1000};
        document.querySelector("#mainsettingsbuttonloading").MaterialSnackbar.showSnackbar(data);
        var jdata = {
            action: "set",
            configuration: {
                directory: capturesPath.value,
                pathlog: logPath.value,
                nbc: nbCapt.value
            }
        };

        let jdataenc = JSON.stringify(jdata);
        console.log("JSON envoyé : " + jdataenc);
        $.post("api.php", {settings: jdataenc, token: sessiontoken}, function(data, status) {
            console.log(status);
            if(status == "success") {
                console.log(data);
                var ret = JSON.parse(data);
                console.log(ret);
                if(ret.valid && ret.success) {
                    if(ret.operationSuccess) {
                        console.log("Requête réalisée avec succès.");
                        $('#mainsettingserror').hide();
                        var data = {message: 'Paramètres modifiés', timeout: 1000};
                        document.querySelector("#mainsettingsbuttonloading").MaterialSnackbar.showSnackbar(data);
                    }else {
                        console.log("Problème technique !");
                        ooops();
                    }
                }else {
                    reconnect();
                }
            }
        });
    }
}

function updateLocalServerSettings(sessiontoken) {
    var jdata = {
        action: "get"
    };

    let jdataenc = JSON.stringify(jdata);
    console.log("JSON envoyé : " + jdataenc);
    $.post("api.php", {settings: jdataenc, token: sessiontoken}, function(data, status) {
        console.log(status);
        if(status == "success") {
            console.log(data);
            var ret = JSON.parse(data);
            console.log(ret);
            if(ret.valid && ret.success) {
                if(ret.operationSuccess) {
                    console.log("Requête réalisée avec succès.");
                    
                    document.getElementById("mainsettingspath").value = ret.configuration.directory;
                    document.getElementById("mainsettingspathlog").value = ret.configuration.pathlog;
                    document.getElementById("mainsettingsnumber").value = ret.configuration.nbc;
                    document.getElementById("mainsettingspathhandler").className = "mdl-textfield mdl-js-textfield mainsettingstextarea is-dirty";
                    document.getElementById("mainsettingspathloghandler").className = "mdl-textfield mdl-js-textfield mainsettingstextarea is-dirty";
                    document.getElementById("mainsettingsnumberhandler").className = "mdl-textfield mdl-js-textfield mainsettingstextarea is-dirty";
                }else {
                    console.log("Problème technique !");
                    ooops();
                }
            }else {
                reconnect();
            }
        }
    });
}

function updateTitle(newtitle) {
    $('#maintitle').text(newtitle);
}

function controlService(start, sessiontoken) {
    isControlServiceRuning(sessiontoken, function(success) {
        if(success) {
            if(start) {
                var data = {message: "Le service est déjà en cours d'éxécution !", timeout: 2000};
                document.querySelector("#mainctlloading").MaterialSnackbar.showSnackbar(data);
                return;
            }
        }else {
            if(!start) {
                var data = {message: "Le service n'est pas en cours d'éxécution !", timeout: 2000};
                document.querySelector("#mainctlloading").MaterialSnackbar.showSnackbar(data);
                return;
            }
        }

        var text = (start) ? "Lancement du service ..." : "Arrêt du service ...";
        var data = {message: text, timeout: 2000};
        document.querySelector("#mainctlloading").MaterialSnackbar.showSnackbar(data);
        $.post("api.php", {servicectl: (start) ? "start" : "stop", token: sessiontoken}, function(data, status) {
            console.log(status);
            if(status == "success") {
                console.log(data);
                var ret = JSON.parse(data);
                console.log(ret);
                if(ret.valid && ret.success) {
                    if(ret.operationSuccess) {
                        console.log("Requête réalisée avec succès.");
                        isControlServiceRuning(sessiontoken, function(running) {
                            if(running) {
                                $('#maingloballogo').text("check");
                                $('#maingloballogo').css("color", "green");
                                $('#mainctlinfo').text("En fonctionnement");
                            }else {
                                $('#maingloballogo').text("clear");
                                $('#maingloballogo').css("color", "red");
                                $('#mainctlinfo').text("À l'arrêt");
                            }
                        });
                    }else {
                        console.log("Problème technique !");
                        ooops();
                    }
                }else {
                    reconnect();
                }
            }
        });
    });
}

function setControlServiceLoadingScreen() {
    $('#maingloballogo').text("cached");
    $('#maingloballogo').css("color", "rgb(49, 49, 49)");
    $('#mainctlinfo').text("Chargement ...");
}

function isControlServiceRuning(sessiontoken, success) {
    $.post("api.php", {servicectl: "status", token: sessiontoken}, function(data, status) {
        console.log(status);
        if(status == "success") {
            console.log(data);
            var ret = JSON.parse(data);
            console.log(ret);
            if(ret.valid && ret.success) {
                if(ret.operationSuccess) {
                    console.log("Requête réalisée avec succès.");
                    if(ret.status == 0) {
                        success(true);
                    }else if(ret.status == 1) {
                        success(false);
                    }else {
                        console.log("Problème technique ! (erreur de status)");
                        ooops();
                    }
                }else {
                    console.log("Problème technique !");
                    ooops();
                }
            }else {
                reconnect();
            }
        }
    });
}

function controlCaptures(date, sessiontoken) {
    $.post("api.php", {captures: date, token: sessiontoken}, function(data, status) {
        console.log(status);
        if(status == "success") {
            console.log(data);
            var ret = JSON.parse(data);
            if(ret.valid && ret.success) {
                if(ret.operationSuccess) {
                    console.log("Requête réalisée avec succès.");
                    let afiles = ret.files;
                    $('#maincaptures').empty();
                    if(afiles.length == 0) {
                        console.log("Aucun résultat trouvé.");
                        var data = {message: 'Aucun résultat trouvé', timeout: 2000};
                        document.querySelector("#maincapturesloading").MaterialSnackbar.showSnackbar(data);
                        displayNotFound();
                    }else {
                        var text = (afiles.length == 1) ? "1 résultat trouvé" : afiles.length + " résultats trouvés";
                        var data = {message: text, timeout: 2000};
                        document.querySelector("#maincapturesloading").MaterialSnackbar.showSnackbar(data);
                        afiles.forEach(element => {
                            console.log("Fichier reçu : " + element);
                        });
                        displayTiles(afiles);
                    }
                }else {
                    console.log("Problème technique !");
                    ooops();
                }
            }else {
                reconnect();
            }
        }
    });
}

function updateControlStatus(token) {
    isControlServiceRuning(token, function(success) {
        if(success) {
            $('#maingloballogo').text("check");
            $('#maingloballogo').css("color", "green");
            $('#mainctlinfo').text("En fonctionnement");
        }else {
            $('#maingloballogo').text("clear");
            $('#maingloballogo').css("color", "red");
            $('#mainctlinfo').text("À l'arrêt");
        }
    });
}

function displayTiles(files) {
    files.forEach(element => {
        let filename = element.replace(/^.*[\\\/]/, '');
        console.log("Affichage de " + filename + " ...");
        $('#maincaptures').append('<a href=\"' + element + '\">\
        <div class=\"capture-image mdl-card mdl-shadow--2dp\" style="background: url(\'' + element + '\') center / cover;\">\
        <div class=\"mdl-card__title mdl-card--expand\"></div><div class=\"mdl-card__actions\"><span class=\"capture-image__filename\">\
        ' + getDateFormattedFromFilename(filename) + '</span></div></div></a>');
    });
}

function getDateFormattedFromFilename(filename) {
    let parts = filename.split(".");
    let year = parts[0];
    let day = parts[2];
    let hour = parts[3];
    let minute = parts[4];
    let second = parts[5];
    let months = ["janvier", "février", "mars", "avril", "mai", "juin", "juillet", "août", "septembre", "octobre", "novembre", "décembre"];
    let month = months[parts[1] - 1];
    return day + " " + month + " " + year + " " + hour + ":" + minute + ":" + second;
}

function displayNotFound() {
    console.log("Affichage bannière aucun résultat.");
    $('#maincaptures').append('<div id=\"maincaptures\"><div id=\"maincapturenotfound\">\
        <span id=\"maincapturenotfoundicon\" class=\"material-icons\">find_in_page</span>\
        <p id=\"maincapturenotfoundtext\">Aucun résultat</p></div></div>');
}

function showSearchError(message) {
    var errorMessage = $('#maincaptureserror');
    errorMessage.html("<span class=\"material-icons mainerroricon\">error</span>"+message);
    errorMessage.show();
}

function showSettingsError(message) {
    var errorMessage = $('#mainsettingserror');
    errorMessage.html("<span class=\"material-icons mainerroricon\">error</span>"+message);
    errorMessage.show();
}

function getToken() {
    const regex = /(?<=main\.html\?)tok_[0-9a-f]{13}/gm;
    var arr = document.URL.match(regex);
    if(arr != null) {
        if(arr.length == 1) {
            return arr[0];
        }else {
            reconnect();
            return null;
        }
    }else {
        reconnect();
        return null;
    }
}

function checkToken(tokentest) {
    $.post("api.php", {autologin: 0, token: tokentest}, function(data, status) {
        console.log(status);
        if(status == "success") {
            console.log(data);
            var ret = JSON.parse(data);
            console.log(ret);
            if(ret.valid && ret.success) {
                console.log("Vérification main réussie !");
            }else {
                console.log("Vérification main échouée !");
                reconnect();
            }
        }
    });
}

function reconnect() {
    console.log("Redirection.");
    window.location.href = "index.html?fromage";
}

function ooops() {
    window.location.href = "index.html?ooops";
}