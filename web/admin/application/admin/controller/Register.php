<?php
namespace app\admin\controller;

use think\Controller;
use think\Db;
use think\Session;
use think\Validate;

class Register extends Main {
    public function index(){
    }

    //实时在线数据
    public function online(){
        if(!$this->request->isAjax()){
            //当前在线数据
            $data = [
                'online' => $this->region_connect->name('role_status')->where("is_online=1")->count(),
                'create' => $this->region_connect->name('role_create')->count(),
            ];

            $this->assign('time', date('Y-m-d', time()));
            $this->assign('data', $data);
            return $this->fetch();
        }

        $begin_time = $this->request->param('time', '', 'trim');
        $begin_time = $begin_time ? $begin_time : date('Y-m-d', time());
        $begin_time = strtotime($begin_time);

        $end_time = $begin_time + 86400;
        $result   = $this->region_connect->name('online')->where("time>=$begin_time AND time<$end_time")->select();

        if(empty($result)){
            return [
                'name' => [],
                'val'  => [],
                'max'  => 0,
                'min'  => 0,
                'avg'  => 0,
            ];
        }

        $time_limit    = 10;
        $one_day_times = 24*60;

        //分组，按时间,每10分钟为一组
        $online_num_arr = [];
        foreach($result as $val){
            $ten_m = floor(($val['time'] - $begin_time) / ($time_limit*60)) + 1;
            $online_num_arr[$ten_m][] = (int)$val["online_num"];
        }

        //将一天内的时间按每10分钟为一段来循环
        $hour = $mill = 0;
        $time_val = $time_name = [];
        $loop_times = ($one_day_times/10) + 1; //循环次数
        for($i=1; $i<=$loop_times; $i++){
            $time_val[$i] = isset($online_num_arr[$i]) ? array_sum($online_num_arr[$i]) : 0;
            $time_name[$i] = sprintf('%02d', $hour).':'. sprintf('%02d', $mill*10);

            ++$mill;

            if($i%6 == 0){
                $mill = 0;
                $hour++;
            }
        }
        unset($v);

        //最大值最小值及平均数
        $max = max($time_val);
        $min = min($time_val);

        return [
            'name' => array_values($time_name),
            'val'  => array_values($time_val),
            'max'  => $max,
            'min'  => $min,
            'avg'  => ($max+$min)/2,
        ];
    }

    public function onlinetable(){
        $group = $this->region_connect
            ->name('role_status')
            ->field('id, role_id, role_level, time, last_login_ip')
            ->where("is_online=1")
            ->select();

        if(empty($group))
            return ['code' => '0', 'msg' => '', 'count' => 0, 'data' => []];

        foreach ($group as $key=>$val){
            $roleid     = $val['role_id'];
            $time_alone = time() - $val['time'];

            $group[$key]['time']         = date('Y-m-d H:i:s', $val['time']);
            $group[$key]['account_name'] = $this->region_connect->name('role_login')->where("role_id=$roleid")->value('account_name');
            $group[$key]['time_alone']   = sprintf('%.1f' , ($time_alone/60));
        }

        return ['code' => '0', 'msg' => '', 'count' => count($group), 'data' => $group];
    }


