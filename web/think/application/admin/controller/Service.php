<?php
namespace app\admin\controller;

use think\Controller;
use think\Db;
use think\Session;
use think\Validate;

class Service extends Main {
    //玩家查询
    public function gamer(){
        return $this->fetch();
    }

    public function gamer_data(){
        $parm = $this->request->param();
        $data = '';

        if(!empty($parm['find'])){
            $map = '';
            if(!empty($parm['roleid'])){
                $map['role_id'] = $parm['roleid']; //角色id
            }

            if(!empty($parm['online'])){
                $map['is_online'] = $parm['online']; //是否在线
            }

            if(!empty($parm['lv1']) && !empty($parm['lv2'])){
                $lv1 = $parm['lv1'];
                $lv2 = $parm['lv2'];
                $map['role_level'] = array('between',"$lv1,$lv2"); //等级区间
            }

            if(!empty($parm['role'])){
                $rolename = $parm['role'];
                $map['role_name'] = array('like',"%$rolename%"); //角色名
            }

            if(!empty($parm['account'])){
                $accountname = $parm['account'];
                $map['account_name'] = array('like',"%$accountname%"); //账号
            }

            if(!empty($parm['vip1']) && !empty($parm['vip2'])){
                $vip1 = $parm['vip1'];
                $vip2 = $parm['vip2'];
                $map['role_vip_level'] = array('between',"$vip1,$vip2"); //vip等级区间
            }

            if(!empty($parm['create'])){
                list($parm['create1'], $parm['create2']) = explode(' - ', $parm['create']);
                $create1 = strtotime($parm['create1']);
                $create2 = strtotime($parm['create2']) + 86400 - 1;
                $map['create_time'] = array('between',"$create1,$create2"); //注册时间区间
            }

            $res = $this->region_connect
                ->name('role_status')
                ->where($map)
                ->limit(($parm['page']-1)*$parm['limit'], $parm['limit'])
                ->select();
            $count = $this->region_connect
                ->name('role_status')
                ->where($map)
                ->count();

        }else{
            $res = $this->region_connect
                ->name('role_status')
                ->limit(($parm['page']-1)*$parm['limit'], $parm['limit'])
                ->order('last_login_time desc')
                ->select();

            $count = $this->region_connect
                ->name('role_status')
                ->count();
        }

        foreach ($res as $key=>$val){
            $data[$key]['role_id'] = $val['role_id'];
            $data[$key]['account_name'] = $val['account_name'];
            $data[$key]['role_name'] = $val['role_name'];
            $data[$key]['is_online'] = ($val['is_online'] == 1)? '在线': '离线';
            $data[$key]['role_level'] = $val['role_level'];
            $data[$key]['role_vip_level'] = $val['role_vip_level'];
            $data[$key]['category'] = $val['category'];
            $data[$key]['power'] = $val['power'];
            $data[$key]['gold'] = $val['gold'];
            $data[$key]['create_time'] = date('Y-m-d H:i:s',$val['create_time']);
            $data[$key]['last_login_time'] = date('Y-m-d H:i:s',$val['last_login_time']);
            $data[$key]['last_login_ip'] = $val['last_login_ip'];
            $data[$key]['edit'] = '<a href="/admin/service/info?role_id='.$val['role_id'].'&role_name='.$val['role_name'].'"><button class="layui-btn layui-btn-xs">基本信息</button></a>';

        }

        return ['code' => '0', 'msg' => '', 'count' => $count, 'data' => $data];
    }

