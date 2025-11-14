<?php
if (php_sapi_name() === 'cli-server') {
    $path = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
    
    if ($path !== '/' && file_exists(__DIR__ . $path)) {
        return false;
    }
    
    require_once 'index.php';
}
