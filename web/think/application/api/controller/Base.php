<?php
namespace app\api\controller;

use think\Controller;

class Base extends Controller {

    public function _initialize() {
        parent::_initialize();
    }

    public function returnJson($code, $msg = '', $data = []){
        die(json_encode(array('status'=>['code'=>$code,'msg'=>$msg], 'data'=>$data)));
    }

}
