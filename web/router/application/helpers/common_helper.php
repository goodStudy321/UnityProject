<?php
/**
 * Created by PhpStorm.
 * User: laijichang
 * Date: 2017/12/18
 * Time: 10:09
 */
if(! function_exists('checkMD5')){

    /**
     * @param null $driver
     * @return mixed
     */
    function checkMD5($str, $key){
        $authKey =  config_item('auth_key');
        $md5key = md5($str. $authKey);
        return $md5key == $key;
    }
}
