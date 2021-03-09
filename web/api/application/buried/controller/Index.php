<?php
namespace app\buried\controller;

use app\common\Base;

/**
 * 技术埋点模块 - 主控制器
*/
class Index extends Base {

    public function index() {
        $this->returnJson(10200);
    }
}
