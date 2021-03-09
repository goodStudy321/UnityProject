<?php
namespace app\admin\controller;

use think\Controller;
use think\Db;
use think\Session;
use think\Validate;
// 组管理
class Department extends Main{
	public $group_status = [];

	public function _initialize(){
		parent::_initialize();
		$this->group_status = ['禁用', '启用'];
	}


	public function list() {
		$parm = $this->request->param();

		if(!$this->request->isAjax()){
			return $this->fetch();
		}

		$data = DB::name('group')->order('sort asc')->limit(($parm['page']-1)*$parm['limit'], $parm['limit'])->select();
		foreach ($data as $k => &$val) {
			$val['num'] = $k+1;
			$val['status_name'] = $this->group_status[$val['status']];
			$val['time'] = empty($val['edit_time']) ? $val['add_time'] : $val['last_time'];
			$val['control'] = '<button class="layui-btn layui-btn-xs " onclick="x_admin_show(\'修改组\',\'edit.html?id='.$val['id'].'\',500,300)">编辑</i></button>';
			if($val['status'] > 0){
				$val['control'] .= '<button class="layui-btn layui-btn-xs layui-btn-danger" onclick="del('.$val['id'].')">禁用</button>';
			}
		}
		$count = DB::name('group')->order('sort asc')->count();

		return ['code' => 0, 'msg' => '', 'count' => $count, 'data' => $data];
	}

	// 软删除（禁用）
	public function del(){
		$id = $this->request->param('id', 0, 'int');
		if(empty($id))
			$this->returnJson(10404, '参数有误');

		$data = DB::name('group')->where(['id' => $id])->find();
		if(empty($data))
			$this->returnJson(10404, '该组不存在');

		$res = DB::name('group')->update(['id' => $id, 'status' => 0]);
		if($res > 0){
            $this->returnJson(10200, '删除成功');
		}else{
            $this->returnJson(10400, '删除失败');
        }
    }

    // 添加组
    public function add(){
    	if($this->request->isAjax()){
    		$name 	= $this->request->param('name', '', 'trim');
    		$status = $this->request->param('status', 1, 'int');
    		$sort   = $this->request->param('sort', 0, 'int');
    		if(empty($name))
    			$this->returnJson(10400, '组名不能为空');
    		$res = DB::name('group')->where(['group_name' => $name])->find();
    		if(!empty($res))
    			$this->returnJson(10400, '该组已存在');

    		$data = [
    			'group_name' => $name,
    			'status'     => $status,
    			'sort'		 => $sort,
    			'add_time'	 => date('Y-m-d H:i:s', time()),
    		];
    		DB::name('group')->insert($data);
    		$insId = DB::name('group')->getLastInsID();
    		if($insId > 0)
	    		$this->returnJson(10200, '添加成功');
	    	else
	    		$this->returnJson(10400, '添加失败');
    	}

    	return $this->fetch();
    }

    // 修改组
    public function edit(){
    	$id = $this->request->param('id', '', 'int');

    	if(empty($id))
    		$this->returnJson(10400, '参数有误');

    	$group = DB::name('group')->where('id', $id)->find();
    	if(empty($group))
    		$this->returnJson(10400, '该组不存在');

    	if($this->request->isAjax()){
    		$name 	= $this->request->param('name', '', 'trim');
    		$status = $this->request->param('status', 1, 'int');
    		$sort   = $this->request->param('sort', 0, 'int');
    		$data = [
    			'id'		 => $id,
    			'group_name' => $name,
    			'status'     => $status,
    			'sort'		 => $sort,
    			'last_time'	 => date('Y-m-d H:i:s', time()),
    		];
    		
    		$res = DB::name('group')->update($data);
    		if($res > 0)
	    		$this->returnJson(10200, '修改成功');
	    	else
	    		$this->returnJson(10400, '修改失败');
    	} 

    	$this->assign('data', $group);
    	return $this->fetch();
    } 
}