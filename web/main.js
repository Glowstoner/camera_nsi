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
});

function updateTitle(title) {
    $("#maintitle").text(title);
}