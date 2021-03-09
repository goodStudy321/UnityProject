<?php
namespace app\common;

use think\Request;
use think\Controller;

class Base extends Controller {
    public function _initialize(){
        parent::_initialize();
    }

    public function returnJson($code, $msg = '', $data = []){
        die(json_encode(['status'=>['code'=>$code,'msg'=>$msg], 'data'=>$data]));
    }

}
