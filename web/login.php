<?php
$PASSWD = "test";

function getReturnJSON($sucess, $valid) {
    if(!$valid) {
        $ret->valid = FALSE;
        $ret->sucess = FALSE;
        return json_encode($ret);
    }

    $ret->valid = TRUE;
    if($sucess) {
        $ret->sucess = TRUE;
    }else {
        $ret->sucess = FALSE;
    }

    return json_encode($ret);
}

if($_SERVER["REQUEST_METHOD"] == "POST") {
    if(isset($_POST["passwd"])) {
        echo getReturnJSON((htmlentities($_POST["passwd"]) == $PASSWD), TRUE);
    }else {
        $ret->valid = FALSE;
        echo getReturnJSON(FALSE, FALSE);
    }
}
?>