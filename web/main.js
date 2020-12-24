$(document).ready(function (){
    var asec = "#mainsecctl";

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
        }else if(hours === "" || Number(hours) == NaN) {
            showSearchError("Veuillez spécifier une heure valide !");
        }else if(minutes === "" || Number(minutes) == NaN) {
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
});

function updateTitle(title) {
    $("#maintitle").text(title);
}

function showSearchError(message) {
    var errorMessage = $('#maincaptureserror');
    errorMessage.html("<span id=\"maincaptureserroricon\" class=\"material-icons\">error</span>"+message);
    errorMessage.show();
}