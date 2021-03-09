<?php
namespace app\admin\model;

use think\Model;

class Mail extends Model{

	protected $autoWriteTimestamp = true;

	public function  getTimeAttr($value){
	    return date('Y-m-d H:i:s', $value);
    }

    public function  getUserAttr($value){
        return empty($value) ? '全服邮件' : $value;
    }

    public function  getTypeAttr($value){
        return $value == 0 ? '个人邮件' : '全服邮件';
    }

    public function  getStatusAttr($value){
        return $value == 0 ? '未成功' : '发送成功';
    }
    public function  getBindAttr($value){
	    return $value == 0 ? '不绑定' : '绑定';
    }











}
