<?php
namespace app\cms\controller;

use think\Controller;
use think\Db;
class Index extends Controller
{
    function test()
    {
        $arr = Db::name('auth_rule')
        	->select();
        dump($this->array2level($arr));
    }

    function tree(){
        $array = Db::name('auth_rule')->select();
        dump($array);
        //判断是否有子集
        
     
        
    }

}
