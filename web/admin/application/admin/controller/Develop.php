<?php
namespace app\admin\controller;

use think\Controller;
use think\Db;


class Develop extends Main {

    public $action_config = [];

    public function _initialize(){
        parent::_initialize();
        $this->action_config = [
            [
                'min' => 10000,
                'max' => 19999,
                'name' => '道具获取',
            ],
            [
                'min' => 20000,
                'max' => 29999,
                'name' => '道具失去',
            ],
            [
                'min' => 30000,
                'max' => 39999,
                'name' => '银两获取',
            ],
            [
                'min' => 40000,
                'max' => 49999,
                'name' => '银两失去',
            ],
            [
                'min' => 50000,
                'max' => 59999,
                'name' => '元宝获取',
            ],
            [
                'min' => 60000,
                'max' => 69999,
                'name' => '元宝失去',
            ],
            [
                'min' => 70000,
                'max' => 79999,
                'name' => '积分获取',
            ],
            [
                'min' => 80000,
                'max' => 89999,
                'name' => '积分失去',
            ],
        ];
    }

    //首页
    public function prop(){
        return $this->fetch();
    }

    public function develop_data(){
        $parm = $this->request->param();

        $data = [];
        if(!empty($parm['find'])){
            $map = '';

            if(!empty($parm['role_id'])){
                $map['a.role_id'] = $parm['role_id']; //角色id
            }

            if(!empty($parm['account_name'])){
                $map['b.account_name'] = $parm['account_name']; //条件id
            }

            /*if(!empty($parm['prop_status'])&&$parm['prop_status']!='all'){
                $map['code_status'] = $parm['code_status'];
            }*/

            $res = $this->region_connect
                ->name('role_nurture')
                ->alias('a')
                ->where($map)
                ->join('role_status b','a.role_id = b.role_id')
                ->field("a.*,b.role_name,b.account_name")
                ->select();

            $count = $this->region_connect
                ->name('role_nurture')
                ->alias('a')
                ->where($map)
                ->join('role_status b','a.role_id = b.role_id')
                ->count();

        }else{
            $res = $this->region_connect
                ->name('role_nurture')
                ->alias('a')
                ->join('role_status b','a.role_id = b.role_id')
                ->field("a.*,b.role_name,b.account_name")
                ->limit(($parm['page']-1)*$parm['limit'], $parm['limit'])
                ->select();

            $count = $this->region_connect->name('role_nurture')->count();
        }

        $name = [
            'wing'   => $this->getExcelConfig('excel_wing'),
            'magic'  => $this->getExcelConfig('excel_magic_weapon'),
            'weapon' => $this->getExcelConfig('excel_god_weapon'),
        ];
        foreach ($res as $key=>$val){   //可能会有多个皮肤
            //清空数组
            $weapon_data = array();
            $weapon_star = array();
            $magic_data = array();
            $magic_star = array();
            $wing_data = array();
            $wing_star = array();
            $weapon = explode(',',$val['god_weapon_skins']);
            if(!empty($weapon[0])){
                foreach ($weapon as $kk=>$vv){  //分解多个装备，同时截取星级
                    $weapon_str = substr($vv,0,5);
                    $weapon_data[] =  $name['weapon'][$weapon_str];
                    $weapon_star[] = substr($vv,-1,1);
                }
            }else{
                $weapon_data[0] = '暂无';
                $weapon_star[0] = '暂无';
            }

            $magic = explode(',',$val['magic_weapon_skins']);

            if(!empty($magic[0])){
                foreach ($magic as $kk=>$vv){ //分解多个装备，同时截取星级
                    $magic_str = substr($vv,0,5);
                    $magic_data[] =  $name['magic'][$magic_str];
                    $magic_star[] = substr($vv,-1,1);
                }
            }else{
                $magic_data[0] = '暂无';
                $magic_star[0] = '暂无';
            }

            $wing = explode(',',$val['wing_skins']);
            if(!empty($wing[0])){
                foreach ($wing as $kk=>$vv){ //分解多个装备，同时截取星级
                    $wing_str = substr($vv,0,5);
                    $wing_data[] =  $name['wing'][$wing_str];
                    $wing_star[] = substr($vv,-1,1);
                }
            }else{
                $wing_data[0] = '暂无';
                $wing_star[0] = '暂无';
            }
            
            $data[$key]['id'] = $val['id'];
            $data[$key]['role_name'] = $val['role_name'];
            $data[$key]['account_name'] = $val['account_name'];

            $data[$key]['weapon_name'] = (count($weapon_data)>=2)?implode(',',$weapon_data):$weapon_data[0];

            $data[$key]['weapon_level'] = $val['god_weapon_level'];

            $data[$key]['weapon_star'] = (count($weapon_star)>=2)?implode(',',$weapon_star):$weapon_star[0];

            $data[$key]['wing_name'] = (count($wing_data)>=2)?implode(',',$wing_data):$wing_data[0];

            $data[$key]['wing_level'] = $val['wing_level'];
            $data[$key]['wing_star'] = (count($wing_star)>=2)?implode(',',$wing_star):$wing_star[0];

            $data[$key]['magic_name'] = (count($magic_data)>=2)?implode(',',$magic_data):$magic_data[0];
            $data[$key]['magic_level'] = $val['magic_weapon_level'];

            $data[$key]['magic_star'] = (count($magic_star)>=2)?implode(',',$magic_star):$magic_star[0];

        }

        return ['code' => '0', 'msg' => '', 'count' => $count, 'data' =>$data];
    }

