<?php
namespace app\admin\controller;

use app\admin\model\Channel as ChannelModel;
use app\admin\model\ChannelGame;

class Channel extends Main {

    public function index() {
        return $this->fetch();
    }

    public function channelGameData(){
        $model = new ChannelGame();
        $limit = $this->request->param('limit', 30, 'int');

        $res = $model->alias('g')
            ->join('channel c','g.channel_id = c.id', "LEFT")
            ->field('g.*, c.name as channel_name')
            ->order('g.id desc')
            ->paginate($limit)
            ->toArray();
        $data = $res['data'];

        if(!empty($data)){
            foreach($data as &$v){
                $v['action'] = '<button onclick="del('.$v['id'].')" class="layui-btn layui-btn-xs layui-btn-danger">删除</button>';
                $v['action'] .= '<button class="layui-btn layui-btn-xs " onclick="x_admin_show(\'修改包渠道\',\'edit.html?id='.$v['id'].'\',500,350)">修改包渠道</i></button>';
            }
            unset($v);
        }

        return [
            'code'  => '0',
            'msg'   => '',
            'count' => $model->count(),
            'data'  => $data,
        ];
    }

    public function add(){
        if($this->request->isAjax()){
            $post = $this->request->post();
            $data = [
                'router_id'     => (int)$post['router_id'],
                'version_name' => trim($post['version_name']),
                'name'         => trim($post['name']),
                'add_time'     => time(),
            ];
            if(in_array('', $data))
                $this->returnJson(10400, '参数有误');

            $data['channel_id'] = (int)$post['channel_id'];

            $res = (new ChannelGame())->save($data);
            if($res)
                $this->returnJson(10200, '添加成功');
            else
                $this->returnJson(10400, '添加失败');
        }

        $channel_data = (new ChannelModel())->select();
        $this->assign('channel_data', $channel_data);
        return $this->fetch();
    }

    public function edit(){
        if($this->request->isAjax()){
            $post = $this->request->post();
            $data = [
                'id'           => (int)$post['id'],
                'router_id'     => (int)$post['router_id'],
                'version_name' => trim($post['version_name']),
                'name'         => trim($post['name']),
                'add_time'     => time(),
            ];
            if(in_array('', $data))
                $this->returnJson(10400, '参数有误');

            $data['channel_id'] = (int)$post['channel_id'];

            $res = (new ChannelGame())->update($data);
            if($res)
                $this->returnJson(10200, '添加成功');
            else
                $this->returnJson(10400, '添加失败');
        }

        $id = $this->request->get('id', 'int', 0);
        if($id <= 0)
            return $this->error('参数有误');

        $data = (new ChannelGame())->find($id);
        if(empty($data))
            return $this->error('没有这条数据');

        $channel_data = (new ChannelModel())->select();
        $this->assign('data', $data);
        $this->assign('channel_data', $channel_data);
        return $this->fetch();
    }

    public function del(){
        $id = $this->request->post('id', 'int', 0);
        if($id <= 0)
            $this->returnJson(10400, '参数有误');

        $res = (new ChannelGame())->where("id=$id")->delete();

        if($res > 0)
            $this->returnJson(10200, '删除成功');
        else
            $this->returnJson(10400, '删除失败');
    }


    //渠道相关 (上面是包渠道) ============================================================================================
    public function channel(){
        return $this->fetch();
    }
    public function channelData(){
        $model = new ChannelModel();
        $limit = $this->request->param('limit', 30, 'int');

        $res  = $model->order('id desc')->paginate($limit)->toArray();
        $data = $res['data'];

        if(!empty($data)){
            foreach($data as &$v){
                $v['action'] = '<button onclick="del('.$v['id'].')" class="layui-btn layui-btn-xs layui-btn-danger">删除</button>';
                $v['action'] .= '<button class="layui-btn layui-btn-xs " onclick="x_admin_show(\'修改渠道\',\'channelEdit.html?id='.$v['id'].'\',500,200)">修改渠道</i></button>';
            }
            unset($v);
        }
        return [
            'code'  => '0',
            'msg'   => '',
            'count' => $model->count(),
            'data'  => $data,
        ];
    }
    public function channelAdd(){
        if($this->request->isAjax()){
            $post = $this->request->post();
            $data = [
                'name'     => trim($post['name']),
                'add_time' => time(),
            ];
            if(in_array('', $data))
                $this->returnJson(10400, '参数有误');

            $res = (new ChannelModel())->save($data);
            if($res)
                $this->returnJson(10200, '添加成功');
            else
                $this->returnJson(10400, '添加失败');
        }

        return $this->fetch();
    }

    public function channelEdit(){
        if($this->request->isAjax()){
            $post = $this->request->post();
            $data = [
                'id'   => (int)$post['id'],
                'name' => trim($post['name']),
            ];
            if(in_array('', $data))
                $this->returnJson(10400, '参数有误');

            $res = (new ChannelModel())->update($data);
            if($res)
                $this->returnJson(10200, '添加成功');
            else
                $this->returnJson(10400, '添加失败');
        }

        $id = $this->request->get('id', 'int', 0);
        if($id <= 0)
            return $this->error('参数有误');

        $data = (new ChannelModel())->find($id);
        if(empty($data))
            return $this->error('没有这条数据');

        $channel_data = (new ChannelModel())->select();
        $this->assign('data', $data);
        return $this->fetch();
    }

    public function channelDel(){
        $id = $this->request->post('id', 'int', 0);
        if($id <= 0)
            $this->returnJson(10400, '参数有误');

        $res = (new ChannelModel())->where("id=$id")->delete();

        if($res > 0)
            $this->returnJson(10200, '删除成功');
        else
            $this->returnJson(10400, '删除失败');
    }
}
