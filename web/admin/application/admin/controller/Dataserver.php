<?php
namespace app\admin\controller;

use think\Db;
use app\admin\model\DataTitle;
use app\admin\model\DataServer as DataServerModel;

class Dataserver extends Main {

    public function index() {
        return $this->fetch();
    }

    public function dataserverData(){
        $model = new DataServerModel();
        $limit = $this->request->param('limit', 30, 'int');
        $res   = $model->order('index_id DESC')->paginate($limit)->toArray();
        $data  = $res['data'];
        
        if(!empty($data)){
            //组装
            foreach($data as &$v){
                $v['action'] = '<button onclick="del('.$v['index_id'].')" class="layui-btn layui-btn-xs layui-btn-danger">删除</button>';
                $v['action'] .= '<button class="layui-btn layui-btn-xs " onclick="x_admin_show(\'修改服务器\',\'edit.html?id='.$v['index_id'].'\',600,560)">修改服务器</i></button>';
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

    public function del(){
        $id = $this->request->post('id', 'int', 0);
        if($id <= 0)
            $this->returnJson(10400, '参数有误');

        $res = (new DataServerModel())->where("index_id=$id")->delete();

        if($res > 0)
            $this->returnJson(10200, '删除成功');
        else
            $this->returnJson(10400, '删除失败');
    }

    public function add(){
        if($this->request->isAjax()){
            $post = $this->request->post();
            $data = [
                'router_id'  => (int)$post['router_id'],
                'server_id' => (int)$post['server_id'],
                'name'      => trim($post['name']),
                'ip'        => trim($post['ip']),
                'port'      => (int)$post['port'],
                'add_time'  => time(),
            ];
            if(in_array('', $data))
                $this->returnJson(10400, '参数有误');

            $data['status'] = (int)$post['status'];
            $data['is_new'] = (int)$post['is_new'];
            $data['is_first_version'] = (int)$post['is_first_version'];

            $res = (new DataServerModel())->save($data);
            if($res === false)
                $this->returnJson(10400, '添加失败');
            else
                $this->returnJson(10200, '添加成功');
        }

        return $this->fetch();
    }

    public function edit(){
        if($this->request->isAjax()){
            $post = $this->request->post();
            $data = [
                'index_id'  => (int)$post['index_id'],
                'router_id'  => (int)$post['router_id'],
                'server_id' => (int)$post['server_id'],
                'name'      => trim($post['name']),
                'ip'        => trim($post['ip']),
                'port'      => (int)$post['port'],
                'add_time'  => time(),
            ];
            if(in_array('', $data))
                $this->returnJson(10400, '参数有误');

            $data['status'] = (int)$post['status'];
            $data['is_new'] = (int)$post['is_new'];
            $data['is_first_version'] = (int)$post['is_first_version'];

            $res = (new DataServerModel())->update($data);
            if($res === false)
                $this->returnJson(10400, '修改失败');
            else
                $this->returnJson(10200, '修改成功');
        }

        $id = $this->request->get('id', 'int', 0);
        if($id <= 0)
            return $this->error('参数有误');

        $data = Db::name('data_server')->find($id);
        if(empty($data))
            return $this->error('没有这条数据');

        $this->assign('data', $data);
        return $this->fetch();
    }

    /* 服务器分类相关 =================================================================================================== */
    //服务器分类
    public function category(){
        return $this->fetch();
    }

    public function categoryData(){
        $model = new DataTitle();
        $limit = $this->request->param('limit', 30, 'int');
        $res   = $model->order('index_id DESC')->paginate($limit)->toArray();
        $data  = $res['data'];

        if(!empty($data)){
            //组装
            foreach($data as &$v){
                $v['action'] = '<button onclick="del('.$v['index_id'].')" class="layui-btn layui-btn-xs layui-btn-danger">删除</button>';
                $v['action'] .= '<button class="layui-btn layui-btn-xs " onclick="x_admin_show(\'修改服务器分类\',\'categoryEdit.html?id='.$v['index_id'].'\',500,350)"></i>修改服务器分类</button>';
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

    //添加一个
    public function categoryAdd(){
        if($this->request->isAjax()){
            $post = $this->request->post();
            $data = [
                'router_id'        => (int)$post['router_id'],
                'name'            => trim($post['name']),
                'begin_id'        => (int)$post['begin_id'],
                'end_id'          => (int)$post['end_id'],
                'add_time'        => time(),
            ];
            if(in_array('', $data))
                $this->returnJson(10400, '参数有误');

            $res = (new DataTitle())->save($data);
            if($res == 1)
                $this->returnJson(10200, '新增成功');
            else
                $this->returnJson(10400, '新增失败');
        }

        return $this->fetch();
    }

    //修改
    public function categoryEdit(){
        if($this->request->isAjax()){
            $post = $this->request->post();
            $data = [
                'index_id'        => (int)$post['index_id'],
                'router_id'        => (int)$post['router_id'],
                'name'            => trim($post['name']),
                'begin_id'        => (int)$post['begin_id'],
                'end_id'          => (int)$post['end_id'],
            ];
            if(in_array('', $data))
                $this->returnJson(10400, '参数有误');

            $res = (new DataTitle())->update($data);
            if($res !== false)
                $this->returnJson(10200, '修改成功');
            else
                $this->returnJson(10400, '修改失败');
        }

        $id = $this->request->get('id', 'int', 0);
        if($id <= 0)
            return $this->error('参数有误');

        $data = Db::name('data_title')->find($id);
        if(empty($data))
            return $this->error('没有这条数据');

        $this->assign('data', $data);
        return $this->fetch();
    }

    //物理删除
    public function categoryDel(){
        $id = $this->request->post('id', 'int', 0);
        if($id <= 0)
            $this->returnJson(10400, '参数有误');

        $res = (new DataTitle())->where("index_id=$id")->delete();

        if($res)
            $this->returnJson(10200, '删除成功');
        else
            $this->returnJson(10400, '删除失败');
    }

    public function getByChannelID(){
        $channel = $this->request->post('channel', '', 'trim');
        $channel = $channel ? explode('-', $channel) : [];
        $channel_id = $channel ? reset($channel) : 0;
        if($channel_id <= 0)
            $this->returnJson(10400);

        $channel_game = Db::name('channel_game')->where('channel_id='.$channel_id)->column('id,router_id,name');
        $router_ids = $channel_game ? array_column($channel_game, 'router_id') : [];
        if(empty($router_ids))
            $this->returnJson(10400);

        $map = [
            'router_id' => ['in', $router_ids],
            'status' => 1,
        ];
        $server = Db::name('data_server')->where($map)->column('index_id,server_id,name');

        $this->returnJson(10200, '', $server);
    }
}
