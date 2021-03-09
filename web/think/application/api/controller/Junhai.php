<?php
namespace app\api\controller;

use think\Request;
use think\Log;

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
            Log::write($return, '=======10400========');
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
        Log::write($return, '=======10200========');
        $this->returnJson(10200, '', $return);
    }

    //服务端支付回调接口
    public function paidCallBack(){
        $parma = $this->request->param();
        if(in_array('', $parma)){
            echo json_encode(['ret'=>0]);
            die;
        }

        //验证sign
        $sign  = $parma['sign'];
        unset($parma['sign']);
        $parma['app_secret'] = config('jh_app_secret');
        ksort($parma);
        if( $sign != urlencode(md5(http_build_query($parma))) ){
            echo json_encode(['ret'=>0]);
            die;
        }

        //fixme

        $this->returnJson(10200, '', $parma);
    }
}
