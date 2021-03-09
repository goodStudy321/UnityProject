<?php

$dataname = 'last_admin';
$database = [];

$file = $_SERVER['DOCUMENT_ROOT'] . '/../../mysql.php';
if(file_exists($file))
    $database = include $file;

if(!isset($database[$dataname]) || in_array('', $database[$dataname]))
    die('database error');

//公共数据库配置
$config_public = [
    'type'     => 'mysql',
    'hostname' => '',
    'username' => '',
    'password' => '',
    'database' => '',
    'hostport' => '3306',
    'charset'  => 'utf8',
    'prefix'   => '',
];

//主数据库用户
$arr = array_merge($config_public, $database[$dataname]);
unset($database[$dataname]);

if(empty($database))
    return $arr;

//多个数据库用户
foreach($database as &$v)
    $v = array_merge($config_public, $v);
unset($v);

return $arr + $database;