    //玩家反馈
    public function feedback(){
        return $this->fetch();
    }
    public function feedback_data(){
        $parm = $this->request->param();

        if(!empty($parm['find'])){
            $map = '';
            if(!empty($parm['type'])&&$parm['type']!='all')
                $map['type'] = $parm['type']; //类型

            if(!empty($parm['status'])&&$parm['status']!='all')
                $map['status'] = $parm['status']; //状态

            if(!empty($parm['role_name'])){
                $rolename = $parm['role_name'];
                $map['role_name'] = array('like',"%$rolename%"); //角色名
            }

            if(!empty($parm['account_name'])){
                $accountname = $parm['account_name'];
                $map['account_name'] = array('like',"%$accountname%"); //账号
            }

            if(!empty($parm['back_name'])){
                $backname = $parm['back_name'];
                $map['back_name'] = array('like',"%$backname%"); //回复人
            }

            $time = trim($parm['time']);
            if(strlen($time) >= 23){
                list($begin_time, $end_time) = explode(' - ', $time);
                $begin_time = strtotime($begin_time);
                $end_time   = strtotime($end_time);
                $map['time'] = array('between', "$begin_time, $end_time"); //注册时间区间
            }

            $res = $this->region_connect
                ->name('feedback')
                ->limit(($parm['page']-1)*$parm['limit'], $parm['limit'])
                ->where($map)
                ->select();
            $count = $this->region_connect->name('feedback')->where($map)->count();
        }else{
            $res = $this->region_connect
                ->name('feedback')
                ->limit(($parm['page']-1)*$parm['limit'], $parm['limit'])
                ->order('time desc')
                ->select();

            $count = $this->region_connect->name('feedback')->count();
        }


        foreach ($res as $key=>$val){
            $res[$key]['back_content'] = (!empty($val['back_content']))? $val['back_content']: '暂无回复';
            $res[$key]['status'] = ($val['status']==0)? '未回复': '已回复';
            $res[$key]['type'] = ($val['type']==1)? '建议': 'bug';
            $res[$key]['time'] = date('Y-m-d H:i:s',$val['time']);
            $res[$key]['back_time'] = (!empty($val['back_content']))?date('Y-m-d H:i:s',$val['back_time']):'暂无';
        }

        $arr = array ('code' => '0', 'msg' => '', 'count' => $count, 'data' =>$res );
        return $arr;
    }

    //回复内容
    public function feedback_content($id){
        $role_id = $this->region_connect
            ->name('feedback')
            ->where("id=$id")
            ->value('role_id');
        $this->assign('id',$id);
        $this->assign('role_id',$role_id);
        return $this->fetch();
    }

    //提交回复
    public function feedback_send(){
        $post = $this->request->post();
        if(!empty($post)){
            $parm = [
                'time'     => time(),
                'ticket'   => md5(time(). config('erlang_salt')),
                'action'   => 'send_role_letter',
                'role_ids' => $post['role_id'],
                'title'    => '反馈回复',
                'text'     => urlencode(trim($post['back_content'])),
            ];
            if(in_array('', $parm))
                return $this->error('参数错误');

            $url = $this->message_send_to_url . '/?' .  http_build_query($parm);
            $curl = curl_init();
            curl_setopt($curl, CURLOPT_URL, $url);
            curl_setopt($curl, CURLOPT_HEADER, 0);
            curl_setopt($curl, CURLOPT_RETURNTRANSFER, 1);
            $data = curl_exec($curl);
            curl_close($curl);
            $ret = json_decode($data,true);

            if(!empty($ret)&&$ret['ret']==1){ //确认成功发送
                $data = [
                    'back_name'    => $post['back_name'],
                    'status'       => 1,
                    'back_content' => $post['back_content'],
                    'back_time'    => time(),
                ];

                $res = $this->region_connect
                    ->name('feedback')
                    ->where('id', (int)$post['id'])
                    ->update($data);
                return $this->success('发送成功');
            }else{
                return $this->error('发送失败');
            }
        }
    }

    //在线区间
    public function interval(){
        return $this->fetch();
    }



