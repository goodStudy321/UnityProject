<?php
namespace app\admin\model;

use think\Model;

class DataServer extends Model {
	public function  getStatusAttr($value){
        switch ($value) {
            case '0': return '关闭'; break;
            case '1': return '开启'; break;
            case '2': return '繁忙'; break;
            case '3': return '火爆'; break;
            case '4': return '爆满'; break;
        }
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
