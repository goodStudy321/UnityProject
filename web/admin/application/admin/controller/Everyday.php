<?php
namespace app\admin\controller;

use think\Controller;
use think\Db;
use think\Log;
use think\Session;
use think\Validate;

class Everyday extends Main {

    //活跃统计
    public function active(){
        $res = $this->region_connect
            ->name('role_create')
            ->count();
        $this->assign('create',$res);
        return $this->fetch();
    }
    // 活跃玩家
    public function active_table_gamer(){
        $parm = $this->request->param();

        $one_day_times = 86400;
        $limit = $parm['limit'];
        $page  = $parm['page'];
        $data  = [];
        $count = 0;
        $now   = date('Y-m-d', time());

        $time = $this->request->param('time', '', 'trim');
        list($search_begin_time, $search_end_time) = $time ? explode(' - ', $time) : ['', ''];

        //1. 计算总页(按角色创建日期)
        $first_day_org = $this->region_connect->name('role_create')->order('time asc')->limit(1)->value('time');
        $first_day_org = $first_day_org > 0 ? $first_day_org : time();
        $first_day_org = (!empty($search_begin_time) && $search_begin_time > strtotime($now)) ? strtotime($search_begin_time) : $first_day_org;
        $first_day     = date('Y-m-d', $first_day_org);
        $count         = (strtotime($now) - strtotime($first_day)) / $one_day_times +1;

        //2. 循环日期取数据
        for($i=0; $i<$limit; $i++){
            $base_time = !empty($search_end_time) ? strtotime($search_end_time) : time();
            $base_time = strtotime(date('Y-m-d',$base_time));
            $before    = $i+(($page-1)*$limit);

            //当天的时间戳范围
            $day_begin_time = strtotime("-$before day", $base_time);
            $day_end_time   = $day_begin_time + $one_day_times;

            if($day_end_time < $first_day_org || $day_end_time <= strtotime($search_begin_time))
                break;

            // 活跃玩家
            $active_numbers = $this->region_connect //当天活跃账号，角色
                ->name('role_login')
                ->field('count(distinct(role_id)) as role_num, count(distinct(account_name)) as account_num')
                ->where("time>=$day_begin_time AND time<$day_end_time")
                ->find();
            Log::write($this->region_connect->getLastSql(), 'debug:active_table_gamer');
            $active_numbers['imei_num'] = $this->region_connect // 当天活跃设备
                ->name('role_login')
                ->where("time>=$day_begin_time AND time<$day_end_time")
                ->where("imei <> '' and imei <> 'unknown'")
                ->group('imei')
                ->count();

            // 新增玩家
            $new_numbers = $this->region_connect //当天新增账号角色数
                ->name('role_create')
                ->field('count(distinct(role_id)) as role_num, count(distinct(account_name)) as account_num')
                ->where("time>=$day_begin_time AND time<$day_end_time")
                ->find();
            Log::write($this->region_connect->getLastSql(), 'debug:active_table_gamer');
            $create_imei = $this->region_connect //当天新增数设备
                ->name('role_create')
                ->where("time>=$day_begin_time AND time<$day_end_time")
                ->where("imei <> '' and imei <> 'unknown'")
                ->group('imei')
                ->count();
            $login_imei = $this->region_connect //当天登录
                ->name('role_login')
                ->where("time>=$day_begin_time AND time<$day_end_time")
                ->group('imei')
                ->column('imei');
            $login_imei_num = count($login_imei);

            // 老玩家
            // 设备：活跃设备中留存下来的设备数量（需要进行账号去重，即若玩家用同一账号登录不同的两台设备，则视为一台设备）
            // $old_imei_num = $this->region_connect->name('role_login')->where("time < $day_begin_time")->column('distinct(imei)');//当天之前登陆过的设备
            $old_imei_num = $old_account_num = $old_account_name = [];
            $active_account = $this->region_connect // 当天活跃账号
                ->name('role_login')
                ->where(['time' => ['between', "$day_begin_time,$day_end_time"]])
                ->group('account_name')
                ->column('account_name');
            $old_imei_data = $this->region_connect // 当天之前的登录账号
                ->name('role_login')
                ->where("time < $day_begin_time")
                ->where("imei<>'' AND imei <> 'unknown'")
                ->where('account_name', 'in', $active_account)
                ->column('account_name,imei');
            if(!empty($old_imei_data)){
                foreach ($old_imei_data as $key => $value) {
                    if(!empty($value)&&!in_array($value, $old_imei_num) && !in_array($key, $old_account_name)){
                        $old_imei_num[] = $value;
                        $old_account_name[] = $key;
                    }
                }
            }
            $old_imei = count($old_imei_num);
            // 账号：新增账号中留存下来的账号数量
            $old_account_num = $this->region_connect->name('role_create')->where("time < $day_begin_time")->column('distinct(account_name)');// 当天之前注册了的账号
            if(!empty($old_account_num)){
                $old_account = $this->region_connect // 老账号数
                    ->name('role_login')
                    ->where("time>=$day_begin_time AND time<$day_end_time")
                    ->where('account_name', 'in', $old_account_num)
                    ->group('account_name')
                    ->count();
            } else{
                $old_account = 0;
            }
            

            $data[$i] = [
                'time' => date('Y-m-d', $day_begin_time),
                //新增
                'new_imei'    => $create_imei,
                'new_account' => $new_numbers['account_num'],
                'new_role'    => $new_numbers['role_num'],
                //活跃
                'active_imei'    => $active_numbers['imei_num'],
                'active_account' => $active_numbers['account_num'],
                'active_role'    => $active_numbers['role_num'],
                //老玩家
                'old_imei'    => $old_imei,
                'old_account' => $old_account,
                'old_role'    => max(0, ($active_numbers['role_num'] - $new_numbers['role_num'])),
            ];
        }

        return ['code' => '0', 'msg' => '', 'count' => $count, 'data' => $data];
    }
    // 活跃用户构成
    public function active_table(){
        $parm = $this->request->param();

        $one_day_times = 86400;
        $limit = $parm['limit'];
        $page  = $parm['page'];
        $data  = [];
        $count = 0;
        $now   = date('Y-m-d', time());

        $time = $this->request->param('time', '', 'trim');
        list($search_begin_time, $search_end_time) = $time ? explode(' - ', $time) : ['', ''];

        //1. 计算总页(按角色创建日期)
        $first_day_org = $this->region_connect->name('role_create')->order('time asc')->limit(1)->value('time');
        $first_day_org = $first_day_org > 0 ? $first_day_org : time();
        $first_day_org = (!empty($search_begin_time) && $search_begin_time > strtotime($now)) ? strtotime($search_begin_time) : $first_day_org;
        $first_day     = date('Y-m-d', $first_day_org);
        $count         = (strtotime($now) - strtotime($first_day)) / $one_day_times +1;

        //2. 循环日期取数据
        for($i=0; $i<$limit; $i++){
            $base_time = !empty($search_end_time) ? strtotime($search_end_time) : time();
            $base_time = strtotime(date('Y-m-d', $base_time));
            $before    = $i+(($page-1)*$limit);

            //当天的时间戳范围
            $day_begin_time = strtotime("-$before day", $base_time);
            $day_end_time   = $day_begin_time + $one_day_times;

            if($day_end_time < $first_day_org || $day_end_time <= strtotime($search_begin_time))
                break;

            $res_active_head = $this->region_connect //当天活跃人数
                ->name('role_login')
                ->where("time>=$day_begin_time AND time<$day_end_time")
                ->count('distinct(role_id)');
            $add_head = $this->region_connect //当天新增
                ->name('role_create')
                ->where("time>=$day_begin_time AND time<$day_end_time")
                ->count();

            //N天前新增人数占当日全部活跃人数的比例（活跃百分比）
            $k = 1;
            while($k<=30){ //注册日期当天往后的30天
                $login_begin_time = strtotime(date('Y-m-d', $day_begin_time));
                $login_begin_time = $login_begin_time + $one_day_times*$k;
                $login_end_time   = $login_begin_time + $one_day_times;

                if($login_begin_time > time() || in_array($k, [15,21,30]))
                    break;

                $active_num = $this->region_connect
                    ->name('role_login')
                    ->where("time>=$login_begin_time AND time<=$login_end_time")
                    ->count('distinct(role_id)');

                $data[$i]['a'.$k] = percentage($active_num <= 0 ? 0 : ($add_head / $active_num));
                ++$k;
            }

            $data[$i]['time']   = date('Y-m-d', $day_begin_time);
            $data[$i]['add']    = $add_head;//当天新增
            $data[$i]['active'] = $res_active_head;//当天活跃
        }

        return ['code' => '0', 'msg' => '', 'count' => count($data), 'data' => $data];
    }


