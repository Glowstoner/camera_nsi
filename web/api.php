<?php
$TOKENS_EXPIRE = 1 * 60;
$TOKENS_PATH = "tokens.dat";
$PASSWD = "test";

function processLogin($success) {
    $ret = new stdClass();
    $ret->valid = TRUE;
    if($success) {
        $ret->success = TRUE;
        $ret->token = addToken();
    }else {
        $ret->success = FALSE;
    }

    echo json_encode($ret);
}

function processAutologin() {
    $ret = new stdClass();
    $ret->valid = TRUE;
    $ret->success = TRUE;
    return json_encode($ret);
}

function processError($valid) {
    $ret = new stdClass();
    $ret->valid = $valid;
    $ret->success = FALSE;
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

function isLogged() {
    return checkToken(htmlentities($_POST["token"]));
}

function serviceControlRequestValid($data) {
    $sandata = htmlentities($data);
    if($sandata === "start") {
        return 1;
    }else if($sandata === "stop") {
        return 0;
    }else {
        return -1;
    }
}

function serviceAction($action) {
    if($action) {
        return serviceStart();
    }else {
        return serviceStop();
    }
}

function serviceStart() {
    //Start service
    //echo "START\n";
    return TRUE; //tmp value
}

function serviceStop() {
    //Stop service
    //echo "STOP\n";
    return FALSE; //tmp value
}

function processControl($success) {
    $ret = new stdClass();
    $ret->valid = TRUE;
    $ret->success = TRUE;
    $ret->operationSuccess = $success;
    echo json_encode($ret);
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
            if(isLogged()) {
                echo processAutologin();
            }else {
                processError(TRUE);
            }
        }else if(isset($_POST["servicectl"]) && isset($_POST["token"])) {
            $ctlreq = serviceControlRequestValid($_POST["servicectl"]);
            if($ctlreq != -1) {
                if(isLogged()) {
                    processControl(serviceAction($ctlreq));
                }else {
                    processError(TRUE);
                }
            }else {
                processError(FALSE);
            }
        }else {
            processError(FALSE);
        }
    }else {
        processError(FALSE);
    }
}
?>