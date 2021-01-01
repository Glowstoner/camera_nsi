<?php
$TOKENS_EXPIRE = 5 * 60;
$TOKENS_PATH = "tokens.dat";
$PASSWD = "test";

function processLoginJSON($sucess, $valid) {
    $ret = new stdClass();
    if(!$valid) {
        $ret->valid = FALSE;
        $ret->sucess = FALSE;
        return json_encode($ret);
    }

    $ret->valid = TRUE;
    if($sucess) {
        $ret->sucess = TRUE;
        $ret->token = addToken();
    }else {
        $ret->sucess = FALSE;
    }

    return json_encode($ret);
}

function processAutologin() {
    $ret = new stdClass();
    $ret->valid = TRUE;
    $ret->sucess = TRUE;
    return json_encode($ret);
}

function processError() {
    echo processLoginJSON(FALSE, FALSE);
}

function writeTokenDataStorage($data) {
    file_put_contents($TOKENS_PATH, $data, FILE_APPEND);
}

function readTokenDataStorage() {
    $handle = fopen($TOKENS_PATH, "r");
    $data = fread($handle, filesize($TOKENS_PATH));
    fclose($handle);
    return $data;
}

function writeTokenStorage($token) {
    if(!file_exists($TOKENS_PATH)) {
        writeTokenDataStorage($token . "\n");
        echo "Existe po\n";
    }else {
        echo "Existe oui oui\n";
        $olddata = readTokenDataStorage();
        echo $olddata;
        echo "\n------------------------------\n";
        $data = $olddata . $token . "\n";
        echo $data;
        writeTokenDataStorage($data);
    }
}

function readTokenStorage() {
    if(file_exists($TOKENS_PATH)) {
        $data = readTokenDataStorage();
        return explode("\n", $data);
    }

    return array();
}

function formatTokenStorage($token) {
    return $token . "-" . round(microtime(true) * 1000);
}

function getNewToken() {
    return uniqid("tok_");
}

function actionToken($token) {
    $data = "";
    $tokens = readTokenStorage();
    foreach($tokens as &$tok) {
        $ptok = explode("-", $tok);
        if($ptok[0] === $token) {
            $data .= (formatTokenStorage($token) . "\n");
        }else {
            $data .= ($tok . "\n");
        }
    }

    writeTokenDataStorage($data);
}

function removeInvalidTokens() {
    $data = "";
    $tokens = readTokenStorage();
    foreach($tokens as &$tok){
        $ptok = explode("-", $tok);
        if($ptok[1] <= (round(microtime(true) * 1000) + 1000 * $TOKENS_EXPIRE)) {
            $data .= $tok;
        }
    }

    writeTokenStorage($data);
}

function checkToken($token) {
    removeInvalidTokens();
    $tokens = readTokenStorage();
    foreach($tokens as &$tok) {
        $ptok = explode("-", $tok);
        if($ptok[0] === $token) {
            actionToken($token);
            return TRUE;
        }
    }

    return FALSE;
}

function addToken() {
    $newtoken = getNewToken();
    writeTokenStorage(formatTokenStorage($newtoken));
    return $newtoken;
}

if($_SERVER["REQUEST_METHOD"] == "POST") {
    if(count($_POST) == 1) {
        if(isset($_POST["passwd"])) {
            echo processLoginJSON((htmlentities($_POST["passwd"]) == $PASSWD), TRUE);
        }else {
            processError();
        }
    }else if(count($_POST) == 2) {
        if(isset($_POST["autologin"]) && isset($_POST["token"])) {
            if(checkToken(htmlentities($_POST["token"]))) {
                echo processAutologin();
            }else {
                processError();
            }
        }else {
            processError();
        }
    }else {
        processError();
    }
}
?>