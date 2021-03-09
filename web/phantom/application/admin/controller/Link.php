<?php
namespace app\admin\controller;

use think\Controller;
use think\Db;
use think\Session;
use think\Validate;
// 链接管理
class Link extends Main{
	public $url_status = [];

	public function _initialize(){
		parent::_initialize();
		$this->url_status = ['禁用', '启用'];
	}


	public function list() {

		$res = DB::name('group')->where(['status' => 1])->order('sort asc')->select();
		$group = [];
		foreach ($res as $key => $val) {
			$group[$val['id']] = $val;
		}
		$this->assign('group', $group);

		if($this->request->isAjax()){
			$parm = $this->request->param();
			$where = [];
			if(!empty($parm['group_id'])){
				$where['group_id'] = (int)$parm['group_id'];
			}

			$data = DB::name('url')
				->where($where)
				->order('sort desc')
				->limit(($parm['page']-1)*$parm['limit'], $parm['limit'])
				->select();
			foreach ($data as $k => &$v) {
				$v['num'] = $k+1;
				$v['group_name'] = $group[$v['group_id']]['group_name'];
				$v['url_status'] = $this->url_status[$v['status']];
				$v['control'] = '<button class="layui-btn layui-btn-xs " onclick="x_admin_show(\'修改组\',\'edit.html?id='.$v['id'].'\',500,360)">编辑</i></button>';
				if($v['status'] > 0){
					$v['control'] .= '<button class="layui-btn layui-btn-xs layui-btn-danger" onclick="del('.$v['id'].')">禁用</button>';
				}
			}

			$count = DB::name('url')->where($where)->count();
			return ['code' => 0, 'msg' => '', 'count' => 0, 'data' => $data];
		}

		return $this->fetch();
	}

	// 删除（软删除）
	public function del(){
		$id = $this->request->param('id', 0, 'int');
		if(empty($id))
			$this->returnJson(10400, '参数有误');

		$res = DB::name('url')->where('id',$id)->find();
		if (empty($res))
			$this->returnJson(10400, '该链接不存在');

		$result = DB::name('url')->update(['id' => $id, 'status' => 0]);
		if($result > 0){
            $this->returnJson(10200, '删除成功');
		}else{
            $this->returnJson(10400, '删除失败');
        }
	}

	// 添加链接
	public function add(){
		if($this->request->isAjax()){
			$group_id = $this->request->param('group_id', 0 ,'int');
			$name 	  = $this->request->param('name', '', 'trim');
			$url 	  = $this->request->param('url', '', 'trim');
			$status   = $this->request->param('status', 1, 'int');

			if (empty($group_id)) {
				$this->returnJson(10400, '请选择所属组');
			}
			if (empty($url)) {
				$this->returnJson(10400, '请输入链接地址');
			}else{
				$url = 'http://'.$url;
				$match = "/http:[\/]{2}[a-z]+[.]{1}[a-z\d\-]+[.]{1}[a-z\d]*[\/]*[A-Za-z\d]*[\/]*[A-Za-z\d]*/";
				preg_match_all($match, $url, $arr);
				if(empty($arr[0]))
					$this->returnJson(10400, 'url有误');
			}
			$res = DB::name('url')->where(['url_name' => "$name"])->find();
			if(!empty($res)){
				$this->returnJson(10400, '该链接名已存在');
			}

			$data = [
				'group_id' => $group_id,
				'url_name' => $name,
				'url'	   => $url,
				'status'   => $status,
				'add_time' => date('Y-m-d H:i:s', time()),
			];
			DB::name('url')->insert($data);
			$insId = DB::name('url')->getLastInsID();
			if($insId > 0){
				$this->returnJson(10200, '添加成功');
			} else {
				$this->returnJson(10500, '添加失败');
			}
		} 

		$group = DB::name('group')->where(['status' => 1])->order('sort asc')->select();
		$this->assign('group', $group);

		return $this->fetch();
	}

	// 编辑
	public function edit() {
		$id = $this->request->param('id', 0, 'int');
		if(empty($id))
			$this->returnJson(10400, '参数有误');

		if($this->request->isAjax()){
			$group_id = $this->request->param('group_id', 0 ,'int');
			$name 	  = $this->request->param('name', '', 'trim');
			$url 	  = $this->request->param('url', '', 'trim');
			$status   = $this->request->param('status', 1, 'int');

			if (empty($group_id)) {
				$this->returnJson(10400, '请选择所属组');
			}
			if (empty($url)) {
				$this->returnJson(10400, '请输入链接地址');
			}else{
				$url = 'http://'.$url;
				$match = "/http:[\/]{2}[a-z]+[.]{1}[a-z\d\-]+[.]{1}[a-z\d]*[\/]*[A-Za-z\d]*[\/]*[A-Za-z\d]*/";
				preg_match_all($match, $url, $arr);
				if(empty($arr[0]))
					$this->returnJson(10400, 'url有误');
			}
			$res = DB::name('url')->where(['url_name' => "$name", 'id' => ['neq', $id]])->find();
			if(!empty($res)){
				$this->returnJson(10400, '该链接名已存在');
			}

			$data = [
				'id'	   => $id,
				'group_id' => $group_id,
				'url_name' => $name,
				'url'	   => $url,
				'status'   => $status,
				'last_time'=> date('Y-m-d H:i:s', time()),
			];
			$insId = DB::name('url')->update($data);
			if($insId > 0){
				$this->returnJson(10200, '编辑成功');
			} else {
				$this->returnJson(10500, '编辑失败');
			}
		} else {
			$group = DB::name('group')->where(['status' => 1])->order('sort asc')->select();
			$data = DB::name('url')->where('id', $id)->find();
			$this->assign('group', $group);
			$this->assign('data', $data);

			return $this->fetch();
		}
	}
}