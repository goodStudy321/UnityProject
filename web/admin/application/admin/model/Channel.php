<?php
namespace app\admin\model;

use think\Model;
use think\Db;

class Channel extends Model {
	public function  getAddTimeAttr($value){
	    return  $value > 0 ? date('Y-m-d H:i:s', $value) : '--';
    }

    public function processChannels(&$data){
        $channel_name = $game_channel_name = [];

        //取出渠道数据
        $channel_id = array_column($data, 'channel_id');
        $channel_id = array_unique($channel_id);
        if(!empty($channel_id)){
            $channel_id = implode(',', $channel_id);
            $channel_name = $this->where("id in($channel_id)")->column('name', 'id');
        }

        //取出包渠道数据
        $game_channel_id = array_column($data, 'game_channel_id');
        $game_channel_id = array_unique($game_channel_id);
        if(!empty($game_channel_id)){
            $game_channel_id = implode(',', $game_channel_id);
            $game_channel_name = DB::name('channel_game')
                ->where("id in($game_channel_id)")
                ->column('name', 'id');
        }

        return compact('channel_name', 'game_channel_name');
    }

}