    //留存
    public function keep(){
        $res = $this->region_connect
            ->name('role_create')
            ->count();
        $this->assign('create',$res);
        return $this->fetch();
    }
    // 活跃留存
    public function keep_data(){
        $data = [];
        $parm = $this->request->param();

        // 1.计算总页数（按角色创建日期）
        $first_day = $this->region_connect->name('role_create')->order('time asc')->limit(1)->value('time');
        $first_day = $first_day > 0 ? strtotime(date('Y-m-d',$first_day)) : strtotime(date('Y-m-d',time()));
        $count     = ceil((time() - $first_day) / 86400); // 留存天数
        $data_page = ceil($count/15); // 留存页数
        $num       = $count <= 15 ? $count : $parm['page'] == $data_page ? $count-(($parm['page']-1)*15) : 15;

        // 2.循环查询留存（根据用户登录）
        for($i=0; $i < $num; $i++) { 
            $begin = strtotime(date('Y-m-d',time())) - (($i + ($parm['page'] - 1)*15)*86400);
            $end   = $begin + 86400;
            $where['time']      = ['between', "$begin,$end"];
            $data[$i]['day']    = $count - ($i + (($parm['page'] - 1) * 15)) . '<font color=gray> ('.date('Y-m-d', $begin).' )</font>'; 
            $data[$i]['equip']  = $this->region_connect->name('role_login')->where($where)->group('imei')->count();// 设备留存
            $data[$i]['account']= $this->region_connect->name('role_login')->where($where)->group('account_name')->count();// 账号留存
            $data[$i]['role']   = $this->region_connect->name('role_login')->where($where)->group('role_id')->count();// 角色留存
        }

        $arr = array ('code' => '0', 'msg' => '', 'count' => $count, 'data' =>$data );
        return $arr;
    }
    // 用户留存统计 - 新增账号留存
    public function keep_table_data(){
        $parm = $this->request->param();

        $one_day_times = 86400;
        $limit = $parm['limit'];
        $page  = $parm['page'];
        $now   = date('Y-m-d', time());

        $time = $this->request->param('time', '', 'trim');
        list($search_begin_time, $search_end_time) = $time ? explode(' - ', $time) : ['', ''];

        //1. 计算总页(按账号创建日期)
        $first_day_org = $this->region_connect->name('role_create')->order('time asc')->limit(1)->value('time');
        $first_day_org = $first_day_org > 0 ? $first_day_org : time();
        $first_day_org = (!empty($search_begin_time) && $search_begin_time > strtotime($now)) ? strtotime($search_begin_time) : $first_day_org;
        $first_day     = date('Y-m-d', $first_day_org);
        $count         = (strtotime($now) - strtotime($first_day)) / $one_day_times +1;

        //2. 循环日期取数据
        $data = [];
        for($i=0; $i<$limit; $i++){
            $base_time = !empty($search_end_time) ? strtotime($search_end_time) : time();
            $base_time = strtotime(date('Y-m-d',$base_time));
            $before    = $i+(($page-1)*$limit);

            //当天的时间戳范围
            $day_begin_time = strtotime("-$before day", $base_time);
            $day_end_time   = $day_begin_time + $one_day_times;

            if($day_end_time < $first_day_org || $day_end_time <= strtotime($search_begin_time))
                break;

            $account_names = $this->region_connect->name('role_create')->where("time>=$day_begin_time AND time<=$day_end_time")->group('account_name')->column('account_name');//当天新增账号
            $day_add_user_total = count($account_names);

            //注册日期当天往后的每日登录率（所谓留存率）
            $k = 1;
            while($k<30){
                $login_begin_time = strtotime(date('Y-m-d', $day_begin_time));
                $login_begin_time = $login_begin_time + $one_day_times*$k;
                $login_end_time   = $login_begin_time + $one_day_times;

                if($login_begin_time > time())
                    break;

                $active_num = 0;
                if(!empty($account_names)){
                    $active_num = $this->region_connect
                        ->name('role_login')
                        ->where("time>=$login_begin_time AND time<=$login_end_time")
                        ->where('account_name', 'in', $account_names)
                        ->count('distinct(account_name)');
                }

                $data[$i]['a'.$k] = percentage($active_num <= 0 ? 0 : ($active_num / $day_add_user_total));
                ++$k;
            }

            $data[$i]['time'] = date('Y-m-d', $day_begin_time); //日期
            $data[$i]['add']  = $day_add_user_total;
        }

        return ['code' => '0', 'msg' => $count, 'count' => $count, 'data' =>$data];
    }
    // 新增设备留存
    public function keep_new_imei(){
        $parm = $this->request->param();
        $data = [];

        list($search_begin, $search_end) = (isset($parm['time'])&&!empty($parm['time'])) ? explode(' - ', $parm['time']) : ['', ''];
        
        // 1计算页数
        $now = strtotime(date('Y-m-d',time()));
        $start_date = $this->region_connect->name('role_create')->order('time asc')->limit(1)->value('time');
        $start_date = $start_date > 0 ? strtotime(date('Y-m-d', $start_date)) : $now;
        $start_date = empty($search_begin) ? $start_date : strtotime($search_begin); // 第一天是否开服当天
        $end_date   = empty($search_end) ? ($now+86400) : (strtotime($search_end)+86400); // 最后一天是否今天
        $count      = ceil(($end_date - $start_date) / 86400); // 总天数
        $page_total = ceil($count / 15); // 总页数
        $limit      = ($count > 15 && $page_total != $parm['page']) ? 15 : $count - (($parm['page'] - 1) * $parm['limit']); // 当页条数

        // 循环获取数据
        $last_time = empty($search_end) ? $now : strtotime($search_end);
        for ($i=0; $i < $limit; $i++) { 
            $begin_time = $last_time - (((($parm['page']-1) * $parm['limit']) + $i) * 86400); 
            $end_time   = $begin_time + 86400;

            $data[$i]['date']     = date('Y-m-d', $begin_time); // 日期
            $new_imei = $this->region_connect->name('role_create')->where(['time' => ['between', "$begin_time,$end_time"]])->where("imei<>'' and imei<>'unknown'")->group('imei')->column('imei'); // 当天新增设备
            $data[$i]['num'] = count($new_imei); // 当天新增设备量
       
            if($begin_time < $start_date || $end_time > $end_date)
                break;

            // 当天新增账号
            $new_account = $this->region_connect
                ->name('role_create')
                ->where(['time' => ['between', "$begin_time,$end_time"]])
                ->group('account_name')
                ->column('account_name');


            // 注册当天后每日登陆数（留存率）
            // 当日新增活跃设备（即当日新增的进行过登录操作的设备数量）中留存下来的设备数量（需要进行账号去重，即若玩家用同一账号登录不同的两台设备，则视为一台设备）/当日新增设备的数量
            for ($j=0; $j < 30; $j++) { 
                $login_begin_time = $begin_time+($j*86400);
                $login_end_time   = $login_begin_time + 86400;
                $old_imei_num = 0;
                $old_imei = $old_account = [];

                if($login_begin_time > $now)
                    break;

                if(!empty($new_imei)){
                    $old_data = $this->region_connect
                        ->name('role_login')
                        ->where(['time'=>['between', "$login_begin_time,$login_end_time"]])
                        ->where("imei <> '' AND imei <> 'unknown'")
                        ->where('account_name', 'in', $new_account)
                        ->column('account_name,imei');
                    if(!empty($old_data)){
                        foreach ($old_data as $key => $value) {
                            if(!empty($value) && !in_array($value, $old_imei) && !in_array($key, $old_account)){
                                $old_imei[] = $value;
                                $old_account[] = $key;
                            }
                        }
                    }
                    $old_imei_num = count($old_imei);
                }


                $data[$i]['b'.$j] = percentage( ($data[$i]['num'] > 0)? ($old_imei_num / $data[$i]['num']) : 0);
            }
        }
        
        return ['code' => 0, 'msg' => '', 'count' => $count, 'data' => $data];
    }


