<?php
namespace app\admin\controller;

use think\Controller;
use think\Db;
use think\Session;
use think\Validate;
// 用户管理
class Subscriber extends Main{
	public $user_status = [];

	public function _initialize(){
		parent::_initialize();
		$this->user_status = ['禁用', '启用'];
	}

	public function list() {
		$parm = $this->request->param();
		$where = ['status' => 1];

		// 模板渲染
		if(!$this->request->isAjax()){	
			return $this->fetch();
		}
		
		if(!empty($parm['email'])){
			$where['email'] = ['like', '%'.trim($parm['email']).'%'];
		}
		$data = DB::name('subscriber')
			->order('add_time DESC')
			->where($where)
			->limit(($parm['page']-1)*$parm['limit'], $parm['limit'])
			->select();
		foreach ($data as &$value) {
			$value['user_status'] = $this->user_status[$value['status']];
			if($value['status'] > 0){
				$value['control'] = '<button class="layui-btn layui-btn-xs layui-btn-danger" onclick="del('.$value['id'].')">删除</button>';
			} else {
				$value['control'] = '';
			}
		}
		$count = DB::name('subscriber')->count();		

		return ['code' => 0, 'msg' => '', 'count' => $count, 'data' => $data];
	}

	// 软删除
	public function del(){
		$id = $this->request->param('id', 0, 'int');
		if(empty($id))
			$this->returnJson(10404, '参数有误');

		$data = DB::name('subscriber')->where(['id' => $id])->find();
		if(empty($data))
			$this->returnJson(10404, '该用户不存在');

		$res = DB::name('subscriber')->update(['id' => $id, 'status' => 0]);
		if($res > 0){
            $this->returnJson(10200, '删除成功');
		}else{
            $this->returnJson(10400, '删除失败');
        }
    }
}