    public function interval_data(){
        $parm = $this->request->param();
        $data = '';

        if(!empty($parm['find'])){
            $map = '';

            if(!empty($parm['create'])){
                $timet = strtotime($parm['create']);
                $timed = strtotime($parm['create'])+86400;
                $map['a.time'] = array('between',"$timet,$timed"); //注册时间区间
            }

            $res = $this->region_connect
                ->name('role_logout')
                ->alias('a')
                ->where($map)
                ->field('a.role_id,sum(online_time) time,b.role_vip_level level')
                ->group('role_id')
                ->join("role_status b",'a.role_id = b.role_id')
                ->select();

        }else{
                //当天时间
            $timed = time();
            $timet = strtotime(date('Y-m-d',$timed));
            $map['a.time'] = array('between',"$timet,$timed"); //注册时间区间
            //当天内各个玩家在线时长
            $res = $this->region_connect
                ->name('role_logout')
                ->alias('a')
                ->where($map)
                ->field('a.role_id,sum(online_time) time,b.role_vip_level level')
                ->group('role_id')
                ->join("role_status b",'a.role_id = b.role_id')
                ->select();

        }

        //获取时间列表
        $list = $this->time_list();
        foreach ($list as $key=>$val){
            $data[$key]['time_name'] = $val;
            $data[$key]['online_num'] = 0;
            $data[$key]['0'] = 0;
            $data[$key]['1'] = 0;
            $data[$key]['2'] = 0;
            $data[$key]['3'] = 0;
            $data[$key]['4'] = 0;
            $data[$key]['5'] = 0;
        }
        //dump($res);die;
        foreach ($res as $key=>$val){
            switch ($val['time']){
                case $val['time']<60 && $val['time']>0:
                    $data[0]['online_num'] += 1;
                    $data[0][$val['level']] += 1; //直接用vip等级做下标
                    $data[21][$val['level']] += 1;
                    break;
                case $val['time']<=300:
                    $data[1]['online_num'] += 1;
                    $data[1][$val['level']] += 1;
                    $data[21][$val['level']] += 1;
                    break;
                case $val['time']<=600:
                    $data[2]['online_num'] += 1;
                    $data[2][$val['level']] += 1;
                    $data[21][$val['level']] += 1;
                    break;
                case $val['time']<=1200:
                    $data[3]['online_num'] += 1;
                    $data[3][$val['level']] += 1;
                    $data[21][$val['level']] += 1;
                    break;
                case $val['time']<=1800:
                    $data[4]['online_num'] += 1;
                    $data[4][$val['level']] += 1;
                    $data[21][$val['level']] += 1;
                    break;
                case $val['time']<=2400:
                    $data[5]['online_num'] += 1;
                    $data[5][$val['level']] += 1;
                    $data[21][$val['level']] += 1;
                    break;
                case $val['time']<=3000:
                    $data[6]['online_num'] += 1;
                    $data[6][$val['level']] += 1;
                    $data[21][$val['level']] += 1;
                    break;
                case $val['time']<=3600:
                    $data[7]['online_num'] += 1;
                    $data[7][$val['level']] += 1;
                    $data[21][$val['level']] += 1;
                    break;
                case $val['time']<=4200:
                    $data[8]['online_num'] += 1;
                    $data[8][$val['level']] += 1;
                    $data[21][$val['level']] += 1;
                    break;
                case $val['time']<=4800:
                    $data[9]['online_num'] += 1;
                    $data[9][$val['level']] += 1;
                    $data[21][$val['level']] += 1;
                    break;
                case $val['time']<=5400:
                    $data[10]['online_num'] += 1;
                    $data[10][$val['level']] += 1;
                    $data[21][$val['level']] += 1;
                    break;
                case $val['time']<=6000:
                    $data[11]['online_num'] += 1;
                    $data[11][$val['level']] += 1;
                    $data[21][$val['level']] += 1;
                    break;
                case $val['time']<=6600:
                    $data[12]['online_num'] += 1;
                    $data[12][$val['level']] += 1;
                    $data[21][$val['level']] += 1;
                    break;
                case $val['time']<=7200:
                    $data[13]['online_num'] += 1;
                    $data[13][$val['level']] += 1;
                    $data[21][$val['level']] += 1;
                    break;
                case $val['time']<=10800: //3小时
                    $data[14]['online_num'] += 1;
                    $data[14][$val['level']] += 1;
                    $data[21][$val['level']] += 1;
                    break;
                case $val['time']<=14400: //4小时
                    $data[15]['online_num'] += 1;
                    $data[15][$val['level']] += 1;
                    $data[21][$val['level']] += 1;
                    break;
                case $val['time']<=18000: //5小时
                    $data[16]['online_num'] += 1;
                    $data[16][$val['level']] += 1;
                    $data[21][$val['level']] += 1;
                    break;
                case $val['time']<=21600: //6小时
                    $data[17]['online_num'] += 1;
                    $data[17][$val['level']] += 1;
                    $data[21][$val['level']] += 1;
                    break;
                case $val['time']<=25200: //7小时
                    $data[18]['online_num'] += 1;
                    $data[18][$val['level']] += 1;
                    $data[21][$val['level']] += 1;
                    break;
                case $val['time']<=28800: //8小时
                    $data[19]['online_num'] += 1;
                    $data[19][$val['level']] += 1;
                    $data[21][$val['level']] += 1;
                    break;
                case $val['time']>28800: //8小时以上
                    $data[20]['online_num'] += 1;
                    $data[20][$val['level']] += 1;
                    $data[21][$val['level']] += 1;
                    break;
            }
            $data[21]['online_num'] += 1;
        }
        //总数

        $count = count($data);
        //dump($data);die;
        $arr = array ('code' => '0', 'msg' => '', 'count' => $count, 'data' =>$data );
        return $arr;

    }

