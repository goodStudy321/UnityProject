<?php
namespace app\admin\controller;

use think\Db;
use app\admin\model\Channel;

class Record extends Main{

    public function index(){
        return $this->fetch('login');
    }

    //邮件日志数据
    public function mail(){
        return $this->fetch();
    }

    //邮件日志数据
    public  function mailData(){
        $where = [];
        $channel_id = $this->request->param('channel_id', 0, 'int');
        if($channel_id > 0)
            $where['m.channel_id'] = $channel_id;

        $game_channel_id = $this->request->param('game_channel_id', 0, 'int');
        if($game_channel_id > 0)
            $where['m.game_channel_id'] = $game_channel_id;

        $time_org  = $this->request->param('send_time', '', 'trim');
        if(!empty($time_org)){
            $time   = explode(' - ', $time_org);
            $begin  = strtotime($time['0']);
            $end    = strtotime($time['1']) + 86400; // 当天 + 1天 - 1秒(当天23:59:59)
            
            if($begin != '' && $end != '')
                $where['m.time'] = [['>', $begin], ['<', $end]];
        }

        $title = $this->request->param('title_strings', '', 'trim');
        if($title != '')
            $where['m.title_strings'] = ['like', "%$title%"];

        $limit= $this->request->param('limit', 30, 'int');
        $res = $this->region_connect
            ->name('role_mail')
            ->alias('m')
            ->join('role_status r','m.role_id = r.role_id', "LEFT")
            ->field("m.*,r.role_name")
            ->where($where)
            ->order('m.id desc')
            ->paginate($limit)
            ->toArray();
        
        $data = $res['data'];
        if(!empty($data)){
            $letter = $this->getExcelConfig('excel_letter');

            foreach($data as $k=>$v){
                $_goods_list = explode('||', $v['goods_list']);
                $_goods_list = array_filter($_goods_list);
                $tool_arr = [];
                if(!empty($_goods_list)){
                    foreach($_goods_list as $key=>$val)
                        $tool_arr[] = explode(',', $val);
                }
                $data[$k]['goods_list'] = $tool_arr;
            }

            //渠道相关的数据
            extract( (new Channel())->processChannels($data) );

            //取出道具数据
            $item = $this->getExcelConfig('execel_item');

            //最后组装
            foreach($data as $k=>$v){
                $template = isset($letter[$v['template_id']]) ? $letter[$v['template_id']] : $letter[0];
                list($title, $content) = explode('%%', $template);
                $data[$k]['title_strings'] = str_replace('#', $v['title_strings'], $title);
                $data[$k]['text_strings']  = str_replace('#', $v['text_strings'], $content);
                $data[$k]['time'] = date('Y-m-d H:i:s', $v['time']);
                $data[$k]['channel_name']      = isset($channel_name[$v['channel_id']]) ? $channel_name[$v['channel_id']] : '--';
                $data[$k]['game_channel_name'] = isset($game_channel_name[$v['game_channel_id']]) ? $game_channel_name[$v['game_channel_id']] : '--';

                $goods_list = '';
                if(!empty($v['goods_list'])){
                    foreach($v['goods_list'] as $_k=>$_v){
                        $_item = isset($item[$_v[0]]) ? explode('%%', $item[$_v[0]])[0] : '--';
                        $_bind = (int)$_v[2] == 0 ? '不绑定' : '绑定';
                        $goods_list .= $_item .' - '. $_v[1] .' - '. $_bind ."；";
                    }
                }
                $data[$k]['goods_list'] = $goods_list;
            }
        }

        return [
            'code'  => '0',
            'msg'   => '',
            'count' => $res['total'],
            'data'  => $data,
        ];
    }

    //boss日志 - boss掉落
    public function bossFall(){
        return $this->fetch();
    }

