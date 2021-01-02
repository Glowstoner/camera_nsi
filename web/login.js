$(document).ready(function (){
    console.log("Page chargée.");
    window.ooops = false;
    let rec = redirected();
    if(rec != null) {
        $('#main').fadeIn(0);
        error(rec);
    }

    autologin();

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

    $('#main').fadeIn(800);
});

function connect(password) {
    $.post("api.php", {passwd: password}, function(data, status) {
        console.log(status);
        if(status == "success") {
            console.log(data);
            var ret = JSON.parse(data);
            console.log(ret);
            if(ret.valid && ret.success) {
                console.log("Connexion réussie !");
                document.cookie = "token=" + ret.token + ";secure";

                $('#main').fadeOut(500, function() {
                    window.location.href = "main.html?" + ret.token;
                });
            }else {
                console.log("Connexion échouée !");
                error("Mot de passe incorrect !");
            }
        }
    });
}

function redirected() {
    var url = document.URL.split("?");
    if(url.length == 2) {
        if(url[1] === "fromage") {
            return "Veuillez vous connecter !";
        }else if(url[1] === "ooops") {
            window.ooops = true;
            return "Un problème serveur est survenu ! Contactez l'administrateur !";
        }
    }

    return null;
}

function autologin() {
    const regex = /(?<=token=)tok_[0-9a-f]{13}/gm;
    var arr = document.cookie.match(regex);
    
    if(arr == null) {
        return;
    }

    if(arr.length == 1) {
        $.post("api.php", {autologin: 0, token: arr[0]}, function(data, status) {
            console.log(status);
            if(status == "success") {
                console.log(data);
                var ret = JSON.parse(data);
                console.log(ret);
                if(ret.valid && ret.success) {
                    console.log("Vérification réussie !");
                    if(window.ooops) {
                        console.log("Ooops, auto connexion impossible.")
                    }else {
                        console.log("Redirection.");
                        window.location.href = "main.html?" + arr[0];
                    }
                }else {
                    console.log("Vérification échouée !");
                }
            }
        });
    }
}

function error(message) {
    var content = "<div id=\"falsepasswd\"><span class=\"material-icons redcolor\" id=\"falsepasswdlogo\">error</span><p class=\"redcolor\" id=\"falsepasswdtext\">" + message + "</p></div>"
    var target = document.getElementById("falsepasswd");
    target.innerHTML = content;
    $('#passwd').val('');
}