    //时间列表
    public function time_list(){
        $list = array('0-1分钟','1-5分钟','5-10分钟','10-20分钟','20-30分钟','30-40分钟','40-50分钟',
            '50-1小时','1小时-1小时10分钟','1小时10分钟-1小时20分钟','1小时20分钟-1小时30分钟','1小时30分钟-1小时40分钟',
            '1小时40分钟-1小时50分钟','1小时50分钟-2小时','2小时-3小时','3小时-4小时','4小时-5小时','5小时-6小时',
            '6小时-7小时','7小时-8小时','8小时以上','总数');
        return $list;
    }

    //玩家基本信息
    public function info(){
        $role_id   = $this->request->param('role_id', 0, 'floatval');
        $role_name = $this->request->param('role_name', '', 'trim');
        if($role_id <= 0 || $role_name  == '')
            $this->error('参数有误');

        $parm = [
            'time'      => time(),
            'ticket'    => md5(time(). config('erlang_salt')),
            'action'    => 'get_role_info',
            'role_id'   => $role_id,
            'role_name' => $role_name,
        ];

        $data = curl( $this->message_send_to_url. '/?'. http_build_query($parm) );
        $data = isset($data['data']) ? $data['data'] : [];

        if(!empty($data)){
            foreach($data as &$v){
                if(isset($v['skin_list']) && !empty($v['skin_list'])){
                    $v['skin_list'] = array_map(function($list){
                        return $list['id'].'=>'.$list['val'];
                    }, $v['skin_list']);
                    $v['skin_list'] = implode('；', $v['skin_list']);
                }
                if(isset($v['pellet_list']) && !empty($v['pellet_list'])){
                    $v['pellet_list'] = array_map(function($list){
                        return $list['id'].'=>'.$list['val'];
                    }, $v['pellet_list']);
                    $v['pellet_list'] = implode('；', $v['pellet_list']);
                }
                if(isset($v['load_runes']) && !empty($v['load_runes'])){
                    $v['load_runes'] = array_map(function($list){
                        return $list['id'].'=>'.$list['val'];
                    }, $v['load_runes']);
                    $v['load_runes'] = implode('；', $v['load_runes']);
                }
            }
            unset($v);
        }

        $this->assign('data', $data);
        return $this->fetch();
    }

