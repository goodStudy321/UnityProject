<?php
/**
 * Created by PhpStorm.
 * User: laijichang
 * Date: 2018/3/13
 * Time: 11:45
 */

class AuthLoginModel extends CI_Model
{

    public function __construct()
    {
        parent::__construct();
        // Your own constructor code
    }

    public function auth()
    {
        $data = $this->input->get();
        $body = $this -> getRequestBody($data);

        $loginURL = config_item('jh_login_node');
        $client = new \GuzzleHttp\Client();
        $options['headers'] = ['content-type' => 'application/x-www-form-urlencoded'];
        $options['body'] = $body;
        $options['timeout'] = 3000;
        log_message('debug', print_r($options, true));
        $response = $client->request('post', $loginURL, $options);
        $this -> response($response);
    }

    // 响应返回
    private function response($response)
    {
        if($response -> getStatusCode())
        {
            $body = $response->getBody();
            $array = (array)json_decode($body);
            log_message('debug', print_r($array, true));
            if ($array["ret"] == 1) // 成功
            {
                $content = (array)$array['content'];
                $userID = urldecode($content['user_id']);
                $accessToken = urldecode($content['access_token']);
                $loginInfo = [
                    "uid" => $userID,
                    "token" => $accessToken
                ];
                $return = [
                    "code" => 0,
                    "loginInfo" => $loginInfo
                ];
                echo json_encode($return);
            }
            elseif($array['ret'] == 0){
                $return = [
                    "code" => 1,
                    "loginInfo" => ""
                ];
                echo json_encode($return);
            }
        }
    }

    private function getRequestBody($data)
    {
        $array = [];
        $array['channel_id'] = $this -> getValue($data, 'channel_id');
        $array['game_id'] = $this -> getValue($data, 'game_id');
        $array['game_channel_id'] = $this -> getValue($data, 'game_channel_id');
        $array['uid'] = $this -> getValue($data, 'uid');
        $array['session_id'] = $this -> getValue($data, 'session_id');
        $body = http_build_query($array);
        return $body;
    }

    private function getValue($array, $key)
    {
        if(array_key_exists($key, $array)){
            return $array[$key];
        }else{
            return "";
        }
    }
}