    //用户等级分布
    public function lv(){
        $role_num = $this->region_connect
            ->name('role_status')
            ->count();
        $this->assign('create',$role_num);
        return $this->fetch();
    }
    public function lv_data(){
        $parm = $this->request->param();
        //总角色
        $role_num = $this->region_connect
            ->name('role_status')
            ->count();

        if(!empty($parm['online'])||!empty($parm['login'])||!empty($parm['pay'])){
            $map = [];
            if(!empty($parm['online'])){
                $map['is_online'] = $parm['online'];
            }
            if(!empty($parm['login'])){
                $time = time() - (46800*$parm['login']);
                $map['time'] = array('>=',$time);
            }
            if(!empty($parm['pay'])){

            }
            $res_active = $this->region_connect
                ->name('role_status')
                ->field('role_level,count(role_level) as lv_num')
                ->group('role_level')
                ->where($map)
                ->select();
        }else{
            $res_active = $this->region_connect
                ->name('role_status')
                ->field('role_level,count(role_level) as lv_num')
                ->group('role_level')
                ->select();
        }

        $data = [];
        foreach ($res_active as $key=>$val){
            $data[$key]['lv'] = $val['role_level'];
            $data[$key]['role_num'] = $val['lv_num'];
            $data[$key]['avg'] = percentage($val['lv_num'] / $role_num);
        }

        return ['code' => '0', 'msg' => '', 'count' => count($res_active), 'data' =>$data];
    }