    public function roleShield(){
        if($this->request->isPost()){
            $role_arr = $this->request->post('roles', '', 'trim');
            $role_arr = $role_arr ? explode(',', $role_arr) : [];
            if($role_arr){
                //0. 调封禁接口
                $parm = [
                    'time'       => time(),
                    'ticket'     => md5(time(). config('erlang_salt')),
                    'action'     => 'ban_role',
                    'role_args'  => implode(',', $role_arr),
                    'ban_type'   => 1,
                    'ban_action' => 1,
                    'end_time'   => '',
                ];
                $url    = $this->message_send_to_url .'/?'. http_build_query($parm);
                $result = curl($url);
                if((int)$result['ret'] == 0)
                    $this->error('操作失败，请重试');

                $no_exist = isset($result['data']) ? $result['data'] : [];
                if($no_exist != '')
                    $this->error($no_exist.'，这些角色不存在', '', '', 10);

                ////1. 检查角色是否存在 (我们这边暂时不做检查)
                //$role_id['role_id']     = ['in', $role_arr];
                //$role_name['role_name'] = ['in', $role_arr];
                //$exist_role = $this->region_connect->name('role_status')
                //    ->field('role_id,role_name')
                //    ->where($role_id)
                //    ->whereOr($role_name)
                //    ->select();

                //if(empty($exist_role))
                //    $this->error('这些角色都不存在', '', '', 5);

                //$exist_role = array_merge(array_column($exist_role, 'role_id') , array_column($exist_role, 'role_name'));
                //$no_exist = [];
                //foreach($role_arr as $role){
                //    if(!in_array($role, $exist_role))
                //        $no_exist[] = $role;
                //}
                //$no_exist = $no_exist ? implode('，', $no_exist) : '';

                //if($no_exist != '')
                //    $this->error($no_exist.'，这些角色不存在', '', '', 10);

                //1. 检查是否重复
                $role['role'] = ['in', $role_arr];
                $exist_role = Db::name('role_shield')
                    ->field('role')
                    ->where($role)
                    ->select();
                if($exist_role){
                    $exist_role = implode('，', array_unique(array_column($exist_role, 'role')));
                    $this->error($exist_role.'，这些角色已经存在了', '', '', 10);
                }

                //2. 批量入库
                $insert_data = [];
                $reason = $this->request->post('reason', '', 'trim');
                $admin_id = session('user_id');
                foreach($role_arr as $k=>$role){
                    $insert_data[$k] = [
                        'role'     => $role,
                        'reason'   => $reason,
                        'status'   => 1,
                        'admin_id' => $admin_id,
                        'add_time' => time(),
                    ];
                }
                $result = Db::name('role_shield')->insertAll($insert_data);
                if(!$result > 0)
                    $this->error('封禁失败，请重试！', '', '', 5);
            }
        }

        $role = $this->request->get('role', '', 'trim');
        if(!$this->request->isAjax()){
            $this->assign([
                'role' => $role,
            ]);
            return $this->fetch();
        }

        $map = [];
        if($role != '')
            $map['role'] = $role;

        //1. 取出封禁表的数据
        $config = session('data_server');
        $config_title = json_decode($config['title'], true);
        $database_config = $config_title['mysql'] + config('database.datauser');

        $data = Db::name('role_shield')
            ->alias('s')
            ->where($map)
            ->field('s.*,c.role_id, c.account_name, c.role_name, c.last_login_ip, c.role_level, c.last_login_time')
            ->join($database_config['database'].".log_role_status c",'s.role = c.role_id OR s.role = c.role_name')
            ->order('s.status ASC')
            ->paginate()->toArray();
        $data = $data['data'];

        if(empty($data))
            return ['code' => '0', 'msg' => '', 'count' => 0, 'data' => []];

        $count = Db::name('role_shield')
            ->alias('s')
            ->where($map)
            ->field('s.*,c.role_id, c.account_name, c.role_name, c.last_login_ip, c.role_level, c.last_login_time')
            ->join($database_config['database'].".log_role_status c",'s.role = c.role_id OR s.role = c.role_name')
            ->count();

        //3. 取出管理员的信息（操作人）
        $admin_ids  = array_unique(array_filter(array_column($data, 'admin_id')));
        $admin_user = [];
        if($admin_ids){
            $admin_user = Db::name('user')->field('id,username')->where(['id'=>['in', $admin_ids]])->select();
            $admin_user = $admin_user ? array_column($admin_user, 'username', 'id') : [];
        }

        //4. 组装信息
        foreach($data as &$v){
            if($v['status'] != 1)
                $v['action'] = '<button onclick="javascript:unshield('.$v['id'].', 1)" class="layui-btn layui-btn-xs layui-btn-danger">封禁</button>';
            else
                $v['action'] = '<button onclick="javascript:unshield('.$v['id'].', 2)" class="layui-btn layui-btn-xs layui-btn-danger">解禁</button>';

            $v['admin_user']      = isset($admin_user[$v['admin_id']]) ? $admin_user[$v['admin_id']] : '--';
            $v['last_login_time'] = date('Y-m-d', $v['last_login_time']);
            $v['add_time']        = date('Y-m-d', $v['add_time']);
            $v['status']          = $v['status'] == 1 ? '封禁' : '正常';
        }

        return ['code' => '0', 'msg' => '', 'count' => $count, 'data' => $data];
    }

