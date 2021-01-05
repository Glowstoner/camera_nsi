<?php
$TOKENS_EXPIRE = 3 * 60;
$TOKENS_PATH = "/var/www/html/data/tokens.dat";
$CAPTURES_PATH = "/var/www/html/data/captures";
$DELIVERY_PATH = "livraison";
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
    echo json_encode($ret);
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
        }else {
            removeOldDeliveries($ptok[0]);
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
    return TRUE; //tmp value
}

function processControl($success) {
    $ret = new stdClass();
    $ret->valid = TRUE;
    $ret->success = TRUE;
    $ret->operationSuccess = $success;
    echo json_encode($ret);
}

function capturesSearchRequestValid($data) {
    $sandata = $data; //TODO change sanitazer, potential JSON injection
    $jdata = json_decode($sandata);
    if($jdata == NULL) return NULL;
    if($jdata->year < 0) return NULL;
    if($jdata->month <= 0 || $jdata->month > 12) return NULL;
    if($jdata->day <= 0 || $jdata->day > 31) return NULL;
    if($jdata->hour < 0 || $jdata->hour > 23) return NULL;
    if($jdata->minute < 0 || $jdata->minute > 59) return NULL;
    return $jdata;
}

function searchCapturesByDate($date) {
    global $CAPTURES_PATH;
    $cpath = $CAPTURES_PATH."/".$date->year.".".$date->month.".".$date->day.".".$date->hour.".".$date->minute.".";
    $fc = array();
    foreach(glob($cpath."*") as $filename) {
        array_push($fc, $filename);
    }
    return $fc;
}

function createSecureDeliveryPath() {
    global $DELIVERY_PATH;

    if(!file_exists($DELIVERY_PATH)) {
        mkdir($DELIVERY_PATH);
    }

    removeOldDeliveries($_POST["token"]);

    $fname = "captures";
    do {
        $fname = $DELIVERY_PATH."/".$_POST["token"]."-".hash('md5', random_bytes(20));
    }while(file_exists($fname));
    mkdir($fname, 0777, TRUE);
    return $fname;
}

function removeDirectory($target) {
    if(is_dir($target)) {
        $files = glob($target.'*', GLOB_MARK);
        foreach($files as $file){
            removeDirectory($file);      
        }
        if(file_exists($target)) rmdir($target);
    }elseif (is_file($target)) {
        unlink($target);  
    }
}

function removeOldDeliveries($token) {
    global $DELIVERY_PATH;
    foreach(glob($DELIVERY_PATH."/".$token."-*", GLOB_ONLYDIR) as $dirs) {
        removeDirectory($dirs);
    }
}

function capturesAction($folder, $data) {
    global $CAPTURES_PATH;
    $fc = searchCapturesByDate($data);
    $cutlen = strlen($CAPTURES_PATH);
    $files = array();
    foreach($fc as $filecapture) {
        $filename = $folder.substr($filecapture, $cutlen);
        copy($filecapture, $filename);
        array_push($files, $filename);
    }
    return $files;
}

function processCaptures($folder, $files) {
    $ret = new stdClass();
    $ret->valid = TRUE;
    $ret->success = TRUE;
    $ret->operationSuccess = TRUE;
    $ret->deliveryPath = $folder;
    $ret->files = $files;
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
                processAutologin();
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
        }else if(isset($_POST["captures"]) && isset($_POST["token"])) {
            $captreq = capturesSearchRequestValid($_POST["captures"]);
            if($captreq != NULL) {
                if(isLogged()) {
                    $folder = createSecureDeliveryPath();
                    $files = capturesAction($folder, $captreq);
                    processCaptures($folder, $files);
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