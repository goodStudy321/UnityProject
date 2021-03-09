<?php
namespace app\admin\controller;

use think\Controller;
use think\Db;


class Activation extends Main {

    public function produce(){
        $data = Db::name('act_create')
            ->order('id desc')
            ->paginate();

        $this->assign('page', $data->render());
        $this->assign('server', Db::name('data_server')->column('index_id,server_id,name'));
        $this->assign('data', $data);
        return $this->fetch();
    }

    public function produceAdd(){
        $data = Db::name('channel')
            ->order('id asc')
            ->select();

        $this->assign('data', $data);
        return $this->fetch();
    }

    //编辑
    public function produceEdit($id=0){
        $data = Db::name('act_create')
            ->where("id=$id")
            ->find();

        $channel = Db::name('channel')
            ->order('id desc')
            ->select();

        $first_channle_id = $data['channel_id'];
        $server = [];
        if($first_channle_id != 'all'){
            $channel_game = Db::name('channel_game')->where("channel_id='$first_channle_id'")->column('id,router_id,name');
            $router_ids = $channel_game ? array_column($channel_game, 'router_id') : [];
            if($router_ids){
                $map = [
                    'router_id' => ['in', $router_ids],
                    'status' => 1,
                ];
                $server = Db::name('data_server')->where($map)->column('index_id,server_id,name');
            }
        }

        $this->assign('server', $server);
        $this->assign('data', $data);
        $this->assign('channel', $channel);
        return $this->fetch();
    }

    //删除
    public function produceDel($id){
        $res = Db::transaction(function() use($id){
            Db::name('act_create')->where("id=$id")->delete();
            Db::name('act_code')->where("create_id=$id")->delete();
            return true;
        });

        if($res)
            return $this->success('操作成功');
        else
            return $this->error('操作失败');
    }

    //生成激活码
    public function send(){
        $id      = $this->request->post('id', 0, 'int');
        $act_num = $this->request->post('act_num', 0, 'int');
        if($id <= 0 || $act_num <= 0)
            return ['code' => '0', 'msg' => '参数有误'];

        $data = Db::name('act_create')->where("id=$id")->find();

        if(empty($data))
            return ['code' => '0', 'msg' => '生成失败'];

        $units = [];
        for ($i = 0; $i < $act_num; $i++) {
            $units[] = [
                'code_name'   => substr(md5(uniqid(rand(),1)),   8,   16),
                'create_id'   => $data['id'],
                'time'        => time(),
            ];
        }

        $res = Db::name('act_code')->insertAll($units);
        if($res){
            $ret = Db::name('act_create')->where(array('id'=>$id))->setInc('create_num');
            return ['code' => '1', 'msg' => '生成成功'];
        }

        return ['code' => '0', 'msg' => '生成失败'];
    }

    //接收添加和编辑
    public function produceSend(){
        $post     = $this->request->post();

        if(!empty($post)){
            $channel = explode('-',$post['channel']);
            $post['channel_id'] = $channel[0];
            $post['channel_name'] = $channel[1];
            if($post['server_id'] != 'all'){
                $server = explode('-',$post['server_id']);
                $post['server_id']      = $server[0];
                $post['data_server_id'] = $server[1];
            }
            unset($post['channel']);

            $post['time'] = time();
            if(!empty($post['edit'])){
                $id = $post['edit'];
                unset($post['edit']);
                $res = Db::name('act_create')->where(array('id'=>$id))->update($post);
            }else{
                $res = Db::name('act_create')->insert($post);
            }

            if($res !== false)
                return $this->success('操作成功');
            else
                return $this->error('操作失败');
        }
    }

    //管理激活码
    public function examine(){
        $id = $this->request->param('id');
        $this->assign('id', $id);
        return $this->fetch();
    }

