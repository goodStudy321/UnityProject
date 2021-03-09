<?php
namespace app\admin\controller;

use org\Auth;
use think\Controller;
use think\Db;
use think\Session;
use app\admin\model\Elasticsearch;

class Main extends Controller {

    public $message_send_to_url;
    public $filter; //区服数据库连接
    public $central_connect; //中央数据服务连接

    //初始化
    public function _initialize() {
        $username = session('username');
        if (empty($username))
            $this->redirect('admin/user/login');

        $this->_checkAuth();
        $this->_getMenu();
        $this->_makeFilter();

        //总数据中心数据库连接
        //$this->central_connect = DB::connect( config('database.central') );
        $this->central_connect = new Elasticsearch();

        $this->assign('export_url', '');
    }

    //生成所有的条件筛选项缓存起来
    protected function _makeFilter(){
        $filter = cache('filter');
        $clean  = $this->request->param('clean', '0', 'int');
        if(empty($filter) || $clean == 1){
             $admin_connect  = DB::connect( config('database.last_admin') );

            //1. 区服
            $database = $admin_connect->name('config')->select();
            $arr = [];
            foreach($database as $v){
                $title = (array)json_decode($v['title']);
                $title = (array)$title['mysql'];
                $arr[] = [
                    'server_id'  => $v['server_id'],
                    'hostname'   => $title['hostname'],
                    'database'   => $title['database'],
                    'title_name' => $v['title_name'],
                ];
            }

            //2. 渠道
            $channel = $admin_connect->name('channel')->column('id,channel_id,name');
            //3. 包渠道
            $channel_game = $admin_connect->name('channel_game')->column('id,channel_id,game_channel_id,name');
            $game = [];
            foreach($channel_game as $v)
                $game[$v['channel_id']][] = $v;

            //组装
            $filter = [
                'database'     => $arr,
                'channel'      => $channel,
                'channel_game' => $game,
            ];
            

            cache('filter', $filter);
        }

        $this->assign('filter', $filter);
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

    public function getFilterValue(){
        $filter = $this->request->param();
        $filter = array_filter([
            'server_id'       => isset($filter['server']) ? array_keys($filter['server']) : [],
            'channel_id'      => isset($filter['channel']) ? array_keys($filter['channel']) : [],
            'game_channel_id' => isset($filter['game_channel']) ? array_keys($filter['game_channel']) : [],
        ]);
        if(empty($filter))
            return [];

        $filter = array_map(function($v){
            if($v[0] === 'all')
                return [];

            return  $v;
        }, $filter);

        return array_filter($filter);
    }

}