    // 货币消耗
    public function action() {
        $action_type_arr = [
            '10001' => '道具消耗',
            '10002' => '银两消耗',
            '10003' => '元宝/绑元消耗',
            '10004' => '元宝/绑元区服产出消耗'
        ];
        $this->assign('action_type_arr', $action_type_arr);
        return $this->fetch();
    }
    public function action_data() {
        $page = $this->request->param('page', 0, 'int');
        $limit= $this->request->param('limit', 15, 'int');
        $time = $this->request->param('time', '', 'trim');
        $action_type = $this->request->param('action_type', 10001, 'int');
        $option = $this->request->param('option', 1, 'int');
        
        $data = [];
        $where = [];
        // 时间搜索
        if(!empty($time)){
            list($begin, $end) = explode(' - ', $time);
            $begin = strtotime($begin);
            $end   = strtotime($end) + 86400;
            $where['time'] = $where_get['time'] = $where_used['time'] = ['between', "$begin, $end"];

            if($end <= ($begin+86400)) // 时间区间是否同一天
                $time = date('Y-m-d', $begin);

        } elseif (in_array($action_type, [10002, 10003, 10004])) {
            // 当天
            $time = date('Y-m-d',time());
            $begin = strtotime($time);
            $end = $begin+86400;
            $where_get['time'] = $where_used['time'] = ['between', "$begin, $end"];
        }

        if($action_type == 10001 || (in_array($option,[2,3]) && $action_type == 10003)) {
            $prop = $this->getExcelConfig('execel_item');
            foreach ($prop as $key => $value) {
                $prop[$key] = strstr($value, '%%', true);
            }
        }

        switch ($action_type) {
            case '10002':  // 银两
                $role_name = $this->request->param('role_name', '', 'trim');
                if(!empty($role_name)){
                    $map_used['rs.role_name'] = $map_get['rs.role_name'] = ['like', "%$role_name%"];
                }
                $map_used['s.time'] = $map_get['s.time'] = isset($where['time']) ? $where['time'] : $where_get['time'];

                // 银两产出
                $map_get['s.action'] = ['between', '30000,39999'];
                $result_get = $this->region_connect
                    ->name('silver s')
                    ->field('sum(s.silver) as silver,s.role_id,rs.role_name')
                    ->join('role_status rs', 'rs.role_id = s.role_id')
                    ->where($map_get)
                    ->group('s.role_id')
                    ->limit(($page-1)*$limit, $limit)
                    ->select();

                // 银两消耗
                $map_used['s.action'] = ['between', '40000,49999'];
                $result_used = $this->region_connect
                    ->name('silver s')
                    ->field('sum(s.silver) as silver,s.role_id,rs.role_name')
                    ->join('role_status rs', 'rs.role_id = s.role_id')
                    ->where($map_used)
                    ->group('s.role_id')
                    ->limit(($page-1)*$limit, $limit)
                    ->select();
                
                foreach ($result_get as $k => $val) {
                    // 角色名
                    $data[$val['role_id']]['role_name'] = $val['role_name'];
                    // 银两产出
                    $data[$val['role_id']]['silver_get'] = $val['silver'];
                    // 银两消耗
                    $data[$val['role_id']]['silver_used'] = 0;
                    foreach ($result_used as $key => $value) {
                        if($val['role_id'] == $value['role_id']){
                            $data[$val['role_id']]['silver_used'] = $value['silver'];
                        }
                    }
                    // 比例
                    @$data[$val['role_id']]['silver_ratio'] = $data[$val['role_id']]['silver_get'] == 0 ? percentage(0) : percentage($data[$val['role_id']]['silver_used'] / $data[$val['role_id']]['silver_get']);;
                    // 日期
                    $data[$val['role_id']]['time'] = $time;
                } 

                $count = $this->region_connect
                    ->name('silver s')
                    ->field('s.role_id')
                    ->join('role_status rs', 'rs.role_id = s.role_id')
                    ->where($map_get)
                    ->group('s.role_id')
                    ->count();
                break;
            case '10003':  // 元宝/绑元
                $total = 0;

                switch ($option) {
                    case '2': // 元宝商城
                        $where_used['asset_type'] = 2;
                        break;
                    case '3': // 绑元商城
                        $where_used['asset_type'] = 3; 
                        break;
                    default: // 各时间段消费比例  两天一页
                        $page_num = ceil(($end-$begin) / 172800); // 总页数
                        $time_quantum['action'] = ['between', '60000,69999'];
                        if($page_num > 1){
                            for ($i=0; $i < $page_num; $i++) { 
                                $time_begin = $begin + ($i * 172800);
                                $time_end = $time_begin + 172800;
                                $search_time[$i] = [
                                    'where'      => ['between', "$time_begin,$time_end"],
                                    'time_begin' => $time_begin,
                                    'time_end'   => $time_end
                                ];
                            }

                            $time_quantum['time'] = $search_time[$page-1]['where'];
                        } else {
                            $time_quantum['time'] = $where_used['time'];
                        }

                        $now = time();
                        if(($end - $begin) <= 86400){
                            // 一天
                            $count = $num = ($begin < $now && $end > $now) ? date('G', time()) + 1 : 24; // 数据总条数
                        } else {
                            // 多天
                            $count = ($begin < $now && $end > $now) ? (floor((($end-$begin) / 86400) - 1) * 24) + (date('G', time()) + 1) : $page_num * 48; // 数据总条数
                                
                            // 是否最后一页数据：
                            $num = $page == $page_num ? $count - (($page - 1) * 48) : 48; 
                        }
                        for ($i=0; $i < $num; $i++) {                                 
                            // 时间
                            $data[date('m-d-G',($begin+($i*3600)+(($page-1)*172800)))]['hour'] = date('G', ($begin+($i*3600)+(($page-1)*172800)));
                            // 日期
                            $data[date('m-d-G',($begin+($i*3600)+(($page-1)*172800)))]['time'] = date('Y-m-d', ($begin+($i*3600)+(($page-1)*172800)));
                            // 元宝充值数
                            $data[date('m-d-G',($begin+($i*3600)+(($page-1)*172800)))]['recharge'] = '--';
                            // 元宝充值人数
                            $data[date('m-d-G',($begin+($i*3600)+(($page-1)*172800)))]['recharge_people_num'] = '--';
                            // 元宝充值人数比
                            $data[date('m-d-G',($begin+($i*3600)+(($page-1)*172800)))]['recharge_people_num_ratio'] = '--';
                            // 元宝消耗数
                            $data[date('m-d-G',($begin+($i*3600)+(($page-1)*172800)))]['gold_used'] = [];
                            // 元宝消耗人数
                            $data[date('m-d-G',($begin+($i*3600)+(($page-1)*172800)))]['gold_used_people_num'] = [];
                            // 元宝消耗人数比
                            $data[date('m-d-G',($begin+($i*3600)+(($page-1)*172800)))]['gold_used_people_num_ratio'] =0;
                            // 绑定元宝消耗数
                            $data[date('m-d-G',($begin+($i*3600)+(($page-1)*172800)))]['bind_gold_used'] = [];
                            // 绑定元宝消耗人数
                            $data[date('m-d-G',($begin+($i*3600)+(($page-1)*172800)))]['bind_gold_used_people_num'] = [];
                            // 绑定元宝消耗人数比
                            $data[date('m-d-G',($begin+($i*3600)+(($page-1)*172800)))]['bind_gold_used_people_num_ratio'] = 0;
                        }

                        $result = $this->region_connect
                            ->name('gold')
                            ->where($time_quantum)
                            ->select();
                        // 消耗元宝总人数
                        $time_quantum['gold'] = ['>', 0];
                        $gold_people = $this->region_connect->name('gold')->where($time_quantum)->group('role_id')->count();
                        // 消耗绑定元宝总人数
                        unset($time_quantum['gold']);
                        $time_quantum['bind_gold'] = ['>', 0];
                        $bind_gold_people = $this->region_connect->name('gold')->where($time_quantum)->group('role_id')->count();

                        
                        // 初始数据
                        foreach ($result as $key => $value) {
                            // 元宝充值数
                            // $data[date('m-d-G', $value['time'])]['recharge'] = 0;
                            // 元宝充值人数
                            // $data[date('m-d-G', $value['time'])]['recharge_people_num'] = 0;
                            // 元宝充值人数比
                            // $data[date('m-d-G', $value['time'])]['recharge_people_num_ratio'] = 0;
                            if($value['gold'] > 0){
                                // 元宝消耗数
                                $data[date('m-d-G', $value['time'])]['gold_used'][] = $value['gold'];
                                // 元宝消耗人数
                                $data[date('m-d-G', $value['time'])]['gold_used_people_num'][$value['role_id']] = $value['role_id'];
                            }
                            if($value['bind_gold'] > 0){
                                // 绑定元宝消耗数
                                $data[date('m-d-G', $value['time'])]['bind_gold_used'][] = $value['bind_gold'];
                                // 绑定元宝消耗人数
                                $data[date('m-d-G', $value['time'])]['bind_gold_used_people_num'][$value['role_id']] = $value['role_id'];
                            }
                        }
                        
                        foreach ($data as &$v) {
                            // 元宝消耗数
                            $v['gold_used'] = array_sum($v['gold_used']);
                            // 元宝消耗人数
                            $v['gold_used_people_num'] = count(array_filter($v['gold_used_people_num']));
                            // 元宝消耗人数比
                            $v['gold_used_people_num_ratio'] = empty($gold_people) ? percentage(0) : percentage($v['gold_used_people_num'] / $gold_people);
                            // 绑定元宝消耗数
                            $v['bind_gold_used'] = array_sum($v['bind_gold_used']);
                            // 绑定元宝消耗人数
                            $v['bind_gold_used_people_num'] = count(array_filter($v['bind_gold_used_people_num']));
                            // 绑定元宝消耗人数比
                            $v['bind_gold_used_people_num_ratio'] = empty($bind_gold_people) ? percentage(0) : percentage($v['bind_gold_used_people_num'] / $bind_gold_people);;
                        }
                        break;
                }
                // 元宝商城、绑元商城
                if(in_array($option,[2,3])){
                    $result = $this->region_connect
                        ->name('shop')
                        ->field('type_id,sum(buy_num) as num,sum(asset_value) as gold,sum(asset_bind_value) as bind_gold')
                        ->where($where_used)
                        ->group('type_id')
                        ->limit(($page-1)*$limit, $limit)
                        ->select();
                    $count = $this->region_connect
                        ->name('shop')
                        ->where($where_used)
                        ->group('type_id')
                        ->count();
                    
                    $where_used['type_id'] = '';
                    foreach ($result as $key => $value) {
                        $where_used['type_id'] .= ','.$value['type_id'];
                        // 道具名
                        $data[$value['type_id']]['title'] = isset($prop[$value['type_id']]) ? strstr($prop[$value['type_id']], '%%', true).'(ID:'.$value['type_id'].')' : '--';
                        // 消耗元宝
                        $data[$value['type_id']]['gold'] = $value['gold'];
                        // 消耗元宝总量
                        $total += $value['gold'];
                        // 购买数量
                        $data[$value['type_id']]['num'] = $value['num'];
                        // 购买人数
                        $data[$value['type_id']]['people_num'] = 0;
                        // 时间
                        $data[$value['type_id']]['time'] = $time;
                        if($option == 3){
                            // 消耗绑定元宝
                            $data[$value['type_id']]['bind_gold'] = $value['bind_gold'];
                        }
                    }

                    $where_used['type_id'] = ['in' ,trim($where_used['type_id'], ',')];
                    // 购买人数
                    $result_poeple = $this->region_connect
                        ->name('shop')
                        ->field('type_id,role_id')
                        ->where($where_used)
                        ->group('type_id,role_id')
                        ->select();
                    // 购买总人数
                    $people_total = count($result_poeple);
                    foreach ($result_poeple as $key => $value) {
                        $data[$value['type_id']]['people_num'] += 1; 
                        // 消耗比例
                        @$data[$value['type_id']]['uesd_ratio'] = percentage($data[$value['type_id']]['gold'] / $total);
                        if($option == 3){                        
                            // 购买人数比例
                            @$data[$value['type_id']]['people_ratio'] = percentage($data[$value['type_id']]['people_num'] / $people_total);
                        }
                    }    
                }

                break;
            case '10004':  // 元宝/绑元产出消耗汇总
                $where_get['action'] = ['between', '50000,59999'];
                $where_used['action'] = ['between', '60000,69999'];
                // 区服信息
                $server_data = DB::name('config')->field('server_id,title_name')->select();
                
                // 元宝、绑元产出数据
                $result_get = $this->region_connect
                    ->name('gold')
                    ->field('SUM(gold) as gold,SUM(bind_gold) as bind_gold,server_id')
                    ->where($where_get)
                    ->group('server_id')
                    ->limit(($page - 1) * $limit, $limit)
                    ->select();
                // 元宝、绑元消耗数据
                $result_used = $this->region_connect
                    ->name('gold')
                    ->field('SUM(gold) as gold,SUM(bind_gold) as bind_gold,server_id')
                    ->where($where_used)
                    ->group('server_id')
                    ->limit(($page - 1) * $limit, $limit)
                    ->select();

                foreach ($server_data as $k => $val) {
                    $data[$val['server_id']]['server_name'] = isset($data[$val['server_id']]['server_name']) ? $data[$val['server_id']]['server_name'].' & '.$val['title_name'] : $val['title_name'];
                    // 产出
                    foreach ($result_get as $key => $value) {
                        if($value['server_id'] == $val['server_id']){                        
                            // 元宝产出
                            $data[$val['server_id']]['gold_get'] = isset($value['gold']) ? $value['gold'] : '--';
                            // 绑定元宝产出
                            $data[$val['server_id']]['bind_gold_get'] = isset($value['bind_gold']) ? $value['bind_gold'] : '--';
                        }
                    }
                    // 消耗
                    foreach ($result_used as $key => $value) {
                        if($value['server_id'] == $val['server_id']){   
                            // 元宝消耗
                            $data[$val['server_id']]['gold_used'] = isset($value['gold']) ? $value['gold'] : '--';
                            // 绑定元宝消耗
                            $data[$val['server_id']]['bind_gold_used'] = isset($value['bind_gold']) ? $value['bind_gold'] : '--';
                        }
                    }
                    // 比例
                    @$data[$val['server_id']]['gold_ratio'] = $data[$val['server_id']]['gold_get'] == 0 ? percentage(0) : percentage($data[$val['server_id']]['gold_used'] / $data[$val['server_id']]['gold_get']);
                    @$data[$val['server_id']]['bind_gold_ratio'] = $data[$val['server_id']]['bind_gold_get'] == 0 ? percentage(0) : percentage($data[$val['server_id']]['bind_gold_used'] / $data[$val['server_id']]['bind_gold_get']);;
                    // 产出、消耗为空，以‘--’显示
                    if(empty($data[$val['server_id']]['gold_get']))
                        $data[$val['server_id']]['gold_get'] = '--';
                    if(empty($data[$val['server_id']]['bind_gold_get']))
                        $data[$val['server_id']]['bind_gold_get'] = '--';
                    if(empty($data[$val['server_id']]['gold_used']))
                        $data[$val['server_id']]['gold_used'] = '--';
                    if(empty($data[$val['server_id']]['bind_gold_used']))
                        $data[$val['server_id']]['bind_gold_used'] = '--';
                    // 日期
                    $data[$val['server_id']]['time'] = $time;
                }
                
                $count = count($data);
                break;
            
            default:  // 道具
                $item = $this->request->param('item', '', 'trim');
                if(!empty($item)){
                    if(is_numeric($item)){
                        $where['type_id'] = ['like', '"%'.$item.'%"'];
                    } else {
                        $where['type_id'] = ['in', implode(',' ,array_keys($prop, $item))];
                    }
                }
                $where['action'] = ['between', '10000,19999'];
                
                // 道具的产出
                $result_get = $this->region_connect
                    ->name('item')
                    ->field('type_id,sum(num) as num')
                    ->where($where)
                    ->group('type_id')
                    ->limit(($page - 1) * $limit, $limit)
                    ->select();
                $count = $this->region_connect
                    ->name('item')
                    ->where($where)
                    ->group('type_id')
                    ->count();
                $type_id = '';
                foreach ($result_get as $key => $value) {
                    $type_id .= ','.$value['type_id'];
                    // 道具名
                    $data[$value['type_id']]['action_name'] = isset($prop[$value['type_id']]) ? $prop[$value['type_id']].'(ID:'.$value['type_id'].')' : '--';
                    // 道具产出
                    $data[$value['type_id']]['action_get'] = $value['num'];
                    // 道具消耗
                    $data[$value['type_id']]['action_used'] = 0;
                }

                $type_id = trim($type_id, ',');
                $where['type_id'] = ['in', "$type_id"];
                $where['action'] = ['between', '20000,29999'];
                // 相应产出的道具的消耗
                $result_used = $this->region_connect
                    ->name('item')
                    ->field('type_id,sum(num) as num')
                    ->where($where)
                    ->group('type_id')
                    ->select(); 

                foreach ($data as $key => $value) {
                    foreach ($result_used as $k => $val) {
                        if($val['type_id'] == $key){
                            // 道具消耗
                            $data[$key]['action_used'] = $val['num'];
                        }
                    }
                    // 产出消耗比
                    @$data[$key]['ratio'] = $data[$key]['action_get'] == 0 ? percentage(0) : percentage($data[$key]['action_used'] / $data[$key]['action_get']);
                }
                
                
                break;
        }

        return ['code' => 0, 'msg' => '', 'count' => $count, 'data' => $data];
    }


