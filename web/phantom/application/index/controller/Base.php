<?php
namespace app\index\controller;

use think\Controller;
use think\Request;
use think\Loader;

class Base extends Controller
{
	/**
     * 构造函数
     * @param Request $request Request对象
     * @access public
    */
    public function _initialize()
    {
        $module = $this->request->module();
        if (!lotus_is_installed() && $module != 'install') {
            header('Location: ' . lotus_get_root() . '/?s=install');
            exit;
        }
    }
}