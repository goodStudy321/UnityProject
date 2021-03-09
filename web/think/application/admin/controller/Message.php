<?php
namespace app\admin\controller;

use think\Controller;
use think\Db;


class Message extends Main
{

    /**
     * 消息与通知
     */
    //邮件
    public function mail(){
        $data = Db::name('mail')
            ->order('id asc')
            ->paginate();

        $this->assign('page', $data->render());
        $this->assign('data', $data);
        return $this->fetch();
    }

    public function mailAdd(){
        return $this->fetch();
    }

    public function send(){
        $post     = $this->request->post();
        if(!empty($post)){
            $time = time();
            $ticket = md5(time(). config('erlang_salt'));
            if($post['type']==0){
                $action = 'send_role_letter'; //单个玩家
            }else{
                $action = 'send_all_letter'; //全服玩家
            }

            $role_ids = $post['user'];  //玩家id
            $title    = urlencode($post['title']);  //标题
            $content  = urlencode($post['content']); //内容

            $prop = explode(',',$post['prop']);
            $propnum = explode(',',$post['propnum']);
            //绑定，数量
            $goods = '';
            foreach ($prop as $key=>$val){
                $goods .= $val.','.$propnum[$key].','.$post['bind'].'|';
            }

            $goods = trim($goods,'|');  //物品列表
            $url = $this->message_send_to_url . "/?time=$time&ticket=$ticket&action=$action&role_ids=$role_ids&goods=$goods&title=$title&text=$content";

            $post['admin_name'] = session('username');
            $post['time'] = time();

            //初始化
            $curl = curl_init();
            //设置抓取的url
            curl_setopt($curl, CURLOPT_URL, $url);
            //设置头文件的信息作为数据流输出
            curl_setopt($curl, CURLOPT_HEADER, 0);
            //设置获取的信息以文件流的形式返回，而不是直接输出。
            curl_setopt($curl, CURLOPT_RETURNTRANSFER, 1);
            //执行命令
            $data = curl_exec($curl);
            //关闭URL请求
            curl_close($curl);
            //显示获得的数据
            $ret = json_decode($data,true);
            if(!empty($ret)&&$ret['ret']==1){
                $post['status'] = 1;
                $res = Db::name('mail')->insert($post);
                return $this->success('发送成功');
            }else{
                $post['status'] = 0;
                $res = Db::name('mail')->insert($post);
                return $this->error('发送失败');
            }

        }

    }

    public function del(){
        $post     = $this->request->post();
        $red = Db::name('mail')->where(array('id'=>$post['id']))->delete();
        if(!empty($red)){
            $this->success('success');
        }else{
            $this->error('error');
        }

    }

    //滚屏公告
    public function notice(){
        $data = Db::name('notice')
            ->order('id desc')
            ->paginate();

        $this->assign('page', $data->render());
        $this->assign('data', $data);
        return $this->fetch();
    }

    public function noticeAdd(){
        return $this->fetch();
    }

    public function noticeSend(){
        $post     = $this->request->post();
        if(!empty($post)){

            $noticetime = strtotime($post['time']) - time();
            $noticetime = $noticetime > 0 ? $noticetime : 0;
            $ticket     = md5(time(). config('erlang_salt'));
            $time       = time();
            $txt        = urlencode($post['content']);
            $times      = $post['num'];
            $interval   = $post['time_interval'];
            $url = $this->message_send_to_url . "/?time=$time&notice_time=$noticetime&ticket=$ticket&action=send_notice&txt=$txt&times=$times&interval=$interval";

            $post['time'] = $noticetime;

            //初始化
            $curl = curl_init();
            //设置抓取的url
            curl_setopt($curl, CURLOPT_URL, $url);
            //设置头文件的信息作为数据流输出
            curl_setopt($curl, CURLOPT_HEADER, 0);
            //设置获取的信息以文件流的形式返回，而不是直接输出。
            curl_setopt($curl, CURLOPT_RETURNTRANSFER, 1);
            //执行命令
            $data = curl_exec($curl);
            //关闭URL请求
            curl_close($curl);
            //显示获得的数据
            $ret = json_decode($data,true);
            if(!empty($ret)&&$ret['ret']==1){
                $post['status'] = 1;
                $res = Db::name('notice')->insert($post);
                return $this->success('发送成功');
            }else{
                $post['status'] = 0;
                $res = Db::name('notice')->insert($post);
                return $this->error('发送失败');
            }
        }
    }


    //删除
    public function noticeDel(){
        $post     = $this->request->post();
        $red = Db::name('notice')->where(array('id'=>$post['id']))->delete();
        if(!empty($red)){
            $this->success('success');
        }else{
            $this->error('error');
        }
    }

    //弹窗公告
    public function announcement(){
        $data = Db::name('announcement')
            ->order('id asc')
            ->paginate();

        $this->assign('page', $data->render());
        $this->assign('data', $data);
        return $this->fetch();
    }
    public function announcementadd(){
        $data = Db::name('channel')
            ->order('id asc')
            ->select();
        $this->assign('data', $data);
        return $this->fetch();
    }

    public function announcementsend(){
        $post = $this->request->post();
        if(!empty($post)){
            $data['text'] = $post['text'];
            $channel = explode('-',$post['channel']);
            $data['channel_id'] = $channel[0];
            $data['channel_name'] = $channel[1];
            if(!empty($post['edit'])){
                $res = Db::name('announcement')->where(array('id'=>$post['edit']))->update($data);
            }else{
                $res = Db::name('announcement')->insert($data);
            }

            if($res !== false)
                return $this->success('操作成功');
            else
                return $this->error('操作失败');
        }
    }

    public function announcementedit($id){
        $data = Db::name('announcement')
            ->where("id=$id")
            ->find();
        $this->assign('data', $data);
        return $this->fetch();
    }

    //删除
    public function announcementdel(){
        $post     = $this->request->post();
        $red = Db::name('announcement')->where(array('id'=>$post['id']))->delete();
        if(!empty($red)){
            $this->success('success');
        }else{
            $this->error('error');
        }
    }








}
