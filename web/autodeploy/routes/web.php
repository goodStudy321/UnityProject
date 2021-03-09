<?php

/*
|--------------------------------------------------------------------------
| Web Routes
|--------------------------------------------------------------------------
|
| Here is where you can register web routes for your application. These
| routes are loaded by the RouteServiceProvider within a group which
| contains the "web" middleware group. Now create something great!
|
*/

Route::get('/', function () {
    return view('welcome');
});



//支持所有的URL
$URI = [];
if(isset($_SERVER['REQUEST_URI'])){
    $URI = $url = $_SERVER['REQUEST_URI'];
    $URI = parse_url($URI);
    $URI = array_values(array_filter(explode('/', $URI['path'])));
}

$controller = (isset($URI[0]) ? ucfirst($URI[0]) : 'Home').'Controller';
$action     = isset($URI[1]) ? $URI[1] : 'index';

Route::any('/'.implode('/', $URI), $controller.'@'.$action);

Auth::routes(); //已经包含了Auth的所有url route
