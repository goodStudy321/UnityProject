<?php
namespace app\admin\model;

use think\Model;

class ChannelGame extends Model {
	public function  getAddTimeAttr($value){
	    return  $value > 0 ? date('Y-m-d H:i:s', $value) : '--';
    }
}
