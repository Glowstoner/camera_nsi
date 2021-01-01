<?php
$TOKENS_EXPIRE = 30;
$TOKENS_PATH = "tokens.dat";
$PASSWD = "test";

function processLogin($sucess) {
    $ret = new stdClass();
    $ret->valid = TRUE;
    if($sucess) {
        $ret->sucess = TRUE;
        $ret->token = addToken();
    }else {
        $ret->sucess = FALSE;
    }

    echo json_encode($ret);
}

function processAutologin() {
    $ret = new stdClass();
    $ret->valid = TRUE;
    $ret->sucess = TRUE;
    return json_encode($ret);
}

function processError($valid) {
    $ret = new stdClass();
    $ret->valid = $valid;
    $ret->sucess = FALSE;
    echo json_encode($ret);
}

function writeTokenDataStorage($data) {
    global $TOKENS_PATH;
    $handle = fopen($TOKENS_PATH, "w");
    fwrite($handle, $data);
    fclose($handle);
}

function readTokenDataStorage() {
    global $TOKENS_PATH;
    if(filesize($TOKENS_PATH) == 0) return "";
    $handle = fopen($TOKENS_PATH, "r");
    $data = fread($handle, filesize($TOKENS_PATH));
    fclose($handle);
    return $data;
}

function writeTokenStorage($token) {
    global $TOKENS_PATH;
    if(!file_exists($TOKENS_PATH)) {
        writeTokenDataStorage($token . "\n");
    }else {
        $olddata = readTokenDataStorage();
        $data = $olddata . $token . "\n";
        echo $data;
        writeTokenDataStorage($data);
    }
}

function readTokenStorage() {
    global $TOKENS_PATH;
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
        if(empty($tok)) continue;
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
    global $TOKENS_EXPIRE;
    $data = "";
    $tokens = readTokenStorage();
    print_r($tokens);
    if(empty($tokens)) return;
    foreach($tokens as &$tok){
        if(empty($tok)) continue;
        $ptok = explode("-", $tok);
        $rest = ($ptok[1] + 1000 * $TOKENS_EXPIRE) - round(microtime(true) * 1000);
        if($rest >= 0) {
            $data .= ($tok . "\n");
        }
    }

    writeTokenDataStorage($data);
}

function checkToken($token) {
    if(tokenExists($token)) {
        actionToken($token);
        return TRUE;
    }else {
        return FALSE;
    }
}

function tokenExists($token) {
    removeInvalidTokens();
    $tokens = readTokenStorage();
    foreach($tokens as &$tok) {
        $ptok = explode("-", $tok);
        if($ptok[0] === $token) {
            return TRUE;
        }
    }

    return FALSE;
}

function addToken() {
    $newtoken = "";
    do {
        $newtoken = getNewToken();
    } while(tokenExists($newtoken));

    writeTokenStorage(formatTokenStorage($newtoken));
    return $newtoken;
}

if($_SERVER["REQUEST_METHOD"] == "POST") {
    if(count($_POST) == 1) {
        if(isset($_POST["passwd"])) {
            processLogin((htmlentities($_POST["passwd"]) == $PASSWD));
        }else {
            processError(FALSE);
        }
    }else if(count($_POST) == 2) {
        if(isset($_POST["autologin"]) && isset($_POST["token"])) {
            if(checkToken(htmlentities($_POST["token"]))) {
                echo processAutologin();
            }else {
                processError(TRUE);
            }
        }else {
            processError(FALSE);
        }
    }else {
        processError(FALSE);
    }
}
?>