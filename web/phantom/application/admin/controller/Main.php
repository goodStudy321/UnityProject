<?php
namespace app\admin\controller;

use org\Auth;
use think\Controller;
use think\Db;
use think\Session;

class Main extends Controller {

    //初始化
    public function _initialize() {
        $username = session('username');
        if (empty($username))
            $this->redirect('admin/user/login');

        $this->_checkAuth();
        $this->_getMenu();
    }

    /**
     * 权限检查
     * @return bool
     */
    protected function _checkAuth() {
        if (!Session::has('user_id')) {
            $this->redirect('admin/login/index');
        }

        $module     = $this->request->module();
        $controller = $this->request->controller();
        $action     = $this->request->action();
        // 排除权限
        $not_check = ['admin/Index/index','admin/Index/welcome', 'admin/AuthGroup/getjson', 'admin/System/clear'];

        if (!in_array($module . '/' . $controller . '/' . $action, $not_check)) {
            $auth     = new Auth();
            $admin_id = Session::get('user_id');
            if (!$auth->check($module . '/' . $controller . '/' . $action, $admin_id) && $admin_id != 1) {
                $this->error('没有权限','');
            }
        }
    }

    // 获取侧边栏菜单
    protected function _getMenu() {
        $menu           = [];
        $admin_id       = Session::get('user_id');
        $auth           = new Auth();
        $auth_rule_list = Db::name('auth_rule')->where('status', 1)->order(['sort' => 'ASC'])->select();
        foreach ($auth_rule_list as $value) {
            if ($auth->check($value['name'], $admin_id) || $admin_id == 1) {
                $menu[] = $value;
            }
        }
        $menu = !empty($menu) ? array2tree($menu) : [];
        $this->assign('menu', $menu);
    }

    public function returnJson($code, $msg = '', $data = []){
        die(json_encode(['status'=>['code'=>$code,'msg'=>$msg], 'data'=>$data]));
    }

}