    //解角色封禁
    public function roleUnshield(){
        $id     = $this->request->post('id', 0, 'int');
        $status = $this->request->post('status', 1, 'int');
        if($id <= 0)
            $this->returnJson(10400, '参数有误');

        //1. 调接口
        $role = Db::name('role_shield')->where('id='.$id)->value('role');
        if(!$role)
            $this->returnJson(10400, '角色不存在');

        $parm = [
            'time'       => time(),
            'ticket'     => md5(time(). config('erlang_salt')),
            'action'     => 'ban_role',
            'role_args'  => $role,
            'ban_type'   => 1,
            'ban_action' => $status,
            'end_time'   => '',
        ];
        $url    = $this->message_send_to_url .'/?'. http_build_query($parm);
        $result = curl($url);

        //2. 去数据库标记为解禁
        if($result['ret'] == 1 && $result['data'] == '' ){
            $result = Db::name('role_shield')->where('id='.$id)->update(['status'=>$status]);
            if($result >= 0)
                $this->returnJson(10200, '操作成功');
        }

        $this->returnJson(10402, '操作失败');
    }

    public function roleBanned(){
        //新增禁言
        if($this->request->isPost()){
            $role_arr = $this->request->post('roles', '', 'trim');
            $role_arr = $role_arr ? explode(',', $role_arr) : [];
            $end_time = $this->request->post('end_time', '', 'trim');
            $end_time = $end_time != '' ? strtotime($end_time) : 0;

            if($role_arr && $end_time > time()){
                //0. 调封禁接口
                $parm = [
                    'time'       => time(),
                    'ticket'     => md5(time(). config('erlang_salt')),
                    'action'     => 'ban_role',
                    'role_args'  => implode(',', $role_arr),
                    'ban_type'   => 2,
                    'ban_action' => 1,
                    'end_time'   => $end_time,
                ];
                $url    = $this->message_send_to_url .'/?'. http_build_query($parm);
                $result = curl($url);
                if((int)$result['ret'] == 0)
                    $this->error('操作失败，请重试');

                $no_exist = isset($result['data']) ? $result['data'] : [];
                if($no_exist != '')
                    $this->error($no_exist.'，这些角色不存在', '', '', 10);

                //1. 批量入库
                $insert_data = [];
                $reason = $this->request->post('reason', '', 'trim');
                $admin_id = session('user_id');
                foreach($role_arr as $k=>$role){
                    $insert_data[$k] = [
                        'role'     => $role,
                        'reason'   => $reason,
                        'status'   => 1,
                        'admin_id' => $admin_id,
                        'add_time' => time(),
                        'end_time' => $end_time,
                    ];
                }
                $result = Db::name('role_banned')->insertAll($insert_data);
                if(!$result > 0)
                    $this->error('封禁失败，请重试！', '', '', 5);
            }
        }

        //输出模板
        $role = $this->request->get('role', '', 'trim');
        $time = $this->request->get('time', '', 'trim');
        if(!$this->request->isAjax()){
            $this->assign([
                'role' => $role,
                'time' => $time,
            ]);
            return $this->fetch();
        }

        //条件参数
        $map = [];
        if($role != '')
            $map['role'] = $role;

        //1. 取出禁言数据
        $config = session('data_server');
        $config_title = json_decode($config['title'], true);
        $database_config = $config_title['mysql'] + config('database.datauser');
        $data = Db::name('role_banned')
            ->alias('b')
            ->where($map)
            ->field('b.*, s.role_id, s.role_name, s.account_name')
            ->join($database_config['database'].".log_role_status s",'b.role = s.role_id OR b.role = s.role_name')
            ->order('b.status ASC')
            ->paginate()->toArray();
        $data = $data['data'];

        if(empty($data))
            return ['code' => '0', 'msg' => '', 'count' => 0, 'data' => []];

        $count = Db::name('role_banned')
            ->alias('b')
            ->where($map)
            ->field('b.*, s.role_id, s.role_name, s.account_name')
            ->join($database_config['database'].".log_role_status s",'b.role = s.role_id OR b.role = s.role_name')
            ->count();

        //3. 取出管理员的信息（操作人）
        $admin_ids  = array_unique(array_filter(array_column($data, 'admin_id')));
        $admin_user = [];
        if($admin_ids){
            $admin_user = Db::name('user')->field('id,username')->where(['id'=>['in', $admin_ids]])->select();
            $admin_user = $admin_user ? array_column($admin_user, 'username', 'id') : [];
        }

        //4. 组装信息
        foreach($data as &$v){
            if($v['status'] != 1)
                $v['action'] = '<button onclick="javascript:unbanned('.$v['id'].', 1)" class="layui-btn layui-btn-xs layui-btn-danger">禁言</button>';
            else
                $v['action'] = '<button onclick="javascript:unbanned('.$v['id'].', 2)" class="layui-btn layui-btn-xs layui-btn-danger">解禁</button>';

            $v['admin_user'] = isset($admin_user[$v['admin_id']]) ? $admin_user[$v['admin_id']] : '--';
            $v['add_time']   = date('Y-m-d H:i:s', $v['add_time']);
            $v['end_time']   = $v['end_time'] ? date('Y-m-d H:i:s', $v['end_time']) : '--';
            $v['status']     = $v['status'] == 1 ? '禁言' : '正常';
        }

        return ['code' => '0', 'msg' => '11', 'count' => $count, 'data' => $data];
    }

