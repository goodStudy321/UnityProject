<?php
namespace app\admin\controller;

use think\Db;

class Players extends Main {


    public function rechargeDetail() {
        return $this->fetch('public/null');
    }

    //每日新增留存 此方法支持主模板显示、数据输出、结果导出Excel
    public function dayNewUser() {
        //1. 收集参数
        $one_day_times = 86400;
        $excel_total   = $this->request->param('excel_total', 0, 'int');
        $page          = $this->request->param('page', 1, 'int');
        $limit         = $excel_total > 0 ? $excel_total : $this->request->param('limit', 10, 'int');
        $now           = date('Y-m-d', time());

        $time = $this->request->param('time', '', 'trim');
        list($search_begin_time, $search_end_time) = $time ? explode(' - ', $time) : ['', ''];

        $filter = $this->getFilterValue(); //筛选参数
        $map = elasticsearch_condition($filter);

        //2. 计算总页(按角色创建日期)
        $first_day_org = $this->central_connect->name('role_create')->where($map)->order('time asc')->limit(1)->column('time');
        $first_day_org = (!empty($search_begin_time) && $search_begin_time < strtotime($now)) ? strtotime($search_begin_time) : $first_day_org;
        $first_day_org = $first_day_org ? $first_day_org : time();

        $first_day = date('Y-m-d', $first_day_org);
        $count     = (strtotime($now) - strtotime($first_day)) / $one_day_times +1;

        //3. 主模板输出
        if(!$this->request->isAjax() && $excel_total <= 0){
            $url_query = http_build_query($this->request->param());

            $this->assign([
                'where'           => $url_query,
                'time'            => $time,
                'export_url'      => '/admin/players/dayNewUser?'. $url_query.'&excel_total='. ceil($count / $limit),
                'selected_filter' => $filter,
            ]);
            return $this->fetch();
        }

        //4. 循环日期取数据
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

            //当天新增
            $where = "time>=$day_begin_time AND time<$day_end_time";
            if(!empty($map)){
                $where = $map . ' AND ' .$where;
            }
            $day_add_user_total = $this->central_connect
                ->name('role_create')
                ->where($where)
                ->count();

            //注册日期当天往后的每日登录率（所谓留存率）
            $data[$i]['time'] = date('Y-m-d', $day_begin_time); //日期
            $data[$i]['add']  = $day_add_user_total;
            $k = 1;
            while($k<=30){
                $login_begin_time = strtotime(date('Y-m-d', $day_begin_time));
                $login_begin_time = $login_begin_time + $one_day_times*$k;
                $login_end_time   = $login_begin_time + $one_day_times;

                if($login_begin_time > time())
                    break;

                $role_ids = $this->central_connect
                    ->name('role_create')
                    ->field('role_id')
                    ->where($where)
                    ->select();
                $role_ids = $role_ids ? array_unique(array_column($role_ids, 'role_id')) : [];

                $active_num = 0;
                if(!empty($role_ids)){
                    $role_ids = implode(',', $role_ids);
                    $active_num = $this->central_connect
                        ->name('role_login')
                        ->where("time>=$login_begin_time AND time<$login_end_time AND role_id in ($role_ids)")
                        ->count('distinct(role_id)');
                }

                $data[$i]['a'.$k] = ($active_num <= 0) ? '0.00%' : sprintf('%.2f', ($active_num / $day_add_user_total) * 100) . '%';//百分比

                ++$k;
            }

            if($day_begin_time <= $first_day_org)
                break;
        }

        //5. 导出Excel
        if($excel_total > 0){
            $data = array_merge([['注册日期', '当天新增用户', '第2天', '第3天', '第4天', '第5天', '第6天', '第7天', '第8天', '第9天', '第10天', '第11天', '第12天', '第13天', '第14天', '第15天', '第30天']], $data);
            $excel_header = [
                ['A',20],
                ['B',20],
                ['C',10],
                ['D',10],
                ['E',10],
                ['F',10],
                ['G',10],
                ['H',10],
                ['I',10],
                ['J',10],
                ['K',10],
                ['L',10],
                ['M',10],
                ['N',10],
                ['O',10],
                ['P',10],
                ['Q',10],
            ];
            exportExcel($data, $excel_header, ' 每日新增留存');
        }

