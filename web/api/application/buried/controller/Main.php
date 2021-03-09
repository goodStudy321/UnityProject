<?php
namespace app\buried\controller;

use think\Db;
use app\common\Base;

/**
 * 技术埋点模块 - 基类
*/
class Main extends Base {

    public $connection;

    public function _initialize(){
        parent::_initialize();
        $database_config = config('database.game_logs');
        $this->connection = Db::connect($database_config);
    }

}
