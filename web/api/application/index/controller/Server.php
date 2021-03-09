<?php
namespace app\index\controller;

use think\Request;
use app\common\Base;
use app\index\model\DataServer;
use app\index\model\DataTitle;
use app\index\model\ChannelGame;

class Server extends Base{
    public $server_status = [];

    public function _initialize(){
        parent::_initialize();
        $this->server_status = ['关闭', '开启', '繁忙', '火爆', '爆满'];
    }

    public function index() {
        $this->returnJson(10200);
    }

    public function getClientServer() {
        $game_channel_id = $this->request->param('game_channel_id', 0, 'int');
        $version_name    = $this->request->param('version_name', '', 'trim');
        $server_option   = $this->request->param('server_option', 0, 'int');

        $channel_game = (new ChannelGame())->find($game_channel_id);
        if(empty($channel_game) || !$channel_game['router_id'])
            $this->returnJson(10400, '没有这条数据');

        $map = [
            'router_id'         => $channel_game['router_id'],
            'server_option'    => $server_option,
            'is_first_version' => 0,
        ];

        if($version_name != '' && $version_name == $channel_game['version_name'])
            $map['is_first_version'] = ['in', '0,1'];

        $titles = (new DataTitle())->where('router_id='.$channel_game['router_id'])->column('index_id,router_id,name,begin_id,end_id');
        $server = (new DataServer())->where($map)->column('index_id,router_id,server_id,name,ip,port,status,is_new');
        if(!empty($server)){        
            foreach ($server as $key => $value) {
                $server[$key]['status_name'] = $this->server_status[$value['status']];
            }
        }

        echo json_encode([[
            'titles'  => array_values($titles),
            'servers' => array_values($server),
        ]]);
    }

    public function getAll() {
        $data = (new DataServer())->getServer();
        if(!empty($data)){        
            foreach ($data as $key => $value) {
                $data[$key]['status_name'] = $this->server_status[$value['status']];
            }
        }
        $this->returnJson(10200, '', $data);
    }

    public function getOne() {
        $id = $this->request->param('id', 0, 'int');
        if($id <= 0)
            $this->returnJson(10400, '参数有误');

        $data = (new DataServer())->getServer($id);
        if(!empty($data)){
            $data['status_name'] = $this->server_status[$data['status']];
        }

        $this->returnJson(10200, '', $data);
    }

    public function category(){
        $data = (new DataTitle())->column('index_id,router_id,name,begin_id,end_id');
        $data = $data ? array_values($data) : [];
        $this->returnJson(10200, '', $data);
    }
}
