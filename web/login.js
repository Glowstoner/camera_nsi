$(document).ready(function (){
    console.log("Page chargée.");

    $('#loginbutton').click(function (){
        console.log("Connexion ...");
        var password = $('#passwd').val();
        console.log(password);

        if(password) {
            console.log("Mot de passe valide.");
            connect(password);
        }else {
            error("Vous devez renseigner un mot de passe !");
        }
    });

    $('#passwd').on("keyup", function(event) {
        if(event.key == "Enter") {
            console.log("clicked");
            event.preventDefault();
            $('#loginbutton').trigger("click");
        }
    });
});

function connect(password) {
    $.post("login.php", {passwd: password}, function(data, status) {
        if(status == "success") {
            var ret = JSON.parse(data);
            if(ret.valid && ret.sucess) {
                console.log("Connexion réussie !");
            }else {
                console.log("Connexion échouée !");
                error("Mot de passe incorrect !");
            }
        }
    });
}

function error(message) {
    var content = "<div id=\"falsepasswd\"><span class=\"material-icons redcolor\" id=\"falsepasswdlogo\">error</span><p class=\"redcolor\" id=\"falsepasswdtext\">" + message + "</p></div>"
    var target = document.getElementById("falsepasswd");
    target.innerHTML = content;
    $('#passwd').val('');
}