    //用户地图分布
    public function map(){
        return $this->fetch();
    }
    public function map_data(){
        $parm = $this->request->param();

        $map = $data = [];
        if(!empty($parm['online'])||!empty($parm['lv1'])||!empty($parm['lv2'])){  //检索条件
            if(!empty($parm['online'])){
                $map['is_online'] = $parm['online'];
            }
            if(!empty($parm['lv1']) && !empty($parm['lv2'])){
                $lv1 = $parm['lv1'];
                $lv2 = $parm['lv2'];
                $map['role_level'] = array('between',"$lv1,$lv2");
            }
        }

        $res_map = $this->region_connect
            ->name('role_status')
            ->where($map)
            ->field('map_id,count(map_id) as map_num')
            ->group('map_id')
            ->limit(($parm['page']-1)*$parm['limit'], $parm['limit'])
            ->select();

        $arr = $this->getExcelConfig('execel_map');

        foreach ($res_map as $key=>$val){
            $data[$key]['map_name'] = isset($arr[$val['map_id']]) ? $arr[$val['map_id']] : [];
            $data[$key]['map_num'] = $val['map_num'];
            $data[$key]['map_id'] = $val['map_id'];
        }

        $count = $this->region_connect
            ->name('role_status')
            ->where($map)
            ->group('map_id')
            ->count();

        $arr = array ('code' => '0', 'msg' => '', 'count' => $count, 'data' =>$data );
        return $arr;
    }


    // 用户职业统计
    public function vocation() {
        $role_num = $this->region_connect
            ->name('role_status')
            ->count();
        $this->assign('create',$role_num);
        return $this->fetch();
    }
    public function vocation_data() {
        // 总职业数
        $vocation_num = $this->region_connect->name('role_status')->count();

        $data = $this->region_connect
            ->name('role_status')
            ->field('category, count(id) as cate_num')
            ->group('category')
            ->select();
        
        foreach ($data as $key => $value) {
            $data[$key]['category'] = '职业' . $value['category'];
            $data[$key]['ratio']    = percentage($value['cate_num'] / $vocation_num);
        }

        return ['code' => '0', 'msg' => '', 'count' => count($data), 'data' =>$data ];
    }


}
