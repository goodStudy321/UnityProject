<?php
namespace app\admin\validate;

use think\Validate;

class Api extends Validate
{
    protected $rule = [
       'name'=>'require|max:20',
       'base_url'=>'require|url',
    ];
    protected $message = [
    	'name.require'=>'接口名称不能为空',
        'name.max'=>'接口名称过长',
        'base_url.require'=>'BASE_URL不能为空',
        'base_url.url'=>'BASE_URL不是URL格式',
    ];
    protected $scene = [
        'edit'  => [
            'name',
        ],
    ];
}
