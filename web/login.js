var error = $('#falsepasswd');

$(document).ready(function (){
    console.log("hello WORLD!");
    error.remove();
});

function error() {
    $('#logintitle').after(error)
}