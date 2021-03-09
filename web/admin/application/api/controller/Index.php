<?php
namespace app\api\controller;

use think\Request;

class Index extends Base{

    public function __construct(){
        parent::__construct();
    }

    public function index() {
        $this->returnJson(10200, '', []);
    }

}