    public function bossFallData(){
        $where = $data = [];

        $boss_type_id = $this->request->param('boss_type_id', 0, 'int');
        if($boss_type_id > 0)
            $where['boss_type_id'] = $boss_type_id;

        $time_org  = $this->request->param('send_time', '', 'trim');
        if(!empty($time_org)){
            $time   = explode(' - ', $time_org);
            $begin  = strtotime($time['0']);
            $end    = strtotime($time['1']) + 86400; // 当天 + 1天 - 1秒(当天23:59:59)
            
            if($begin != '' && $end != '')
                $where['time'] = [['>', $begin], ['<', $end]];
        }

        $limit= $this->request->param('limit', 30, 'int');
        $res = $this->region_connect
            ->name('world_boss_drop')
            ->where($where)
            ->order('id desc')
            ->paginate($limit)
            ->toArray();

        $monster = $this->getExcelConfig('execel_monster');
        $item    = $this->getExcelConfig('execel_item');
        $tmp     = $res['data'];

        if(!empty($tmp)){
            foreach($tmp as $k=>&$value){
                $_goods_list = explode('||', $value['drop_goods_list']);
                $_goods_list = array_filter($_goods_list);
                $tool_arr = [];
                if(!empty($_goods_list)){
                    foreach($_goods_list as $key=>$val){
                        $goods =  explode(',', $val);
                        $goods[0] = isset($item[$goods[0]]) ? explode('%%', $item[$goods[0]])[0] : '--';
                        $goods[2] = (int)$goods[2] == 0 ? '不绑定' : '绑定';
                        $tool_arr[] = implode(' - ', $goods);
                    }
                }

                $data[] = [
                    'id'   => $value['boss_type_id'],
                    'name' => isset($monster[$value['boss_type_id']]) ? explode('%%', $monster[$value['boss_type_id']])[0] : '--',
                    'time' => date('Y-m-d H:i:s', $value['time']),
                    'goods'     => $tool_arr ? implode('；', $tool_arr) : '--',
                    'role_name' => $value['kill_role_names'] ? str_replace('||', '；', $value['kill_role_names']) : '--',
                ];
            }
        }

        return [
            'code'  => '0',
            'msg'   => '',
            'count' => $res['total'],
            'data'  => $data,
        ];
    }

    //boss日志 - 拾取记录
    public function bossGot(){
        return $this->fetch();
    }

    public function bossGotData(){
        $where = $data = [];

        $boss_type_id = $this->request->param('boss_type_id', 0, 'int');
        if($boss_type_id > 0)
            $where['boss_type_id'] = $boss_type_id;

        $send_time = $this->request->param('send_time', '', 'trim');
        if(!empty($send_time)){
            list($begin, $end) = explode(' - ', $send_time);
            $begin             = strtotime($begin);
            $end               = strtotime($end) + 86400 - 1;
            if($begin != '' && $end != '')
                $where['time'] = [['>', $begin], ['<', $end]];
        }

        $role_name = $this->request->param('role_name', '', 'trim');
        if($role_name != '')
            $where['role_name'] = ['like', "%$role_name%"];

        $limit= $this->request->param('limit', 30, 'int');
        $res = $this->region_connect
            ->name('world_boss_pick')
            ->where($where)
            ->order('id desc')
            ->paginate($limit)
            ->toArray();

        $monster = $this->getExcelConfig('execel_monster');
        $item    = $this->getExcelConfig('execel_item');
        $tmp     = $res['data'];

        if(!empty($tmp)){
            //渠道相关的数据
            extract( (new Channel())->processChannels($tmp) );

            foreach($tmp as $k=>&$value){
                $_goods_list = explode('||', $value['pick_goods_list']);
                $_goods_list = array_filter($_goods_list);
                $tool_arr = [];
                if(!empty($_goods_list)){
                    foreach($_goods_list as $key=>$val){
                        $goods =  explode(',', $val);
                        $goods[0] = isset($item[$goods[0]]) ? explode('%%', $item[$goods[0]])[0] : '--';
                        $goods[2] = (int)$goods[2] == 0 ? '不绑定' : '绑定';
                        $tool_arr[] = implode(' - ', $goods);
                    }
                }
                $data[] = [
                    'id'           => $value['boss_type_id'],
                    'name'         => isset($monster[$value['boss_type_id']]) ? explode('%%', $monster[$value['boss_type_id']])[0] : '--',
                    'role_name'    => $value['role_name'],
                    'time'         => date('Y-m-d H:i:s', $value['time']),
                    'goods'        => $tool_arr ? implode('；', $tool_arr) : '--',
                    'channel'      => isset($channel_name[$value['channel_id']]) ? $channel_name[$value['channel_id']] : '--',
                    'game_channel' => isset($game_channel_name[$value['game_channel_id']]) ? $game_channel_name[$value['game_channel_id']] : '--',
                ];
            }
        }

        return [
            'code'  => '0',
            'msg'   => '',
            'count' => $res['total'],
            'data'  => $data,
        ];
    }

