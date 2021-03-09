<?php
namespace app\api\controller;

use think\Request;
use app\api\model\DataServer;
use app\api\model\DataTitle;
use app\api\model\ChannelGame;

class Server extends Base{

    public function __construct(){
        parent::__construct();
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

        echo json_encode([[
            'titles'  => array_values($titles),
            'servers' => array_values($server),
        ]]);
    }

    public function getAll() {
        $this->returnJson(10200, '', (new DataServer())->getServer());
    }

    public function getOne() {
        $id = $this->request->param('id', 0, 'int');
        if($id <= 0)
            $this->returnJson(10400, '参数有误');

        $this->returnJson(10200, '', (new DataServer())->getServer($id));
    }







}