    // 资源消耗榜
    public function resource_consumption() {
        $excel_total = $this->request->param('excel_total', '', 'int'); // 2:导出数据
        $time        = $this->request->param('time', '', 'trim');
        $channel_type= $this->request->param('channel', '', 'trim'); // 渠道
        $type        = $this->request->param('type', 1, 'int'); // 1:元宝；2：绑元；3：金币
        $page        = $this->request->param('page', 1, 'int');
        $limit       = $excel_total > 0 ? 0 : $this->request->param('limit', 15, 'int');

        // 模板输出
        $channel = DB::name('channel')->select();
        foreach ($channel as $key => $val) {
            $channel_data[$val['channel_id']]['channel_id'] = $val['channel_id'];
            $channel_data[$val['channel_id']]['name'] = $val['name'];
        }
        
        if(!$this->request->isAjax() && $excel_total <= 0){
            // 渠道(查询条件)
            $this->assign('channel_data', $channel_data);
            $this->assign('excel_url', '/admin/develop/resource_consumption?&excel_total=2');
            return $this->fetch();
        }

        $where = [];
        $table = '';
        $order = 'num desc,role_id asc';
        $field = 'rs.role_id,rs.role_name,rs.role_level,rs.role_vip_level,rs.power,p.channel_id';
        $join[]  = ['role_status rs', 'rs.role_id = p.role_id'];
        if(!empty($time)){
            list($begin, $end) = explode(' - ', $time);
            $begin = strtotime($begin);
            $end   = strtotime($end)+86400;
            $where['p.time'] = ['between', "$begin,$end"];
        }
        if(is_numeric($channel_type)) {
            $where['p.channel_id'] = $channel_type;
        }
        
        switch ($type) {
            case '2': // 绑元
                $name = '(绑定元宝)';
                $table = 'gold';
                $field .= ',SUM(p.bind_gold) as num';
                $where['p.action'] = ['between', '60000,69999'];
                break;
            case '3': // 金币
                $name = '(金币)';
                $table = 'silver';
                $field .= ',SUM(p.silver) as num';
                $where['p.action'] = ['between', '40000,49999'];
                break;            
            default: // 元宝
                $name = '(元宝)';
                $table = 'gold';
                $field .= ',SUM(p.gold) as num';
                $where['p.action'] = ['between', '60000,69999'];
                break;
        }
        
        $result = $this->region_connect
            ->name($table . ' p')
            ->field($field)
            ->join($join)
            ->where($where)
            ->order($order)
            ->group('p.channel_id,p.role_id')
            ->limit(($page-1)*$limit, $limit)
            ->select();
        
        // 数据整理
        $data = [];
        foreach ($result as $key => $value) {
            $data[$key]['id']             = $key+ 1;
            $data[$key]['role_name']      = $value['role_name'];
            $data[$key]['role_vip_level'] = $value['role_vip_level'];
            $data[$key]['role_level']     = $value['role_level'];
            $data[$key]['power']          = $value['power'];
            $data[$key]['num']            = $value['num'];
            $data[$key]['channel_name']   = isset($channel_data[$value['channel_id']]['name']) ? $channel_data[$value['channel_id']]['name'] : '--';
        }
        $count = $this->region_connect
            ->name($table . ' p')
            ->join($join)
            ->where($where)
            ->group('p.role_id')
            ->count();
        
        
        // 导出数据
        if($excel_total > 1){
            $data = array_merge([['序号','角色名','vip等级','角色等级','战力','消耗量(降序)','渠道']], $data);
            $excel_header = [
                ['A',20],
                ['B',20],
                ['C',10],
                ['D',10],
                ['E',10],
                ['F',10],
                ['G',10],
            ];
            exportExcel($data, $excel_header, '资源消耗榜'.$name);
        }

        return ['code' => '0', 'msg' => '', 'count' => $count, 'data' =>$data];
    }
}