    //每日峰值在线
    public function peak(){

        return $this->fetch();
    }
    //峰值在线数据处理
    public function peak_data(){
        $parm = $this->request->param();
        if(!empty($parm['time'])){
            list($parm['times'], $parm['timee']) = explode(' - ', $parm['time']);
            $times = strtotime($parm['times']);
            $timee = strtotime($parm['timee']);
            $nums = ($timee-$times)/86400;
            $time_arr = '';
            $time = $times;
            for ($i=0;$i<=$nums;$i++){
                $time_arr[]= date('Y-m-d',$time);
                $timed = $time+86400;
                $res = $this->region_connect
                    ->name('online')
                    ->where("time>=$time AND time<=$timed")
                    ->select();
                $time = $time+86400;
                $arr = '';
                foreach($res as $key=>$val){
                    $arr[] = (int)$val["online_num"];
                }

                $max = $min = $avg = 0;
                if(is_array($arr)){
                    $max = max($arr);
                    $min = min($arr);
                    $avg = ($max+$min)/2;
                }

                $all1[] = $max;
                $all2[] = $avg;
                $all3[] = $min;
            }
        }else{
            $times = strtotime(date('Y-m-d',time()))-864000;
            $timee = strtotime(date('Y-m-d',time()));

            $nums = ($timee-$times)/86400;
            $time_arr = [];
            $time = $times;
            for ($i=1;$i<=$nums;$i++){
                $time_arr[]= date('Y-m-d',$time);
                $timed = $time+86400;
                $res = $this->region_connect
                    ->name('online')
                    ->where("time>=$time AND time<=$timed")
                    ->select();
                $time = $time+86400;
                $arr = [];
                foreach($res as $key=>$val){
                    $arr[] = (int)$val["online_num"];
                }
                $max = $min = $avg = 0;
                if(is_array($arr) && !empty($arr)){
                    $max = max($arr);
                    $min = min($arr);
                    $avg = ($max+$min)/2;
                }

                $all1[] = $max;
                $all2[] = $avg;
                $all3[] = $min;
            }

        }
        $all = array('a1'=>$all1,'a2'=>$all2,'a3'=>$all3);
        $array  =  array('name'=>$time_arr,'val'=>$all);
        return  json_encode($array);

    }

    //峰值在线
    public function peak_table(){
        $parm = $this->request->param();
        if(!empty($parm['times'])||!empty($parm['times'])){
            $times = strtotime($parm['times']);
            $timee = strtotime($parm['timee']);

            $nums = ($timee-$times)/86400;
            $time = $times;
            for ($i=0;$i<=$nums;$i++){
                $timed = $time+86400;
                $res = $this->region_connect
                    ->name('online')
                    ->where("time>=$time AND time<=$timed")
                    ->select();
                $arr = '';
                foreach($res as $key=>$val){
                    $arr[] = (int)$val["online_num"];
                }
                $max = $min = $avg = 0;
                if(is_array($arr)){
                    $max = max($arr);
                    $min = min($arr);
                    $avg = ($max+$min)/2;
                }

                $data[$i]['max_online'] = $max;
                $data[$i]['avg'] = $avg;
                $data[$i]['min_online'] = $min;
                $data[$i]['time'] = $time;
                $time = $time+86400;
            }
        }else{
            $times = strtotime(date('Y-m-d',time()))-864000;
            $timee = strtotime(date('Y-m-d',time()));

            $nums = ($timee-$times)/86400;
            $time = $times;
            for ($i=1;$i<=$nums;$i++){
                $timed = $time+86400;
                $res = $this->region_connect
                    ->name('online')
                    ->where("time>=$time AND time<=$timed")
                    ->select();
                $arr = [];
                foreach($res as $key=>$val){
                    $arr[] = (int)$val["online_num"];
                }
                $max = $min = $avg = 0;
                if(is_array($arr) && !empty($arr)){
                    $max = max($arr);
                    $min = min($arr);
                    $avg = ($max+$min)/2;
                }

                $data[$i]['max_online'] = $max;
                $data[$i]['avg'] = $avg;
                $data[$i]['min_online'] = $min;
                $data[$i]['time'] = date('Y-m-d', $time);
                $time = $time+86400;
            }
        }
        $count = count($data);
        $arr = array ('code' => '0', 'msg' => '', 'count' => $count, 'data' =>$data );
        return $arr;
    }

