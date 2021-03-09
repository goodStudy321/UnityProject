<?php
namespace app\index\controller;

use think\Log;
use think\Db;
use app\common\Base;

//君海相关的接口类
class Junhai extends Base{

    public function __construct(){
        parent::__construct();
    }

    public function index() {
        $this->returnJson(10200);
    }

    //认证登录
    public function auth(){
        $data = $this->request->param();
        $data = http_build_query([
            'channel_id'      => isset($data['channel_id'])      ? $data['channel_id'] : '',
            'game_id'         => isset($data['game_id'])         ? $data['game_id'] : '',
            'game_channel_id' => isset($data['game_channel_id']) ? $data['game_channel_id'] : '',
            'uid'             => isset($data['uid'])             ? $data['uid'] : '',
            'session_id'      => isset($data['session_id'])      ? $data['session_id'] : '',
            'user_name' => '',
            'others' => '',
        ]);
        $headers = ['content-type:application/x-www-form-urlencoded'];
        $url = config('jh_login_node'). '/?'. $data;
        $result  = curl($url, $data, $headers);

        //错误
        $return = [
            'code'      => 1,
            'loginInfo' => '',
        ];
        if($result['ret'] == 0){
            Log::write($return, 'debug:10400');
            $this->returnJson(10400, $result['msg'], $return);
        }

        //成功
        $return = [
            'code'      => 0,
            'loginInfo' => [
                'uid'   => urldecode($result['content']['user_id']),
                'token' => urldecode($result['content']['access_token']),
            ]
        ];
        Log::write($return, 'debug:10200');
        $this->returnJson(10200, '', $return);
    }

    //服务端支付回调接口
    public function paidCallBack(){
        $parma = $this->request->param();
        $parma = $insert_data = [
            'app_id'            => isset($parma['app_id'])            ? $parma['app_id']            : '',
            'channel_id'        => isset($parma['channel_id'])        ? $parma['channel_id']        : '',
            'game_channel_id'   => isset($parma['game_channel_id'])   ? $parma['game_channel_id']   : '',
            'product_id'        => isset($parma['product_id'])        ? $parma['product_id']        : '',
            'total_fee'         => isset($parma['total_fee'])         ? $parma['total_fee']         : '',
            'app_role_id'       => isset($parma['app_role_id'])       ? $parma['app_role_id']       : '',
            'user_id'           => isset($parma['user_id'])           ? $parma['user_id']           : '',
            'jh_order_id'       => isset($parma['jh_order_id'])       ? $parma['jh_order_id']       : '',
            'app_order_id'      => isset($parma['app_order_id'])      ? $parma['app_order_id']      : '',
            'server_id'         => isset($parma['server_id'])         ? $parma['server_id']         : '',
            'pay_result'        => isset($parma['pay_result'])        ? $parma['pay_result']        : '',
            'time'              => isset($parma['time'])              ? $parma['time']              : '',
            'interface_version' => isset($parma['interface_version']) ? $parma['interface_version'] : '',
            'sign'              => isset($parma['sign'])              ? $parma['sign']              : '',
            'app_secret'        => config('jh_app_secret'),
        ];
        if(in_array('', $parma)){
            Log::write($parma, 'debug:1');
            die(json_encode(['ret'=>0, 'msg'=>'每个参数都不能为空']));
        }

        //1. 验证sign
        $sign = $parma['sign'];
        unset($parma['sign']);

        $parma = array_map(function($v){ //值进行urlencode
            return urlencode($v);
        }, $parma);

        ksort($parma); //降序
        $local_sign = md5(http_build_query($parma));

        //if( $sign != $local_sign ){
        //    Log::write($parma, 'debug:2');
        //    Log::write("$sign != $local_sign", 'debug:3');
        //    die(json_encode(['ret'=>0, 'msg'=>'sign 校验失败']));
        //}

        $payModel = Db::name('pay_info');

        //2. 写入数据库
        unset($insert_data['app_secret']);
        $info_id = $payModel->insertGetId($insert_data);
        if(!$info_id){
            Log::write('写入数据库出错', 'debug:4');
            die(json_encode(['ret'=>0, 'msg'=>'写入数据库出错']));
        }

        //3. 通知游戏后台 //http://192.168.2.250:30001/?action=pay&order_id=3&role_id=10000100000020&product_id=1&total_fee=1800
        //解析role_id 得到 agent_id 和 server_id
        $agent_id_server_id = floor($parma['app_role_id'] / 100000000);
        list($agent_id, $server_id) = explode('.', $agent_id_server_id / 100000);
        $map = [
            'agent_id'  => (int)$agent_id,
            'server_id' => (int)$server_id,
        ];

        //通知要发到哪台区服
        $url = Db::name('config')->where($map)->value('title');
        $url = $url ? json_decode($url, true) : [];
        $url = isset($url['other']['send_to_url']) ? $url['other']['send_to_url'] : '';
        if($url == ''){
            Log::write('send_to_url 为空', 'debug:5');
            die(json_encode(['ret'=>0, 'msg'=>'系统配置有误']));
        }

        //组装参数
        $url_param = [
            'action'     => 'pay',
            'order_id'   => $parma['app_order_id'],
            'role_id'    => $parma['app_role_id'],
            'product_id' => $parma['product_id'],
            'total_fee'  => $parma['total_fee'],
        ];
        $url .= '/?'. http_build_query($url_param);

        //发送通知
        $game_server = curl($url);
        Log::write('url:['. $url . '] --- result:'. print_r($game_server, true), 'debug:6');

        $game_server = isset($game_server['ret']) ? (int)$game_server['ret'] : 0;
        if($game_server == 0){
            Log::write('游戏后台服务器确认失败', 'debug:7');
            die(json_encode(['ret'=>0, 'msg'=>'数据已写入，但游戏后台服务器确认失败']));
        }

        $update = $payModel->where('id='.$info_id)->update(['status' => 1]);
        if(!$update)
            Log::write('修改状态失败', 'debug:8');

        die(json_encode(['ret'=>1, 'msg'=>'成功']));
    }
}
