<?php
namespace app\admin\controller;

use think\Db;
use think\Log;

class Other extends Main {

    public function index() {
        $list = [
            ['name'=>'注册开关', 'url'=>'/admin/other/register?html=1'],
            ['name'=>'技术埋点数据 - 导出数据', 'url'=>'/admin/other/buried'],
            ['name'=>'沉迷设置', 'url'=>'/admin/other/indulge'],
            ['name'=>'临时数据导出', 'url'=>'/admin/other/temporary']
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
        for ($i=0; $i < count($titles); $i++) { 
            // 在UID后添加 用户等级 列
            if($titles[$i] == 'UID'){
                $index = $i+1;
                array_splice($titles, $index, 0, ['用户等级']);
                break;
            }
        }

        //取出数据
        $data = $model->field($fileds)->select();
        $databases = [
            'admin_junhai_1',
            'admin_junhai_2',
            'admin_junhai_3',
            'admin_junhai_4',
            // 'admin_local_1',
        ];
        $role_level_all = [];
        foreach ($databases as $key => $value) {
            $database_config = [
                // 'hostname' => '192.168.2.250',
                'hostname' => '115.159.68.105',
                'database' => $value,
                'type'     => 'mysql',
                'username' => 'datauser',
                'password' => 'mfpmaLSTAfwQJ13mBoSFDc4m0bmfCQgd',
                'hostport' => '3306',
                'charset'  => 'utf8',
                'prefix'   => 'log_',
            ];
            $role_level = DB::connect($database_config)->name('role_status')->column('uid,role_level');
            $role_level_all += $role_level;
        }

        foreach($data as $key => &$value){
            foreach($value as $k=>$v){
                if(strpos($k, 'time') !== false){
                    $value[$k] = $v ? date('Y-m-d H:i:s', $v) : '--';
                }
            }
            if(isset($value['uid'])){
                if(isset($role_level_all[$value['uid']])){
                    array_splice($data[$key], $index, 0, ['role_level' => $role_level_all[$value['uid']]]);
                }else{
                    array_splice($data[$key], $index, 0, ['role_level' => '0']);
                }
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
    public function indulge(){
        // 数据表是否已经有数据
        $param = DB::name('setting')->where('key', 'indulge')->find();

        if($this->request->isPost()) {
            $data = [];
            $parm = $this->request->post();
            // printr($parm);
            $data[0]['status'] = 'off'; // 无要求
            $data[0]['name']   = '无要求';
            $data[1]['status'] = 'off'; // 宽松版
            $data[1]['name']   = '宽松版';
            $data[2]['status'] = 'off'; // 严格版
            $data[2]['name']   = '严格版';            
            // 使用哪个版本
            if(!empty($parm['status'])){
                $status = $parm['status']-1;
                $data[$status]['status'] = 'on';
            }else{
                $this->returnJson(10400, '请选择防沉迷版本');
            }

            // 宽松版时间
            if($data[1]['status'] == 'on'){
                if(empty($parm['time']['status1'])){
                    $this->returnJson(10404, '宽松版时间值不能为空');
                }
            }
            $data[1]['time'] = $parm['time']['status1'];
            

            // 严格版数据
            //数据校验
            $data[2]['time'] = [
                'X' => $parm['time']['X'],
                'Y' => $parm['time']['Y'],
                'M' => $parm['time']['M'],
                'N' => $parm['time']['N'],
            ];
            //选项1
            if(isset($parm['indulge']['option1'])){
                foreach ($data[2]['time'] as $key => $val) {
                    if(is_null($val) && $data[2]['status'] == 'on'){
                        $this->returnJson(10404, $key.'值不能为空!');
                    }
                }
                $data[2]['indulge']['option1'] = 'on';
            } else {
                $data[2]['indulge']['option1'] = 'off';
            }
            // 选项2
            if(isset($parm['indulge']['option2'])){
                foreach ($data[2]['time'] as $key => $val) {
                    if(($key == 'X' || $key == 'Y') && is_null($val) && $data[2]['status'] == 'on'){
                        $this->returnJson(10404, $key.'值不能为空!');
                    }
                }
                $data[2]['indulge']['option2'] = 'on';
            } else {
                $data[2]['indulge']['option2'] = 'off';
            }
            // 选项3
            if(isset($parm['indulge']['option3'])){
                // Z值是否为空
                if(is_null($parm['Z']) && $data[2]['status'] == 'on'){
                    $this->returnJson(10404, 'Z值不能为空！');
                }
                $data[2]['indulge']['option3'] = 'on';
                $data[2]['Z'] = $parm['Z'];
            } else {
                $data[2]['indulge']['option3'] = 'off';
            }
            
            // 提交
            $map = [
                'name'      => '沉迷设置', 
                'key'       => 'indulge',
                'value'     => json_encode($data),
                'add_time'  => date('Y-m-d H:i:s', time()),
            ];
            
            if(!empty($param)) {
                // 修改数据 
                $res = DB::name('setting')->where('id', $param['id'])->update($map);
            } else {
                // 添加数据
                DB::name('setting')->insert($map);
                $res = DB::name('setting')->getLastInsID();
            }
            if($res > 0){
                $time = time();
                $ticket = md5($time. config('erlang_salt'));
                $url = $this->message_send_to_url . "/?ticket=$ticket&action=set_addict_state&status=$status&time=$time";
                Log::write($url, 'debug:indulge');

                $curl = curl_init();
                curl_setopt($curl, CURLOPT_URL, $url);
                curl_setopt($curl, CURLOPT_HEADER, 0);
                curl_setopt($curl, CURLOPT_RETURNTRANSFER, 1);
                $data = curl_exec($curl);
                curl_close($curl);

                //显示获得的数据
                $ret = json_decode($data,true);
                if(!empty($ret) && $ret['ret'] == 1){
                    $this->returnJson(10200, '修改成功！');
                } else {
                    DB::name('setting')->where('id', $param['id'])->update($param);
                    $this->returnJson(10500, '修改失败！');
                }
            }

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

    // 临时数据导出
    public function temporary(){
        echo $this->fetch();
        die;
    }
}
