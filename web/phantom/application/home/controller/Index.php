<?php
namespace app\home\controller;

use think\Controller;
use think\Db;
use think\Session;

class Index extends Main {

    public function index() {
    	$group = DB::name('group')->where('status',1)->order('sort asc')->select();
    	$url = DB::name('url')->where('status', 1)->order('sort desc,id asc')->select();
    	$data = [];
    	foreach ($group as $key => $value) {
    		$data[$value['id']]['id'] = $value['id'];
    		$data[$value['id']]['group_name'] = $value['group_name'];
    		$data[$value['id']]['url'] = [];
    		foreach ($url as $k => $val) {
    			if($val['group_id'] == $value['id']){
    				$data[$value['id']]['url'][] = $val;
    			}
    		}
    	}

    	$this->assign('data', $data);
        return $this->fetch();
    }

    // 添加链接
	public function add(){
		if(empty(session('url_username')) || empty(session('url_user_id'))){
			return $this->redirect('home/index/login');
		}

		$group_id = $this->request->param('group_id', 0 ,'int');
		$this->assign('group_id', $group_id);
		if($this->request->isAjax()){
			$name 	 = $this->request->param('name', '', 'trim');
			$url 	 = $this->request->param('url', '', 'trim');
			$status  = $this->request->param('status', 1, 'int');

			if (empty($group_id)) {
				$this->returnJson(10400, '请选择所属组');
			}
			if (empty($url)) {
				$this->returnJson(10400, '请输入链接地址');
			}else{
				if(mb_strlen($url) < 4)
					$this->returnJson(10400, 'url有误');
			}
			$res = DB::name('url')->where(['url_name' => $name, 'status' => 1])->find();
			if(!empty($res)){
				$this->returnJson(10400, '该链接名已存在');
			}

			$data = [
				'user_id'  => session('url_user_id'),
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

	// 删除（软删除）
	public function del(){
		if(empty(session('url_username')) && empty(session('url_user_id')))
			$this->returnJson(10100,'请先登录');

		$id = $this->request->param('id', 0, 'int');
		if(empty($id))
			$this->returnJson(10400, '参数有误');

		$res = DB::name('url')->where('id',$id)->find();
		if (empty($res))
			$this->returnJson(10400, '该链接不存在');
		if($res['user_id'] != session('url_user_id'))
			$this->returnJson(10400, '你无权限删除该链接');

		$result = DB::name('url')->where(['user_id' => session('url_user_id'),'id' => $id])->update(['status' => 0]);
		if($result > 0){
            $this->returnJson(10200, '删除成功');
		}else{
            $this->returnJson(10400, '删除失败');
        }
	}

	// 登录/注册
	public function login(){
		if($this->request->isAjax()){
			$action= $this->request->param('action', 'login', 'trim');
			$email = $this->request->param('email', '', 'trim');
			$pwd   = $this->request->param('pwd', '', 'trim');

			if(empty($email))
				$this->returnJson(10400, '请填写邮箱');
			if(empty($pwd)) 
				$this->returnJson(10400, '请输入密码');

			$res = DB::name('subscriber')->where(['email' => $email])->find();
			if($action == 'register'){
				// 注册
				$repwd = $this->request->param('repwd', '', 'trim');
				if($repwd != $pwd)
					$this->returnJson(10400, '密码不一致');

				if(!empty($res))
					$this->returnJson(10300, '该邮箱已存在');

				$data = [
					'email' => $email,
					'pwd'   => md5($pwd),
					'status'=> 1,
					'add_time'=> date('Y-m-d H:i:s', time()),
				];
				DB::name('subscriber')->insert($data);
				$insId = DB::name('subscriber')->getLastInsID();
				if($insId > 0){
					$this->returnJson(10202, '注册成功,请登录');
				} else {
					$this->returnJson(10400, '注册失败');
				}
			} else {
				// 登录
				if(empty($res))
					$this->returnJson(10400, '该用户不存在');

				if(md5($pwd) == $res['pwd']){
					session('url_username', $email);
					session('url_user_id', $res['id']);
					$this->returnJson(10200, '登录成功');
				} else {
					$this->returnJson(10400, '密码错误');
				}
			}
		} else {
			return $this->fetch();
		}
	}

	// 登出
	public function logout(){
		session('url_username', null);
        $this->redirect('home/index/index');
	}
}
