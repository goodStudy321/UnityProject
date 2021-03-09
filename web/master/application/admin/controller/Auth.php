<?php
namespace app\admin\controller;

use \think\Db;
use \think\Reuquest;
class auth extends Main
{
    function index(){
        //获取权限列表
        $auth = Db::name('auth_rule')
	        ->order(['sort' => 'ASC'])
	        ->select();
        $auth = array2Level($auth);
        return $this->fetch('index',['auth'=>$auth]);
    }
    //展示权限界面
    function showAdd(){
    	$auth = Db::name('auth_rule')->order(['sort' => 'ASC'])->select();
        $auth = array2Level($auth);
    	return  $this->fetch('add',['auth'=>$auth]);
    }
    //新增权限
    function add(){
    	$post = $this->request->post();
        $str = $post['icon'];
        $post['icon'] = $this->checkStr($str);
    	$validate = validate('auth');
    	$res = $validate->check($post);
		if($res!==true){
			$this->error($validate->getError());
		}else{
			Db::name('auth_rule')
			->insert($post);
			$this->success('success');
		}
    }
    //异常字符串处理
    function checkStr($str){
        switch ($str) {
            case strspn($str,'&#;')>0:
                $str =  ltrim($str,'&#');
                $str =  rtrim($str,';');
                return $str;
            default:
                return $str;
                break;
        }
    }
    //权限编辑页面
    function showEdit(){
        $id  = $this->request->get('id');
        $pid = Db::name('auth_rule')
            ->where('id',$id)
            ->value('pid');
        if($pid!==0){
            $p_title = Db::name('auth_rule')
                ->where('id',$pid)
                ->value('title');
        }else{
            $p_title = '顶级菜单';
        }
        $this->assign('p_title',$p_title);
        $data  =   Db::name('auth_rule')
            ->where('id',$id)
            ->find();
        return  $this->fetch('edit',['data'=>$data]);
    }
    /*权限编辑*/
    function edit(){
        $post =  $this->request->post();
        $id = $post['id'];
        /*start 演示数据保护，开发可以删除*/
        if($id<203){
            $this->error('很抱歉,系统默认权限无法编辑');
        }
        /*end*/
        $validate = validate('auth');
        $validate->scene('edit');
        $res = $validate->check($post);
        if($res!==true){
            $this->error($validate->getError());
        }else{
            unset($post['id']);
            Db::name('auth_rule')
            ->where('id',$id)
            ->update($post);
            $this->success('success');
        }
    }
    /*权限删除*/
    function delete(){
        $id = $this->request->post('id');
        $juge = Db::name('auth_rule')
            ->where('pid',$id)
            ->find();
        /*start 演示数据保护，开发可以删除*/
         if($id<203){
                  $this->error('重要节点无法删除');
        }
        /*end*/
        if(!empty($juge)){
                $this->error('请先删除子权限');
        }else{
            if($id<203){
                 $this->error('重要节点无法删除');
            }else{
                 Db::name('auth_rule')
                    ->delete($id);
                    $this->success('success');
            }
        }
    }
    /*角色页面展示*/
    function showRole(){
        $role = Db::name('auth_group')
            ->order('id desc')
            ->paginate('15');
        $this->assign('role',$role);
        return $this->fetch('role');
    }
    //新增角色
    function addRole(){
        $auth_group = $this->request->post('role_name');
        if(!empty($auth_group)){
            $res = Db::name('auth_group')
            ->where('title',$auth_group)
            ->find();
            if(empty($res)){
                 Db::name('auth_group')
                ->insert(['title'=>$auth_group,'status'=>0]);
                $this->success('添加成功');
            }else{
                $this->error('系统中已经存在该用户名');
            }
        }else{
            $this->error('请输入角色名称再添加');
        }
    }
    //切换角色状态
    function doChangeRoleStatus(){
        $data = $this->request->post();
        if($data['id']==1){
            $this->error('不允许修改超级管理员角色');
        }
        if($data['status']==0){
            Db::name('auth_group')
                ->where('id',$data['id'])
                ->update(['status'=>1]);
                $this->success('启用成功');
        }else{
             Db::name('auth_group')
                ->where('id',$data['id'])
                ->update(['status'=>0]);
                $this->success('禁用成功');
        }
    }
    //授权页面展示
    function showAuth($id){
        $this->assign('id',$id);
        return $this->fetch('auth');
    }
    //获取规则数据
    public function getJson()
    {
        $id = $this->request->post('id');
        $auth_group_data = Db::name('auth_group')->find($id);
        $auth_rules      = explode(',', $auth_group_data['rules']);
        $auth_rule_list  = Db::name('auth_rule')->field('id,pid,title')->select();

        foreach ($auth_rule_list as $key => $value) {
            in_array($value['id'], $auth_rules) && $auth_rule_list[$key]['checked'] = true;
        }
        return $auth_rule_list;
    }
    /**
     * 更新权限组规则
     * @param $id
     * @param $auth_rule_ids
     */
    public function updateAuthGroupRule()
    {
        if ($this->request->isPost()){
            $post = $this->request->post();
            if($post['id']==1){
               $this->error('超级管理员信息无法编辑');
            }
            $group_data['id']    = $post['id'];
            $group_data['rules'] = is_array($post['auth_rule_ids']) ? implode(',', $post['auth_rule_ids']) : '';
            if (Db::name('auth_group')->where('id',$post['id'])->update($group_data) !== false) {
                $this->success('授权成功');
            } else {
                $this->error('授权失败');
            }
        }
    }
    //角色编辑页面
    function showRoleEdit($id){
        $data = Db::name('auth_group')
        ->where('id',$id)
        ->find();
        return $this->fetch('roleEdit',['data'=>$data]);
    }
    //角色编辑
    function editRole(){
        $post = $this->request->post();
        if($post['id']==1){
           $this->error('超级管理员信息无法编辑');
        }
        $validate = validate('role');
        $res = $validate->check($post);
        if(!$res){
            $this->error($validate->getError());
        }else{
            Db::name('auth_group')
            ->where('id',$post['id'])
            ->update(['title'=>$post['title'],'status'=>$post['status']]);
            $this->success('更新成功');
        }
    }
    // 删除角色
    function delRole(){
        $id  = $this->request->post('id');
        if($id!=='1'){
            $res =  Db::name('auth_group')
            ->delete($id);
            $this->success('删除成功');
        }else{
            $this->error('超级管理员无法删除');
        }
    }

}
