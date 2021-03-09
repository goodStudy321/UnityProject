<?php
namespace app\admin\controller;

use think\Db;

class Other extends Main {

    public function index() {
        $list = [
            ['name'=>'注册开关', 'url'=>'/admin/other/register?html=1'],
            ['name'=>'技术埋点数据 - 导出数据', 'url'=>'/admin/other/buried'],
            ['name'=>'沉迷设置', 'url'=>'/admin/other/indulge'],
        ];

        $this->assign('list', $list);
        return $this->fetch();
    }

    // 技术埋点数据 - 导出数据
    public function buried() {
        $type = $this->request->param('type', 0, 'int');
        if($type <= 0){
            echo $this->fetch();
            die;
        }

        $type_arr = [
            1 => ['机型首次打开','first_open'],
            2 => ['机型注册','model_register'],
            3 => ['账号注册','account_register'],
            4 => ['账号登录登出','account_login_logout'],
            5 => ['区账号注册','serverid_register'],
            6 => ['区账号登录登出','serverid_login_logout'],
            7 => ['客户端异常','client_error'],
            8 => ['补丁相关','patch'],
            9 => ['角色注册','role_register'],
        ];

        if(!isset($type_arr[$type]))
            return $this->fetch();

        list($name,$table) = $type_arr[$type];
        $game_logs = config('database.game_logs');
        $prefix    = $game_logs['prefix'];

        $model = Db::connect($game_logs)->name($table);

        //取出表注释作为Excel title
        $columns = Db::query("SELECT COLUMN_NAME,COLUMN_COMMENT FROM information_schema.columns WHERE table_name = '".$prefix.$table."'");
        $columns = array_filter(array_column($columns, 'COLUMN_COMMENT', 'COLUMN_NAME'));
        $titles  = array_values($columns);
        $fileds  = implode(',', array_keys($columns));

        //取出数据
        $data = $model->field($fileds)->select();
        foreach($data as &$value){
            foreach($value as $k=>$v){
                if(strpos($k, 'time') !== false)
                    $value[$k] = $v ? date('Y-m-d H:i:s', $v) : '--';
            }
        }
        unset($value);

        $data = array_merge([$titles], $data);
        $excel_header = [
            ['A',20], ['B',20], ['C',20], ['D',20], ['E',20], ['F',20], ['G',20], ['H',20], ['I',20], ['J',20], ['K',20], ['L',20], ['M',20], ['N',20], ['O',20], ['P',20], ['Q',20], ['R',20], ['S',20], ['T',20], ['U',20], ['V',20], ['W',20], ['X',20], ['Y',20], ['Z',20],
            ['AA',20], ['AB',20], ['AC',20], ['AD',20], ['AE',20], ['AF',20], ['AG',20], ['AH',20], ['AI',20], ['AJ',20], ['AK',20], ['AL',20], ['AM',20], ['AN',20], ['AO',20], ['AP',20], ['AQ',20], ['AR',20], ['AS',20], ['AT',20], ['AU',20], ['AV',20], ['AW',20], ['AX',20], ['AY',20], ['AZ',20],
        ];
        exportExcel($data, $excel_header, $name);
    }

    //注册开关
    public function register() {
        $type    = $this->request->param('type', 1, 'int');
        $is_open = $this->request->param('is_open', 0, 'int');
        $html    = $this->request->param('html', 0, 'int');

        $param = [
            'time'    => time(),
            'ticket'  => md5(time(). config('erlang_salt')),
            'action'  => 'auth_switch',
            'type'    => max(1, $type),
        ];
        if($param['type'] == 2)
            $param['is_open'] = $is_open;

        $url = $this->message_send_to_url . '/?' . http_build_query($param);
        $result = curl($url);

        //输出html
        if($html == 1){
            $this->assign('register_status', $result['data']);
            echo $this->fetch();
            die;
        }

        //for ajax
        if(!empty($result) && $result['ret'] == 1)
            $this->returnJson(10200, '', $result);
        else
            $this->returnJson(10400);
    }

    // 沉迷设置
    public function indulge()
    {
        // 数据表是否已经有数据
        $param = DB::name('setting')->where('key', 'indulge')->find();

        if($this->request->isPost()) {
            $data = $this->request->post();
            
            //数据校验
            $arr = [
                'X' => $data['time']['X'],
                'Y' => $data['time']['Y'],
                'M' => $data['time']['M'],
                'N' => $data['time']['N'],
            ];
            //选项1
            if(isset($data['indulge']['option1'])){
                foreach ($arr as $key => $val) {
                    if(empty($val)){
                        $this->returnJson(10404, $key.'值不能为空!');
                    }
                }
            } else {
                $data['indulge']['option1'] = 'off';
            }
            // 选项2
            if(isset($data['indulge']['option2'])){
                foreach ($arr as $key => $val) {
                    if(($key == 'X' || $key == 'Y') && empty($val)){
                        $this->returnJson(10404, $key.'值不能为空!');
                    }
                }
            } else {
                $data['indulge']['option2'] = 'off';
            }
            // 选项3
            if(isset($data['indulge']['option3'])){
                // Z值是否为空
                if(empty($data['Z'])){
                    $this->returnJson(10404, 'Z值不能为空！');
                }
            } else {
                $data['indulge']['option3'] = 'off';
            }

            // 提交
            $map = [
                'name'      => '沉迷设置', 
                'key'       => 'indulge',
                'value'     =>  json_encode($data),
                'add_time'  => date('Y-m-d H:i:s', time()),
            ];
            
            if(!empty($param)) {
                // 修改数据 
                DB::name('setting')->where('id', $param['id'])->update($map);
            } else {
                // 添加数据
                DB::name('setting')->insert($map);
            }
            
            $this->returnJson(10200, '修改成功！');

        } else {
            // 展示页面
            if(!empty($param)) {
                $value = json_decode($param['value'], true);
                $this->assign('data', $value);
            }

            echo $this->fetch();
            die;
        }
    }
}
