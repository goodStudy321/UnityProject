<?php
namespace app\admin\validate;

use think\Validate;

class App extends Validate
{
    protected $rule = [
       'name'=>'require|min:2|max:20',
        'appid'=>'unique:app'
    ];
    protected $message = [
    	'name.require'=>'应用名称不能为空',
        'name.max'=>'应用名称过长',
        'appid.unique'=>'尴尬了,系统随机数重复,请重新打开窗口生成',
    ];
    protected $scene = [
        'edit'  => [
            'name',
        ],
    ];
}