        return ['code' => '0', 'msg' => $count, 'count' => $count, 'data' =>$data];
    }

    public function timeOnLine() {
        $one_day_times = 86400;
        $parm = $this->request->param();
        $excel= $this->request->param('excel', 0, 'int');
        $time_limit     = $this->request->param('time_limit', 60, 'int');
        $begin_time_org = $this->request->param('time', '', 'trim');
        $begin_time_org = $begin_time_org ? $begin_time_org : date('Y-m-d', time());

        //筛选参数
        $filter = $this->getFilterValue();
        $map = elasticsearch_condition($filter);

        if(!$this->request->isAjax() && $excel != 1){
            $this->assign('time', $begin_time_org);
            $this->assign('time_limit', $time_limit);
            $this->assign('width', (100 - $time_limit)*60);
            $this->assign('selected_filter', $filter + $parm);
            $this->assign('where', http_build_query($parm));
            $this->assign('export_url', '/admin/players/timeOnLine?'. http_build_query($parm). '&excel=1');
            return $this->fetch();
        }

        $begin_time = strtotime($begin_time_org);
        $end_time   = $begin_time + 86400;
        $where = "time >= $begin_time AND time<$end_time";
        if(!empty($map)){
            $where .= ' AND ' . $map; 
        }
        $result     = $this->central_connect->name('online')->where($where)->select();

        if(empty($result)){
            return [
                'name' => [],
                'val'  => [],
            ];
        }

        $one_hour_minute = 60;
        $time_limit      = in_array($time_limit, [5,10,30,60]) ? $time_limit : $one_hour_minute;
        $one_day_times   = 24*$one_hour_minute;

        //分组，按时间,每$time_limit分钟为一组
        $online_num_arr = [];
        foreach($result as $val){
            $group_key = floor(($val['time'] - $begin_time) / ($time_limit*$one_hour_minute)) + 1;
            $online_num_arr[$group_key][] = (int)$val["online_num"];
        }

        //将一天内的时间按每$time_limit分钟为一段来循环
        $hour = $mill = 0;
        $time_val = $time_name = [];
        $loop_times = ($one_day_times/$time_limit) + 1; //循环次数
        for($i=1; $i<=$loop_times; $i++){
            $time_val[$i] = isset($online_num_arr[$i]) ? array_sum($online_num_arr[$i]) : 0;
            $time_name[$i] = sprintf('%02d', $hour).':'. sprintf('%02d', $mill*$time_limit);

            ++$mill;

            if($i%($one_hour_minute/$time_limit) == 0){
                $mill = 0;
                $hour++;
            }
        }
        unset($v);

        if($excel == 1){
            $excel_data = [];
            foreach($time_name as $k=>&$v){
                $excel_data[] = [
                    $begin_time_org,
                    $time_name[$k],
                    $time_val[$k],
                ];
            }
            unset($v);

            $data = array_merge([['日期','时间', '在线人数']], $excel_data);
            $excel_header = [
                ['A',20],
                ['B',20],
                ['C',20],
            ];
            exportExcel($data, $excel_header, '分时在线人数 - '.$begin_time_org);
        }

        return [
            'name' => array_values($time_name),
            'val'  => array_values($time_val),
        ];
    }

    public function dayOnLine() {
        $filter = $this->getFilterValue();
        $map = elasticsearch_condition($filter);

        //主模板输出
        if(!$this->request->isAjax()){
            $this->assign('selected_filter', $filter);
            return $this->fetch();
        }

        $parm = $this->request->param();

        if(strlen($parm['time']) >= 23){
            list($times, $timee) = explode(' - ', $parm['time']);
            $times = strtotime($times);
            $timee = strtotime($timee);
            $nums = ($timee-$times)/86400;
            $time_arr = [];
            $time = $times;
            for ($i=0;$i<=$nums;$i++){
                $time_arr[]= date('Y-m-d',$time);
                $timed = $time+86400;
                if(!empty($map)){
                    $where = $map . " AND time>=$time AND time<=$timed";
                }else{
                    $where = "time>=$time AND time<=$timed";
                }
                $res = $this->central_connect
                    ->name('online')
                    ->where($where)
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
        }else{
            $times = strtotime(date('Y-m-d',time()))-864000;
            $timee = strtotime(date('Y-m-d',time()));

            $nums = ($timee-$times)/86400;
            $time_arr = [];
            $time = $times;
            for ($i=1;$i<=$nums;$i++){
                $time_arr[]= date('Y-m-d',$time);
                $timed = $time+86400;
                if(!empty($map)){
                    $where = $map . " AND time>=$time AND time<=$timed";
                }else{
                    $where = "time>=$time AND time<=$timed";
                }
                $res = $this->central_connect
                    ->name('online')
                    ->where($where)
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

    //分时注册(按时)
    public function timeRegister() {
        $oneday = 86400;
        $excel= $this->request->param('excel', 0, 'int');
        $time = $this->request->param('time', '', 'trim');
        $time = $time ? $time : date('Y-m-d', time());

        $begin = strtotime($time);
        $end   = $begin + $oneday;

        //筛选参数
        $filter = $map = $this->getFilterValue();
        $filter['time'] = $time;
        $map = elasticsearch_condition($map); //
        $where = "time >= {$begin} AND time < {$end}";
        if(!empty($map)){
            $where .= " AND " . $map;
        }

        $role_total   = $this->central_connect->name('role_create')->where($where)->count();
        //$accout_total = $this->central_connect->name('role_create')->where($where)->count('distinct(account_name)'); //fixme
        $accout_total = $this->central_connect->name('role_create')->where($where)->field('account_name')->select();
        $accout_total = $accout_total ? count(array_unique(array_column($accout_total, 'account_name'))) : 0;
        

        if(!$this->request->isAjax() && $excel != 1){
            $parm = $this->request->param();
            $this->assign('time', $time);
            $this->assign('role_total', $role_total);
            $this->assign('selected_filter', $filter + $parm);
            $this->assign('account_total', $accout_total);
            $this->assign('where', http_build_query($parm));
            $this->assign('export_url', '/admin/players/timeRegister?excel=1&'. http_build_query($parm));

            return $this->fetch();
        }

        if($time == '' && $excel != 1)
            return ['code' => '0', 'msg' => '', 'count' => 0, 'data' => []];

        $result = $this->central_connect->name('role_create')->where($where)->select();

        if(empty($result) && $excel != 1)
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
        for($i=0; $i<$nowHour; $i++){
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
            $v['account_proportion'] = $accout_total > 0 ? percentage($v['account_number'] / $accout_total) : percentage(0);
            $v['role_number']        = count(array_filter($v['role_number']));
            $v['role_proportion']    = $role_total > 0 ? percentage($v['role_number'] / $role_total) : percentage(0);
        }
        unset($v);

        //导出Excel
        if($excel == 1){
            $excel_data = [];
            foreach($data as $v){
                $excel_data[] = [
                    $v['time'],
                    $v['account_number'],
                    $v['account_proportion'],
                    $v['role_number'],
                    $v['role_proportion'],
                ];
            }
            $data = array_merge([['时间/小时', '账号数', '账号比例', '角色数', '角色比例']], $excel_data);
            $excel_header = [
                ['A',20],
                ['B',20],
                ['C',10],
                ['D',10],
                ['E',10],
            ];
            exportExcel($data, $excel_header, '分时注册统计 - 按时');
        }

        return ['code' => '0', 'msg' => '', 'count' => 0, 'data' =>$data];
    }

    //分时注册(按天)
    public function  timeRegisterDay(){

        $one_day_times = 86400;
        $parm = $this->request->param();
        $excel= $this->request->param('excel', 0, 'int');
        $time = $this->request->param('time', '', 'trim');
        $page = $this->request->param('page', 1, 'int');
        $limit= $this->request->param('limit', 15, 'int');
        $limit = $excel == 1 ?  99999999 : $limit;

        //筛选参数
        $filter = $this->getFilterValue();
        $map = elasticsearch_condition($filter);

        //0. 总量
        $role_total   = $this->central_connect->name('role_create')->where($map)->count();
        //$accout_total = $this->central_connect->name('role_create')->where($map)->count('distinct(account_name)'); //fixme
        $accout_total = $this->central_connect->name('role_create')->where($map)->field('account_name')->select();
        $accout_total = $accout_total ? count(array_unique(array_column($accout_total, 'account_name'))) : 0;
        printr($accout_total);
        if(!$this->request->isAjax() && $excel != 1){
            $this->assign('time', $time);
            $this->assign('role_total', $role_total);
            $this->assign('account_total', $accout_total);
            $this->assign('selected_filter', $filter + $parm);
            $this->assign('where', http_build_query($parm));
            $this->assign('export_url', '/admin/players/timeRegisterDay?'. http_build_query($parm). '&excel=1');
            return $this->fetch();
        }

        list($search_begin_time, $search_end_time) = $time ? explode(' - ', $time) : [0, 0];

        //1. 计算总页(按角色创建日期)
        $first_day_org = !empty($search_begin_time) ? strtotime($search_begin_time) : $this->central_connect->name('role_create')->where($map)->order('time asc')->limit(1)->column('time');
        $first_day_org = $first_day_org ? $first_day_org : time();
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

            if($day_end_time < $first_day_org || $day_end_time <= strtotime($search_begin_time))
                break;

            $where = "time>=$day_begin_time AND time<$day_end_time";
            if(!empty($map)){
                $where .= ' AND ' . $map;
            }

            //当天的账号注册量
            $accout_num = $this->central_connect
                ->name('role_create')
                ->where($where)
                ->count('distinct(account_name)');

            //当天的角色注册量
            $role_num = $this->central_connect
                ->name('role_create')
                ->where($where)
                ->count();

            $data[$i] = [
                'time'               => date('Y-m-d', $day_begin_time), //日期
                'account_number'     => $accout_num,
                'account_proportion' => $accout_total > 0 ? percentage($accout_num/$accout_total) : percentage(0),
                'role_number'        => $role_num,
                'role_proportion'    => $role_total > 0 ? percentage($role_num/$role_total) : percentage(0),
            ];
        }

        //导出Excel
        if($excel == 1){
            $data = array_merge([['时间/小时', '账号数', '账号比例', '角色数', '角色比例']], $data);
            $excel_header = [
                ['A',20],
                ['B',20],
                ['C',10],
                ['D',10],
                ['E',10],
            ];
            exportExcel($data, $excel_header, '分时注册统计 - 按天');
        }

        return ['code' => '0', 'msg' => $count, 'count' => $count, 'data' =>$data];
    }
}