    public function examine_data($limit = 0, $page = 0){
        $parm = $this->request->param();
        $create_id = $parm['create_id'];
        $parm['limit'] =  $limit > 0 ? $limit : $parm['limit'];
        $parm['page']  =  $page > 0 ? $page : (isset($parm['page']) ? $parm['page'] : 1);

        $data = $map = '';
        if(!empty($parm['find'])){
            if(!empty($parm['create_id']))
                $map['c.create_id'] = $parm['create_id']; //条件id

            if(!empty($parm['code_status'])&&$parm['code_status']!='all')
                $map['l.code_status'] = $parm['code_status']; //激活码

            if(!empty($parm['code_name']))
                $map['c.code_name'] = trim($parm['code_name']); //激活码

            if(!empty($parm['reward'])){
                $reward = $parm['reward'];
                $map['l.reward'] = array('like',"%$reward%"); //奖励物品
            }

            if(!empty($parm['create'])){
                list($parm['create1'], $parm['create2']) = explode(' - ', $parm['create']);
                $create1 = strtotime($parm['create1']);
                $create2 = strtotime($parm['create2'])+86400-1;
                $map['c.time'] = array('between',"$create1,$create2"); //注册时间区间
            }
            $res = Db::name('act_code')
                ->alias('c')
                ->join('last_act_create l', 'c.create_id = l.id', 'LEFT')
                ->where($map)
                ->limit(($parm['page']-1)*$parm['limit'], $parm['limit'])
                ->field('c.*, l.code_status, l.reward, l.reward_num')
                ->order('c.id desc')
                ->select();

            $count =Db::name('act_code')
                ->alias('c')
                ->join('last_act_create l', 'c.create_id = l.id', 'LEFT')
                ->where($map)->count();
        }else{
            $res = Db::name('act_code')
                ->alias('c')
                ->join('last_act_create l', 'c.create_id = l.id', 'LEFT')
                ->limit(($parm['page']-1)*$parm['limit'], $parm['limit'])
                ->where('c.create_id='.$create_id)
                ->field('c.*, l.code_status, l.reward, l.reward_num')
                ->order('c.id desc')
                ->select();

            $count = Db::name('act_code')
                ->alias('c')
                ->join('last_act_create l', 'c.create_id = l.id', 'LEFT')
                ->where('c.create_id='.$create_id)
                ->count();
        }

        $status_arr = [
            '每个角色只能领取一次',
            '每个账号只能领取一次',
            '每个服务器只能领取一次',
            '“每个服务器/每个角色”只能领取一次',
        ];

        foreach ($res as $key=>&$val){
            $val['id']           = $val['id'];
            $val['code_name']    = $val['code_name'];
            $val['time']         = date('Y-m-d H:i:s',$val['time']);
            $val['code_status']  = $status_arr[$val['code_status']-1];
            $val['reward']       = $val['reward'];
            $val['reward_num']   = $val['reward_num'];
        }

        return ['code' => '0', 'msg' => '', 'count' => $count, 'data' =>$res];
    }


    //激活码使用列表
    public function user(){
        return $this->fetch();

    }