    public function ranking(){
        $time      = $this->request->param('time', '', 'trim');
        $rank_type = $this->request->param('rank_type', 0, 'int');
        $limit     = $this->request->param('limit', 30, 'int');

        if(!$this->request->isAjax()){
            $rank_type_arr = [
                '10001'=> '战力排行',
                '10002'=> '等级排行',
                '10003'=> '坐骑战力排行',
                '10004'=> '法宝战力排行',
                '10005'=> '宠物战力排行',
                '10006'=> '神兵战力排行',
                '10007'=> '翅膀战力排行',
            ];
            $this->assign('time', $time);
            $this->assign('rank_type_arr', $rank_type_arr);
            $this->assign('first_rank_type', array_keys($rank_type_arr)[0]);
            return $this->fetch();
        }

        $begin = $end = '';
        if($time !='' ){
            list($begin, $end) = explode(' - ', $time);
            $begin = strtotime($begin);
            $end   = strtotime($end) + 86400 - 1;
        }

        $map = array_filter([
            'rank_type' => $rank_type,
            'time'      => $begin != '' ? ['between', [$begin, $end]] : '',
        ]);

        $model = $this->region_connect->name('rank');

        $data = $model->where($map)
            ->field('id, time,role_name,role_vip_level, role_rank')
            ->order('role_rank desc')
            ->paginate($limit)
            ->toArray();

        $data = $data['data'];
        if(!empty($data)){
            foreach($data as &$v)
                $v['time'] = date('Y-m-d H:i:s', $v['time']);
        }

        return [
            'code'  => '0',
            'msg'   => '',
            'count' => $model->where($map)->count(),
            'data'  => $data,
        ];
    }

    public function rename(){
        return $this->fetch('public/null');
    }

    public function equipment(){
        if(!$this->request->isAjax())
            return $this->fetch();

        $type    = $this->request->param('type', 0, 'int');
        $role_id = $this->request->param('role_id', 0, 'int');
        $time    = $this->request->param('time', '', 'trim');
        $page    = $this->request->param('page', 1, 'int');
        $limit   = $this->request->param('limit', 15, 'int');

        $data  = $map = [];
        $count = 0;

        if($role_id > 0)
            $map['e.role_id'] = $role_id;

        if($time){
            list($begin, $end) = explode(' - ', $time);
            $begin = strtotime($begin);
            $end   = strtotime($end) + 86400 - 1;
            $map['e.time'] = ['between', "$begin,$end"];
        }

        switch($type){
            case 1:
                $data = $this->region_connect->name('equip_refine')
                    ->alias('e')
                    ->join('role_status r','e.role_id = r.role_id', "LEFT")
                    ->field("e.*,r.role_name")
                    ->where($map)
                    ->order('e.time desc')
                    ->paginate($limit)->toArray();
                $count = $this->region_connect->name('equip_refine')->alias('e')->where($map)->count();
                break;
            case 2:
                $data = $this->region_connect->name('equip_stone')
                    ->alias('e')
                    ->join('role_status r','e.role_id = r.role_id', "LEFT")
                    ->field("e.*,r.role_name")
                    ->where($map)
                    ->order('e.time desc')
                    ->paginate($limit)->toArray();
                $count = $this->region_connect->name('equip_stone')->alias('e')->where($map)->count();
                break;
            default:
        }

        $data = isset($data['data']) ? $data['data'] : [];
        if(empty($data)){
            return [
                'code'  => '0',
                'msg'   => '',
                'count' => $count,
                'data'  => $data,
            ];
        }

        //渠道相关的数据
        extract( (new Channel())->processChannels($data) );

        //取出道具数据
        $item = $this->getExcelConfig('execel_item');

        $action_type = ['镶嵌', '拆卸'];
        foreach($data as &$v){
            if(isset($v['stone_id'])){
                $stone = isset($item[$v['stone_id']]) ? explode('%%', $item[$v['stone_id']]) : [];
                $v['stone'] = $stone ? reset($stone) : '--';
            }

            $equip = isset($item[$v['equip_id']]) ? explode('%%', $item[$v['equip_id']]) : [];
            $v['equip'] = $equip ? reset($equip) : '--';
            $v['time']  = date('Y-m-d H:i:s', $v['time']);
            $v['action_type']  = (isset($v['action_type']) && isset($action_type[$v['action_type']-1])) ? $action_type[$v['action_type']-1] : '--';
            $v['channel_name'] = isset($channel_name[$v['channel_id']]) ? $channel_name[$v['channel_id']] : '--';
            $v['game_channel_name'] = isset($game_channel_name[$v['game_channel_id']]) ? $game_channel_name[$v['game_channel_id']] : '--';
        }
        unset($v);

        return [
            'code'  => '0',
            'msg'   => '',
            'count' => $count,
            'data'  => $data,
        ];
    }

    public function sword(){
        return $this->fetch('public/null');
    }

    public function immortal(){
        return $this->fetch('public/null');
    }

    public function time(){
        return $this->fetch('public/null');
    }
}
