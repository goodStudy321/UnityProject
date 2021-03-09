<?php
namespace app\admin\model;

use think\Model;

class DataServer extends Model {
	public function  getStatusAttr($value){
        return $value == 1 ? ' 开启' : '--';
    }
	public function  getIsNewAttr($value){
        return $value == 1 ? '新服' : '其他';
    }
	public function  getIsDebugAttr($value){
        return $value == 1 ? '开发环境' : '<font color=red>正式环境</font>';
    }
	public function  getAddTimeAttr($value){
	    return $value > 0 ? date('Y-m-d H:i:s', $value) : '--';
    }

}
