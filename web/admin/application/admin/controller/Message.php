<?php
namespace app\admin\controller;

use think\Controller;
use think\Log;
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

            $prop = explode(',',$post['prop']);
            $propnum = explode(',',$post['propnum']);
            //绑定，数量
            $goods = '';
            foreach ($prop as $key=>$val){
                $goods .= $val.','.$propnum[$key].','.$post['bind'].'|';
            }

            $goods = trim($goods,'|');  //物品列表

            $title = urlencode($post['title']);  //标题
            $text = trim($post['content']);
            $text = str_replace('[color=#', '[', $text);
            $text = str_replace('[/color]', '[-]', $text);
            $post['content'] = $text;
            $text = urlencode($text); //内容

            $headers = ['content-type:application/x-www-form-urlencoded'];
            $url = $this->message_send_to_url . "/?time=$time&ticket=$ticket&action=$action&role_ids=$role_ids&goods=$goods&title=$title&text=$text";
            $ret = curl($url, '', $headers);

            $post['admin_name'] = session('username');
            $post['time'] = time();

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
        $result = Db::name('notice')
            ->order('id desc')
            ->paginate();

        $data = $result->toArray();
        $data = $data['data'];
        if(!empty($data)){
            foreach ($data as $key => $value) {
                if(strlen($value['time']) != 10) {
                    $data[$key]['time'] = '--';
                } else {
                    $data[$key]['time'] = date('Y-m-d H:i:s', $value['time']);
                }
            }
        }

        $this->assign('page', $result->render());
        $this->assign('data', $data);
        return $this->fetch();
    }

    public function noticeAdd(){
        return $this->fetch();
    }

    public function noticeSend(){
        $post     = $this->request->post();
        if(!empty($post)){
            $post['time']= strtotime($post['time']);
            $id = Db::name('notice')->insertGetId($post);

            $noticetime = $post['time'] - time();
            $noticetime = $noticetime > 0 ? $noticetime : 0;
            $ticket     = md5(time(). config('erlang_salt'));
            $time       = time();
            $txt        = urlencode($post['content']);
            $times      = $post['num'];
            $interval   = $post['time_interval'];
            $url = $this->message_send_to_url . "/?id={$id}&time=$time&notice_time=$noticetime&ticket=$ticket&action=send_notice&txt=$txt&times=$times&interval=$interval";
            Log::write($url, 'debug:noticeSend');

            $curl = curl_init();
            curl_setopt($curl, CURLOPT_URL, $url);
            curl_setopt($curl, CURLOPT_HEADER, 0);
            curl_setopt($curl, CURLOPT_RETURNTRANSFER, 1);
            $data = curl_exec($curl);
            curl_close($curl);

            //显示获得的数据
            $ret = json_decode($data,true);
            if(!empty($ret)&&$ret['ret']==1){
                $red = Db::name('notice')->where(array('id'=>$id))->update(['status'=>1]);
                return $this->success('发送成功');
            }else{
                $res = Db::name('notice')->where(array('id'=>$id))->update(['status'=>0]);
                return $this->error('发送失败');
            }
        }
    }


    //删除
    public function noticeDel(){
        $post= $this->request->post();
        $id = $post['id'];
        $res = DB::name('notice')->where('id',$id)->find();
        if(empty($res)){
            $this->error('该公告不存在');
        }
        $red = Db::name('notice')->where(array('id'=>$id))->update(['status'=>2]);

        if(!empty($red)){
            $time   = time();
            $ticket = md5($time. config('erlang_salt'));
            $url = $this->message_send_to_url . "/?id={$id}&ticket={$ticket}&action=del_notice&time={$time}";
            Log::write($url, 'debug:noticeDel');

            $curl = curl_init();
            curl_setopt($curl, CURLOPT_URL, $url);
            curl_setopt($curl, CURLOPT_HEADER, 0);
            curl_setopt($curl, CURLOPT_RETURNTRANSFER, 1);
            $data = curl_exec($curl);
            curl_close($curl);

            //显示获得的数据
            $ret = json_decode($data,true);
            
            if(!empty($ret)&&$ret['ret']==1){
                $this->success('删除成功');
            }else{
                Db::name('notice')->where(array('id'=>$id))->update(['status'=>$res['status']]);
                $this->error('删除失败');
            }
        }else{
            $this->error('删除失败');
        }
    }

    //弹窗公告
    public function announcement(){
        $data = Db::name('announcement')
            ->alias('a')
            ->join('channel c','c.channel_id = a.channel_id', "LEFT")
            ->join('channel_game g','g.game_channel_id = a.game_channel_id', "LEFT")
            ->field('a.*, c.name as channel_name, g.name as game_channel_name')
            ->order('a.id asc')
            ->paginate();

        $this->assign('page', $data->render());
        $this->assign('data', $data->toArray());
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
            $text = trim($post['text']);
            $text = str_replace('[color=#', '[', $text);
            $text = str_replace('[/color]', '[-]', $text);

            $data = [
                'text'            => $text,
                'channel_id'      => isset($post['channel_id']) ? (int)$post['channel_id'] : 0,
                'game_channel_id' => isset($post['game_channel_id']) ? (int)$post['game_channel_id'] : 0,
            ];
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

        $channel = DB::name('channel')->select();
        $channel_game = DB::name('channel_game')->where(['channel_id' => $data['channel_id']])->select();

        $text = $data['text'];
        $text = str_replace('[-]', '[/color]', $text);
        $text = preg_replace('/\[((\w){6,})\]/i', '[color=#${1}]', $text);
        $data['text'] = $text;

        $this->assign([
            'data'         =>$data,
            'channel'      => $channel,
            'channel_game' => $channel_game,
        ]);
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
