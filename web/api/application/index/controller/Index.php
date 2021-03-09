<?php
namespace app\index\controller;

use think\Db;
use app\common\Base;

class Index extends Base {
    public function index() {
        $this->returnJson(10200, 'dd');
    }

    //游戏进入时弹窗公告
    public function announcement($channel_id=1,$channel_game_id=1){
        $data = Db::name('announcement')
            ->where('game_channel_id', (int)$channel_game_id)
            ->value('text');

        if(empty($data)){
            $data = Db::name('announcement')
                ->where('channel_id', (int)$channel_id)
                ->value('text');
        }

        if(empty($data)){
            $data = Db::name('announcement')
                ->where('channel_id', 0)
                ->value('text');
        }

        if(empty($data)){
            $data = Db::name('announcement')
                ->where('channel_id', 1)
                ->value('text');
        }

        if(empty($data))
            $data = '暂时没有公告';

        return $data;
    }
}