    //分时注册(按时)
    public function division(){
        $oneday = 86400;
        $time = $this->request->param('time', '', 'trim');
        $time = $time ? $time : date('Y-m-d',time());

        $begin = strtotime($time);
        $end   = $begin + $oneday;
        $map['time'] = ['between', "$begin, $end"];

        $role_total   = $this->region_connect->name('role_create')->where($map)->count();
        $accout_total = $this->region_connect->name('role_create')->where($map)->count('distinct(account_name)');

        if(!$this->request->isAjax()){
            $this->assign('time', $time);
            $this->assign('role_total', $role_total);
            $this->assign('account_total', $accout_total);
            return $this->fetch();
        }

        if($time == '')
            return ['code' => '0', 'msg' => '', 'count' => 0, 'data' => []];

        $result = $this->region_connect->name('role_create')->where($map)->select();

        if(empty($result))
            return ['code' => '0', 'msg' => '', 'count' => 0, 'data' => []];

        $oneHour = 3600;
        $data    = [];
        foreach($result as &$v){
            $hour = floor(($v['time'] - $begin) / $oneHour);
            $data[$hour]['time']    = $v['time'];
            $data[$hour]['gettime'] = $time;
            $data[$hour]['account_number'][$v['account_name']] = 1;
            $data[$hour]['role_number'][$v['role_id']]         = 1;
        }
        unset($v);

        $nowHour = date('H', time()) + 1;
        $day = date('d', time()) == date('d', $begin) ? $nowHour : 24;
        for($i=0; $i<$day; $i++){
            $hour = $i;
            $block1 = date('H:i', $begin + $hour*$oneHour);
            $block2 = date('H:i', $begin + $hour*$oneHour + $oneHour - 60);

            if( !isset($data[$hour]) ){
                $data[$hour]['gettime']          = $time;
                $data[$hour]['account_number'][] = 0;
                $data[$hour]['role_number'][]    = 0;
            }
            $data[$hour]['time'] = $time . "&nbsp;&nbsp;<font color=red>[</font>$block1 - $block2<font color=red>]</font>";
        }
        unset($v);

        foreach($data as &$v){
            $v['account_number']     = count(array_filter($v['account_number']));
            $v['account_proportion'] = percentage($v['account_number'] / $accout_total);
            $v['role_number']        = count(array_filter($v['role_number']));
            $v['role_proportion']    = percentage($v['role_number'] / $role_total);
        }
        unset($v);

        return ['code' => '0', 'msg' => '', 'count' => 0, 'data' =>$data];
    }

    //分时注册(按天)
    public function divisionDay(){
        //0. 总量
        $role_total   = $this->region_connect->name('role_create')->count();
        $accout_total = $this->region_connect->name('role_create')->count('distinct(account_name)');

        $time = $this->request->param('time', '', 'trim');

        if(!$this->request->isAjax()){
            $this->assign('time', $time);
            $this->assign('role_total', $role_total);
            $this->assign('account_total', $accout_total);
            return $this->fetch();
        }

        $parm = $this->request->param();
        $one_day_times = 86400;
        $limit = $parm['limit'];
        $page  = $parm['page'];

        list($search_begin_time, $search_end_time) = $time ? explode(' - ', $time) : [0, 0];

        //1. 计算总页(按角色创建日期)
        $first_day_org = $this->region_connect->name('role_create')->order('time asc')->limit(1)->value('time');
        $first_day_org = $first_day_org > 0 ? $first_day_org : time();
        $first_day_org = !empty($search_begin_time) ? strtotime($search_begin_time) : $first_day_org;
        $first_day     = date('Y-m-d', $first_day_org);
        $now           = date('Y-m-d', time());
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

            //当天的账号注册量
            $accout_num = $this->region_connect
                ->name('role_create')
                ->where("time>=$day_begin_time AND time<$day_end_time")
                ->count('distinct(account_name)');

            //当天的角色注册量
            $role_num = $this->region_connect
                ->name('role_create')
                ->where("time>=$day_begin_time AND time<$day_end_time")
                ->count();

            $data[$i] = [
                'time'               => date('Y-m-d', $day_begin_time), //日期
                'account_number'     => $accout_num,
                'account_proportion' => percentage($accout_num/$accout_total),
                'role_number'        => $role_num,
                'role_proportion'    => percentage($role_num/$role_total),
            ];

            if($day_begin_time <= $first_day_org)
                break;
        }

        return ['code' => '0', 'msg' => $count, 'count' => $count, 'data' =>$data];
    }
}
