$(document).ready(function (){
    var asec = "#mainsecctl";
    var token = getToken();
    
    checkToken(token);

    $('#mainclickcontrol').click(function (){
        if(asec != "#mainsecctl") {
            console.log("change click control act=" + asec);
            $(asec).hide();
            $('#mainsecctl').show();
            asec = "#mainsecctl";
            updateTitle("État du programme");
        }
    });

    $('#mainclickcaptures').click(function (){
        if(asec != "#mainseccaptures") {
            console.log("change click captures act=" + asec);
            $(asec).hide();
            $('#mainseccaptures').show();
            asec = "#mainseccaptures";
            updateTitle("Captures");
        }
    });

    $('#mainclicksettings').click(function (){
        if(asec != "#mainsecsettings") {
            console.log("change click settings act=" + asec);
            $(asec).hide();
            $('#mainsecsettings').show();
            asec = "#mainsecsettings";
            updateTitle("Paramètres");
        }
    });

    $('#mainsearchbutton').click(function (){
        var date = new Date($('#mainsearchdate').val());
        console.log("date:" + date);
        var hours = $('#mainhourselect').val();
        var minutes = $('#mainminuteselect').val();
        console.log("hours: " + hours + ", minutes: " + minutes);

        if(isNaN(date)) {
            showSearchError("Veuillez spécifier une date !");
        }else if(hours === "" || isNaN(Number(hours))) {
            showSearchError("Veuillez spécifier une heure valide !");
        }else if(minutes === "" || isNaN(Number(minutes))) {
            showSearchError("Veuillez spécifier une minute valide !");
        }else {
            if(Number(hours) >= 24) {
                showSearchError("Veuillez spécifier une heure inférieure à 24 !");
            }else if(Number(minutes) >= 60) {
                showSearchError("Veuillez spécifier une minute inférieure à 60 !");
            }else {
                console.log("Valide. recherche ...");
                $('#maincaptureserror').hide();
                var data = {message: 'Recherche en cours ...', timeout: 2000};
                document.querySelector("#maincapturesloading").MaterialSnackbar.showSnackbar(data);
            }
        }
    });

    $('#mainsettingsbutton').click(function (){
        var data = {message: 'Chargement ...', timeout: 1000};
        document.querySelector("#mainsettingsbuttonloading").MaterialSnackbar.showSnackbar(data);
    });

    $('#mainsearchbutton').click(function (){
        
    });

    $('#mainctlstart').click(function (){
        controlService(true, token);
    });

    $('#mainctlstop').click(function (){
        controlService(false, token);
    })
});

function controlService(start, sessiontoken) {
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
                    if(start) {
                        $('#maingloballogo').text("check");
                        $('#maingloballogo').css("color", "green");
                        $('#mainctlinfo').text("En fonctionnement");
                    }else {
                        $('#maingloballogo').text("clear");
                        $('#maingloballogo').css("color", "red");
                        $('#mainctlinfo').text("À l'arrêt");
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

function updateTitle(title) {
    $("#maintitle").text(title);
}

function showSearchError(message) {
    var errorMessage = $('#maincaptureserror');
    errorMessage.html("<span id=\"maincaptureserroricon\" class=\"material-icons\">error</span>"+message);
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
    window.location.href = "login.html?fromage";
}

function ooops() {
    window.location.href = "login.html?ooops";
}