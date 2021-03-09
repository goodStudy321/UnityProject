<?php
namespace app\admin\controller;

use org\Auth;
use think\Controller;
use think\Db;
use think\Session;


class Main extends Controller {

    public $message_send_to_url;
    public $region_connect; //区服数据库连接

    //初始化
    public function _initialize() {
        $username  = session('username');
        if (empty($username)) {
            $this->redirect('admin/user/login');
        }

        //切换服务器数据库
        $config = session('data_server');
        if(empty($config)){
            $config = Db::name('config')->limit(1)->select();
            $config = reset($config);
            session('data_server', $config);
        }
        $config_title              = json_decode($config['title'], true);
        $database_config           = $config_title['mysql'] + config('database.datauser');
        $this->message_send_to_url = $config_title['other']['send_to_url'];
        $this->region_connect      = Db::connect($database_config);

        $this->assign('servers', Db::name('config')->order('id desc')->column('id,title_name')); //所有服务器
        $this->assign('config_server', $config);

        //其他
        $this->checkAuth();
        $this->getMenu();

    }
    /**
     * 权限检查
     * @return bool
     */
    protected function checkAuth() {
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
    
    /**
     * 获取侧边栏菜单
     */
    protected function getMenu()
    {
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

    //从excel中获取数据
    public function getExcelConfig($file_name){
        if($file_name == '')
            return [];

        $str = @file_get_contents(__DIR__."/config/$file_name.php");
        if(trim($str) == '')
            return [];


        $data = [];
        $arr = explode('||',$str);
        unset($arr[count($arr)-1]);
        foreach ($arr as $key=>$val){
            $_val = explode("=",$val);
            $data[trim($_val[0])] =$_val[1];
        }

        return $data;
    }

    public function getSetting($key){
        if($key == '')
            return '';

        $data = cache('setting');
        if(empty($data)){
            $data = (new app\admin\model\Setting())->order('id DESC')->column('id,name,value,key');
            $data = array_column($data, null, 'key');
            cache('setting', $data);
        }

        return isset($data[$key]) ? $data[$key]['value'] : '';
    }

    public function returnJson($code, $msg = '', $data = []){
        die(json_encode(['status'=>['code'=>$code,'msg'=>$msg], 'data'=>$data]));
    }

}
