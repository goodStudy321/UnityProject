<?php
namespace app\admin\controller;

use think\Controller;
use think\Db;
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

            $active_numbers = $this->region_connect //当天活跃人数
                ->name('role_login')
                ->field('count(role_id) as role_num, count(distinct(account_name)) as account_num, count(distinct(imei)) as imei_num')
                ->where("time>=$day_begin_time AND time<$day_end_time")
                ->find();

            $new_numbers = $this->region_connect //当天新增数
                ->name('role_create')
                ->field('count(role_id) as role_num, count(distinct(account_name)) as account_num, count(distinct(imei)) as imei_num')
                ->where("time>=$day_begin_time AND time<$day_end_time")
                ->find();

            $data[$i] = [
                'time' => date('Y-m-d', $day_begin_time),
                'new_imei'    => $new_numbers['imei_num'],
                'new_account' => $new_numbers['account_num'],
                'new_role'    => $new_numbers['role_num'],
                'active_imei'    => $active_numbers['imei_num'],
                'active_account' => $active_numbers['account_num'],
                'active_role'    => $active_numbers['role_num'],
                'old_imei'    => max(0, ($active_numbers['imei_num'] - $new_numbers['imei_num'])),
                'old_account' => max(0, ($active_numbers['account_num'] - $new_numbers['account_num'])),
                'old_role'    => max(0, ($active_numbers['role_num'] - $new_numbers['role_num'])),
            ];
        }

        return ['code' => '0', 'msg' => '', 'count' => $count, 'data' => $data];
    }

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

    public function keep_data(){
        //最后一天时间
        $last_time = $this->region_connect
            ->name('role_login')
            ->order('time asc')
            ->value('time');

        $timee = strtotime(date('Y-m-d',time()));

        $data = [];
        $time = $timee;
        $nums = ($timee-$last_time)/86400;
        if($nums<60){
            for ($i=1;$i<=$nums;$i++){
                $timed = $time-86400;
                //当天活跃人数
                $res_active_head = $this->region_connect
                    ->name('role_login')
                    ->where("time>=$timed AND time<=$time")
                    ->count('distinct(role_id)');

                $data[$i]['i'] = $i;//日期
                $data[$i]['active'] = $res_active_head;//当天活跃

                $time = $time+86400;//循环时间+1天
            }

        }else{
            $times = strtotime(date('Y-m-d',time()))-864000;
            $timee = strtotime(date('Y-m-d',time()));

            $nums = ($timee-$times)/86400;
            $time = $timee;
            for ($i=1;$i<=$nums;$i++){
                $timed = $time-86400;
                //当天活跃人数
                $res_active_head = $this->region_connect
                    ->name('role_login')
                    ->where("time>=$timed AND time<=$time")
                    ->count('distinct(role_id)');

                $data[$i]['i'] = $i;//日期
                $data[$i]['active'] = $res_active_head;//当天活跃

                $time = $time+86400;//循环时间+1天
            }

        }
        $count = count($data);
        $arr = array ('code' => '0', 'msg' => '', 'count' => $count, 'data' =>$data );
        return $arr;
    }

    // 用户留存统计 - 新增留存
    public function keep_table_data(){
        $parm = $this->request->param();

        $one_day_times = 86400;
        $limit = $parm['limit'];
        $page  = $parm['page'];
        $now   = date('Y-m-d', time());

        $time = $this->request->param('time', '', 'trim');
        list($search_begin_time, $search_end_time) = $time ? explode(' - ', $time) : ['', ''];

        //1. 计算总页(按角色创建日期)
        $first_day_org = $this->region_connect->name('role_create')->order('time asc')->limit(1)->value('time');
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

            $day_add_user_total = $this->region_connect->name('role_create')->where("time>=$day_begin_time AND time<=$day_end_time")->count();//当天新增

            //注册日期当天往后的每日登录率（所谓留存率）
            $k = 1;
            while($k<=30){
                $login_begin_time = strtotime(date('Y-m-d', $day_begin_time));
                $login_begin_time = $login_begin_time + $one_day_times*$k;
                $login_end_time   = $login_begin_time + $one_day_times;

                if($login_begin_time > time())
                    break;

                $role_ids = $this->region_connect
                    ->name('role_create')
                    ->where("time>=$day_begin_time AND time<=$day_end_time")
                    ->column('role_id');

                $active_num = 0;
                if(!empty($role_ids)){
                    $active_num = $this->region_connect
                        ->name('role_login')
                        ->where("time>=$login_begin_time AND time<=$login_end_time")
                        ->where('role_id', 'in', $role_ids)
                        ->count('distinct(role_id)');
                }

                $data[$i]['a'.$k] = percentage($active_num <= 0 ? 0 : ($active_num / $day_add_user_total));
                ++$k;
            }

            $data[$i]['time'] = date('Y-m-d', $day_begin_time); //日期
            $data[$i]['add']  = $day_add_user_total;
        }

        return ['code' => '0', 'msg' => $count, 'count' => $count, 'data' =>$data];
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
            $map = '';
            $data = '';
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
