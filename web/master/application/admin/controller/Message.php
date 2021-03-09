<?php
namespace app\admin\controller;
use app\admin\model\Elasticsearch;

class Message extends Main {

    public function feedback() {
        $parm = $this->request->param();

        $excel_total = $this->request->param('excel_total', 0, 'int');
        $page        = $this->request->param('page', 1, 'int');
        $limit       = $excel_total > 0 ? $excel_total : $this->request->param('limit', 10, 'int');

        //筛选参数
        $filter = $this->getFilterValue();
        $map = elasticsearch_condition($filter);
        // $count = $this->central_connect->name('feedback')->count();
        $count = $this->central_connect->name('feedback')->where($map)->count(); //fixme

        //2. 主模板输出
        if(!$this->request->isAjax() && $excel_total <= 0){
            $this->assign('where', http_build_query($parm));
            $this->assign('selected_filter', $filter + $parm);

            $parm['excel_total'] = $count;
            $this->assign('export_url', '/admin/message/feedback?'. http_build_query($parm));

            return $this->fetch();
        }

        //组装条件
        if(!empty($parm['feedback_type'])&&$parm['feedback_type']!='all'){
            // $filter['feedback_type'] = (int)$parm['feedback_type']; //类型
            $map .= " AND feedback_type = ".(int)$parm['feedback_type'];
        }

        if(!empty($parm['status'])&&$parm['status']!='all'){
            // $filter['status'] = max(0, (int)$parm['status'] -1); //状态
            $map .= " AND status = ".max(0, (int)$parm['status'] -1);
        }

        if(!empty($parm['role_name'])){
            $rolename = trim($parm['role_name']);
            // $filter['role_name'] = array('like',"%$rolename%"); //角色名
            $map .= " AND role_name like '%$rolename%'";
        }

        if(!empty($parm['account_name'])){
            $accountname = trim($parm['account_name']);
            // $filter['account_name'] = array('like',"%$accountname%"); //账号
            $map .= " AND account_name like '%$accountname%'";
        }

        if(!empty($parm['back_name'])){
            $backname = trim($parm['back_name']);
            // $filter['back_name'] = array('like',"%$backname%"); //回复人
            $map .= " AND back_name like '%$backname%'";
        }

        $time = isset($parm['time']) ? trim($parm['time']) : '';
        if(strlen($time) >= 23){
            list($begin_time, $end_time) = explode(' - ', $time);
            $begin_time = strtotime($begin_time);
            $end_time   = strtotime($end_time);
            $filter['time'] = array('between', "$begin_time, $end_time"); //注册时间区间
            $map .= " AND time between $begin_time and $end_time";
        }

        $limit = ($page-1)*$limit.','.$limit;
        $map = trim($map, ' AND ');
        $res = $this->central_connect
            ->name('feedback')
            ->limit($limit)
            ->field('id, feedback_type, status, role_name, account_name, title, content, time, back_content, back_name, back_time')
            ->where($map)
            ->order('time desc')
            ->select();
        $count = $this->central_connect->name('feedback')->where($map)->count();

        foreach ($res as $key=>$val){
            $res[$key]['back_content'] = (!empty($val['back_content']))? $val['back_content']: '暂无回复';
            $res[$key]['status'] = ($val['status']==0)? '未回复': '已回复';
            $res[$key]['feedback_type'] = ($val['feedback_type']==1) ? '建议': 'bug';
            $res[$key]['time'] = date('Y-m-d H:i:s',$val['time']);
            $res[$key]['back_time'] = (!empty($val['back_time'])) ? date('Y-m-d H:i:s',$val['back_time']) : '暂无';
        }

        //导出Excel
        if($excel_total > 0){
            $data = array_merge([['记录ID', '类型', '状态', '角色名', '账号', '标题', '内容', '反馈时间', '回复时间', '回复人', '回复时间']], $res);
            $excel_header = [
                ['A',20],
                ['B',20],
                ['C',10],
                ['D',10],
                ['E',10],
                ['F',10],
                ['G',10],
                ['H',20],
                ['I',10],
                ['J',10],
                ['K',10],
            ];
            exportExcel($data, $excel_header, '玩家意见与反馈');
        }

        return ['code' => '0', 'msg' => '', 'count' => $count, 'data' =>$res];
    }

    public function keyword() {
        return $this->fetch('public/null');
    }


}