    //解角色禁言
    public function roleUnbanned(){
        $id     = $this->request->post('id', 0, 'int');
        $status = $this->request->post('status', 1, 'int');
        if($id <= 0)
            $this->returnJson(10400, '参数有误');

        //1. 调接口
        $role = Db::name('role_banned')->where('id='.$id)->value('role');
        if(!$role)
            $this->returnJson(10400, '角色不存在');

        $parm = [
            'time'       => time(),
            'ticket'     => md5(time(). config('erlang_salt')),
            'action'     => 'ban_role',
            'role_args'  => $role,
            'ban_type'   => 2,
            'ban_action' => $status,
            'end_time'   => '',
        ];
        $url    = $this->message_send_to_url .'/?'. http_build_query($parm);
        $result = curl($url);

        //2. 去数据库标记为解禁
        if($result['ret'] == 1 && $result['data'] == '' ){
            $result = Db::name('role_banned')->where('id='.$id)->update(['status'=>$status]);
            if($result >= 0)
                $this->returnJson(10200, '操作成功');
        }

        $this->returnJson(10400, '操作失败');
    }

    // 聊天监控
    public function chat() {
        return $this->fetch();
    }
    public function chat_data() {
        $parm = $this->request->param();
        $map  = [];

        // 频道
        if(!empty($parm['chat_type']) && $parm['chat_type'] != 'all') {
            $map['chat_type'] = $parm['chat_type'];
        }
        // 角色名
        if(!empty($parm['role_name'])) {
            $map['role_name'] = ['like', '%' . trim($parm['role_name']) . '%'];
        }
        // 角色id
        if(!empty($parm['role_id'])) {
            $map['role_id'] = $parm['role_id'];
        }
        // 时间区间
        if(!empty($parm['create'])) {
            list($begin, $end) = explode(' - ', $parm['create']);
            $begin = strtotime($begin);
            $end   = strtotime($end)+86400-1;
            $map['time'] = ['between', "$begin, $end"];
        }

        $chat_msg = $this->region_connect
            ->name('chat')
            ->where($map)
            ->order('time DESC')
            ->limit(($parm['page']-1)*$parm['limit'], $parm['limit'])
            ->select();
        $data = [];
        foreach ($chat_msg as $key => $value) {
            $data[$key]['num'] = $key+1;
            $data[$key]['msg'] = $this->_chatMsg($value);
        }
        
        return ['code' => '0', 'msg' => '', 'count' => count($chat_msg), 'data' => $data];
    }

    private function _chatMsg($arr) {
        $chat_type = ['1' => '世界频道', '2' => '家族频道', '3' => '队伍频道', '4' => '私人频道'];
        $html = date('Y-m-d H:i:s', $arr['time']) . ' -> [' . $chat_type[$arr['chat_type']] . '] -> ';
        switch ($arr['chat_type']) {
            case '2':
                $html .= '['.$arr['chat_name'] . '] -> <span id="rolename" data-roleid="'.$arr['role_id'].'" data-rolename="'.$arr['role_name'].'">' . $arr['role_name'] . '</span>';
                break;
            case '4':
                $html .= '<span id="rolename" data-roleid="'.$arr['role_id'].'" data-rolename="'.$arr['role_name'].'">' . $arr['role_name'] . '</span> 对 <span id="rolename" data-roleid="'.$arr['chat_id'].'" data-rolename="'.$arr['chat_name'].'">' . $arr['chat_name'] . '</span>';
                break;
            default:
                $html .= '<span id="rolename" data-roleid="'.$arr['role_id'].'" data-rolename="'.$arr['role_name'].'">' . $arr['role_name'] . '</span> ->';
                break;
        }
        $html .= ' 说：' . $arr['msg'];

        return $html;
    }
}

