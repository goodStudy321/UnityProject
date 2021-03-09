<?php
namespace app\admin\controller;

class Recharge extends Main {

    public function allStatistics() {
        //1. 收集参数
        $one_day_times = 86400;
        $parm   = $this->request->param();
        $time   = $this->request->param('time', '', 'trim');
        $excel  = $this->request->param('excel', 0, 'int');
        $page   = $this->request->param('page', 1, 'int');
        $now    = date('Y-m-d', time());
        $excel_total = $this->request->param('excel_total', 0, 'int');
        $limit       = $excel_total > 0 ? $excel_total : $this->request->param('limit', 15, 'int');
        $filter = $this->getFilterValue(); //筛选参数
        $map = elasticsearch_condition($filter);

        list($begin_time, $end_time) = $time != '' ? explode(' - ', $time) : ['', ''];

        //2. 计算总页(按角色创建日期)
        //$first_day_org = $this->central_connect->name('role_create')->order('time asc')->where($filter)->limit(1)->value('time');
        $first_day_org = $this->central_connect->name('role_create')->where($map)->order('time asc')->limit(1)->column('time'); //fixme
        $first_day_org = (!empty($begin_time) && $begin_time > strtotime($now)) ? strtotime($begin_time) : $first_day_org;
        $first_day_org = $first_day_org ? $first_day_org : time();

        $first_day = date('Y-m-d', $first_day_org);
        $count     = (strtotime($now) - strtotime($first_day)) / $one_day_times +1;

        //3. 主模板输出
        if(!$this->request->isAjax() && $excel_total <= 0){
            $this->assign([
                'time'            => $time,
                'where'           => http_build_query($parm),
                'export_url'      => '/admin/Recharge/allStatistics?'. http_build_query($parm).'&excel_total='. ceil($count / $limit),
                'selected_filter' => $filter + $parm,
            ]);

            return $this->fetch();
        }

        //4. 循环日期取数据
        $data = [];
        for($i=0; $i<$limit; $i++){
            $base_time = !empty($end_time) ? strtotime($end_time) : time();
            $base_time = strtotime(date('Y-m-d',$base_time));
            $before    = $i+(($page-1)*$limit);

            //当天的时间戳范围
            $day_begin_time = strtotime("-$before day", $base_time);
            $day_end_time   = $day_begin_time + $one_day_times;

            if($day_end_time < $first_day_org || $day_end_time <= strtotime($begin_time))
                break;

            $where = "time>=$day_begin_time AND time<$day_end_time";
            if(!empty($map)){
                $where .= ' AND ' . $map;
            }

            $new_user = $this->central_connect //当天新增
                ->name('role_create')
                ->where($where)
                ->count();

            $active_user = $this->central_connect //当天活跃人数
                ->name('role_login')
                ->where($where)
                ->count('distinct(role_id)');
            
            $data[$i] = [
                'time'              => date('Y-m-d', $day_begin_time), //'日期'
                //'channel'           => isset($parm['channel']['all']) ? '全部' : '' , //'渠道'       ,
                'new_user'          => $new_user, //'新增用户'
                'old_user'          => $active_user - $new_user,//老用户'     ,
                'active_user'       => $active_user,//'活跃用户'   ,
                'paid_user'         => '待开发..', //'付费人数'   ,
                'paid_total'        => '待开发..', //'付费金额'   ,
                'paid_arpu'         => '待开发..', //'付费ARPU'   ,
                'active_arpu'       => '待开发..', //'活跃ARPU'   ,
                'active_paid_scale' => '待开发..', //'活跃付费率' ,
                'new_paid_user'     => '待开发..', //'付费人数',
                'new_paid_total'    => '待开发..', //'付费金额',
                'new_paid_arpu'     => '待开发..', //'ARPU',
                'new_paid_scale'    => '待开发..', //'付费率',
                'old_paid_user'     => '待开发..', //'付费人数',
                'old_paid_total'    => '待开发..', //'付费金额',
                'old_paid_arpu'     => '待开发..', //'ARPU',
                'old_paid_scale'    => '待开发..', //'付费率',
            ];
        }

        //导出Excel
        if($excel_total > 0){
            $data = array_merge([['日期', '新增用户', '老用户', '活跃用户', '付费人数', '付费金额', '付费ARPU', '活跃ARPU', '活跃付费率', '新用户-付费人数', '新用户-付费金额', '新用户-ARPU', '新用户-付费率', '老用户-付费人数', '老用户-付费金额', '老用户-ARPU', '老用户-付费率']], $data);
            $excel_header = [
                ['A',20],
                ['B',20],
                ['C',20],
                ['D',20],
                ['E',20],
                ['F',20],
                ['G',20],
                ['H',20],
                ['I',20],
                ['J',20],
                ['K',20],
                ['L',20],
                ['M',20],
                ['N',20],
                ['O',20],
                ['P',20],
                ['Q',20],
            ];
            exportExcel($data, $excel_header, '综合统计');
        }

        return [
            'code'  => '0',
            'msg'   => '',
            'count' => $count,
            'data'  => $data
        ];
    }

    public function rechargeStatistics() {
        return $this->fetch('public/null');
    }

    public function rechargeDetail() {
        return $this->fetch('public/null');
    }

    public function serverRechargeDetail() {
        return $this->fetch('public/null');
    }

    public function agentRechargeDetail() {
        return $this->fetch('public/null');
    }

    public function worth() {
        return $this->fetch('public/null');
    }

    public function ranking() {
        return $this->fetch('public/null');
    }

    public function recording() {
        return $this->fetch('public/null');
    }
}