    public function user_data(){
        $parm = $this->request->param();

        $data = $map = '';
        if(!empty($parm['find'])){
            if(!empty($parm['role_name']))
                $map['o.role_name'] = trim($parm['role_name']); //角色

            if(!empty($parm['account_name'])){
                $map['o.account_name'] = trim($parm['account_name']); //账号
            }

            if(!empty($parm['code_status'])&&$parm['code_status']!='all')
                $map['l.code_status'] = (int)$parm['code_status']; //激活码状态

            if(!empty($parm['code_name']))
                $map['c.code_name'] = trim($parm['code_name']); //激活码

            if(!empty($parm['reward'])){
                $reward = trim($parm['reward']);
                $map['l.reward'] = array('like',$reward); //绑定物品
            }

            if(!empty($parm['use_time'])){
                list($parm['create1'], $parm['create2']) = explode(' - ', $parm['use_time']);
                $create1 = strtotime($parm['create1']);
                $create2 = strtotime($parm['create2'])+86400-1;
                $map['o.time'] = array('between',"$create1,$create2"); //使用时间区间
            }

            if(!empty($parm['role_level']))
                $map['o.role_level'] = array('>=',(int)$parm['role_level']); //最低等级

            if(!empty($parm['server_id']))
                $map['l.server_id'] = (int)$parm['server_id']; //最低等级
            
            $res = Db::name('act_code_old')
                ->alias('o')
                ->join('last_act_code c', 'o.code_id = c.id', 'LEFT')
                ->join('last_act_create l', 'o.create_id = l.id', 'LEFT')
                ->where($map)
                ->limit(($parm['page']-1)*$parm['limit'], $parm['limit'])
                ->field('o.*, c.code_name, l.code_status, l.reward_num, l.reward, l.server_id')
                ->order('o.id desc')
                ->select();

            $count =Db::name('act_code_old')
                ->alias('o')
                ->join('last_act_code c', 'o.code_id = c.id', 'LEFT')
                ->join('last_act_create l', 'o.create_id = l.id', 'LEFT')
                ->where($map)
                ->count();
        }else{
            $res = Db::name('act_code_old')
                ->alias('o')
                ->join('last_act_code c', 'o.code_id = c.id', 'LEFT')
                ->join('last_act_create l', 'o.create_id = l.id', 'LEFT')
                ->limit(($parm['page']-1)*$parm['limit'], $parm['limit'])
                ->field('o.*, c.code_name, l.code_status, l.reward_num, l.reward, l.server_id')
                ->order('o.id desc')
                ->select();

            $count = Db::name('act_code_old')->count();
        }

        $status_arr = [
            '每个角色只能领取一次',
            '每个账号只能领取一次',
            '每个服务器只能领取一次',
            '“每个服务器/每个角色”只能领取一次',
        ];

        foreach ($res as $key=>&$val){
            $val['id']           = $val['id'];
            $val['time']         = date('Y-m-d H:i:s',$val['time']);
            $val['code_name']    = $val['code_name'];
            $val['code_status']  = $status_arr[$val['code_status']-1];
            $val['reward']       = $val['reward'];
            $val['reward_num']   = $val['reward_num'];
            $val['server_id']    = ($val['server_id']==1)?'默认服务器':'其他服务器';
        }

        return ['code' => '0', 'msg' => '', 'count' => $count, 'data' =>$res];
    }


    public function exportExcel(){
        $parm      = $this->request->param();
        $create_id = $parm['create_id'];
        $data = $this->examine_data(999999999);
        if(empty($data['data']))
            return $this->error('还没有数据');

        $data = array_merge([['ID', '激活码', '激活码分类ID', '生成时间', '限制条件', '绑定物品', '绑定数量']], $data['data']);

        $title    = '分类ID为'.$create_id.'的所有激活码';
        $T_arr    = ['A','B','C','D','E','F','G','H'];
        $PHPExcel = new \PHPExcel();
        $PHPSheet = $PHPExcel->getActiveSheet();
        $PHPSheet->setTitle($title);
        $PHPExcel->getActiveSheet()->getColumnDimension('A')->setWidth(15);
        $PHPExcel->getActiveSheet()->getColumnDimension('B')->setWidth(25);
        $PHPExcel->getActiveSheet()->getColumnDimension('C')->setWidth(15);
        $PHPExcel->getActiveSheet()->getColumnDimension('D')->setWidth(20);
        $PHPExcel->getActiveSheet()->getColumnDimension('E')->setWidth(35);
        $PHPExcel->getActiveSheet()->getColumnDimension('F')->setWidth(20);
        $PHPExcel->getActiveSheet()->getColumnDimension('G')->setWidth(20);
        foreach($data as $k=>$v){
            if($k != 0)
                $v = array_values($v);

            ++$k;
            foreach($v as $key=>$value){
                $list = $T_arr[$key];
                $t = $list.$k;
                $PHPSheet->setCellValue($t,$value);
            }
        }

        $PHPWriter = \PHPExcel_IOFactory::createWriter($PHPExcel,'Excel2007');//按照指定格式生成Excel文件，‘Excel2007’表示生成2007版本的xlsx，‘Excel5’表示生成2003版本Excel文件

        header('Content-Type: application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');//告诉浏览器输出07Excel文件
        header('Content-Disposition: attachment;filename="'.$title.'.xlsx"');//告诉浏览器输出浏览器名称
        header('Cache-Control: max-age=0');//禁止缓存
        $PHPWriter->save("php://output");
    }

}
