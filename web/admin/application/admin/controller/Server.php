<?php
namespace app\admin\controller;

use think\Controller;
use think\Db;

class Server extends Main {

    public function open(){
        $data = Db::name('server')
            ->order('id asc')
            ->paginate();

        $this->assign('page', $data->render());
        $this->assign('data', $data);
        return $this->fetch();
    }

    //确认开服
    public function openServer(){
        $post     = $this->request->post();
        $data = Db::name('server_data')->where(array('id'=>$post['id']))->select();
        unset($data[0]['id']);
        $config=  '';
        $arr = array('is_debug','gateway_sandbox','background_log_open','is_merge','hb_check_closed','junhai_gold_log_open');
        foreach($data[0] as $key=>$val){
            if (in_array($key, $arr)) {
                if($val==0){
                    $config .= '{' .$key.','.'false'.'}'.".\r\n";
                }elseif($val==1){
                    $config .= '{' .$key.','.'true'.'}'.".\r\n";
                }
            }else{
                if(is_numeric($val)){
                    $config .= '{' .$key.','.$val.'}'.".\r\n";
                }elseif(is_string($val)){
                    $config .= '{' .$key.',"'.$val.'"}'.".\r\n";
                }
            }

        }

        $url = __DIR__;
        $filename = 'server-'.time();
        $myfile = fopen("$url\/$filename.config", "a");
        fwrite($myfile, $config);
        fclose($myfile);
        system("/data/sh/open_server.sh $filename",$status);
        if($status){
            $this->success('开服成功');
        }else{
            $this->error('开服失败');
        }
    }

    public function saveFile(){
        $file_root_url = __DIR__;
        $filename = $this->filename($file_root_url);


        $xml = file_get_contents('server.xml','__DIR__');
        $result= json_decode(json_encode(simplexml_load_string($xml, 'SimpleXMLElement', LIBXML_NOCDATA)), true);
        dump($result);die;
    }



    //编辑修改所有字段
    public function edit($id){

        $serverid = Db::name('server')->where("id=$id")->value('server_data_id');

        $data = array();
        $serverfield = Db::name('server_data')->where("id=$serverid")->select();

        $servercomment = Db::query("SELECT column_comment FROM information_schema.columns WHERE table_name = 'last_server_data' ");

        foreach ($servercomment as $key=>$val){
            $data['comment'][] = $val['column_comment'];
        }

        foreach ($serverfield[0] as $kk=>$vv){
            $data['field'][] = $kk;
            $data['bind'][] = $vv;
        }

        unset($data['comment'][0]);
        unset($data['field'][0]);
        unset($data['bind'][0]);

        return $this->fetch('edit',['data'=>$data,'id'=>$serverid]);
    }
    //接受编辑
    public function serverEdit(){
        $post     = $this->request->post();
        $dataid = $post['serverdataid'];
        unset($post['serverdataid']);
        if (!empty($post)) {
            $db = Db::name('server_data')->where(array('id'=>$dataid))->update($post);
            if($db){
                $this->success('success');
            }

        } else {
            $this->error('error!');
        }

    }


    //删除
    public function delServer(){
        $post     = $this->request->post();
        $red = Db::name('server')->where(array('id'=>$post['id']))->delete();
        if($red){
            $this->success('删除成功');
        }else{
            $this->error('删除失败');
        }
    }

    //新增开服数据
    public function serverAdd(){
        $data = array();
        $serverfield = Db::name('server_data')->where("id=1")->select();

        $servercomment = Db::query("SELECT column_comment FROM information_schema.columns WHERE table_name = 'last_server_data' ");

        foreach ($servercomment as $key=>$val){
            $data['comment'][] = $val['column_comment'];
        }

        foreach ($serverfield[0] as $kk=>$vv){
            $data['field'][] = $kk;
            $data['bind'][] = $vv;
        }
        unset($data['comment'][0]);
        unset($data['field'][0]);
        unset($data['bind'][0]);

        return $this->fetch('serverAdd',['data'=>$data]);
    }

    //接收开服数据
    public function serverAddcome(){
        $post     = $this->request->post();
        $addname = $post['addname'];
        unset($post['addname']);
        if (!empty($post)) {
            $db = Db::name('server_data')->insertGetId($post);
            if($db){
                //插入server_data成功之后写入server显示
                $data['time'] = time();
                $data['server_name'] = $post['server_name'];
                $data['agent_id'] = $post['agent_id'];
                $data['server_id'] = $post['server_id'];
                $data['facilitator'] = Db::name('agent_namelist')->where(array("agent_id"=>$post['agent_id']))->value('agent_name');
                $data['ip'] = $post['server_ip'];
                $data['add_name'] = $addname;
                $data['server_time'] = strtotime($post['server_start_time']);
                $data['server_data_id'] = $db;
                $res = Db::name('server')->insert($data);
                $this->success('success');
            }else{
                $this->error('数据库写入失败！');
            }

        } else {
            $this->error('error!');
        }
    }

    //快捷更新开服时间
    public function timeedit($id){
        if ($this->request->isPost()){
            $post     = $this->request->post();
            $time = $post['time'];
            $db1 = Db::name('server')->where(array('id'=>$post['id']))->setField('server_time',strtotime($time));
            $data_id = Db::name('server')->where(array('id'=>$post['id']))->value('server_data_id');
            $db2 = Db::name('server_data')->where(array('id'=>$data_id))->setField('server_start_time',$time);
            if($db1&&$db2){
                $this->success('success');
            }else{
                $this->error('数据库写入失败！');
            }

        }else{
            $this->assign('id', $id);
            return $this->fetch();
        }


    }









}
