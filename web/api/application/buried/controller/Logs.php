<?php
namespace app\buried\controller;

use think\Request;

/**
 * 技术埋点模块 - 日志控制器
*/
class Logs extends Main {

    public $post = [];

    public function __construct(){
        parent::_initialize();

        $post = Request::instance()->post();
        $this->post = [
            'time'=>                    isset($post['time']                     ) ? $post['time']                     : '',
            'server_id'=>               isset($post['server_id']                ) ? $post['server_id']                : '',
            'log_time'=>                isset($post['log_time']                 ) ? $post['log_time']                 : '',
            'account_id'=>              isset($post['account_id']               ) ? $post['account_id']               : '',
            'uid'=>                     isset($post['uid']                      ) ? $post['uid']                      : '',
            'user_register_channel_id'=>isset($post['user_register_channel_id'] ) ? $post['user_register_channel_id'] : '',
            'user_login_channel_id'=>   isset($post['user_login_channel_id']    ) ? $post['user_login_channel_id']    : '',
            'mobile_os_type'=>          isset($post['mobile_os_type']           ) ? $post['mobile_os_type']           : '',
            'user_add_time'=>           isset($post['user_add_time']            ) ? $post['user_add_time']            : '',
            'mobile_operator'=>         isset($post['mobile_operator']          ) ? $post['mobile_operator']          : '',
            'network_type'=>            isset($post['network_type']             ) ? $post['network_type']             : '',
            'client_type'=>             isset($post['client_type']              ) ? $post['client_type']              : '',
            'client_version'=>          isset($post['client_version']           ) ? $post['client_version']           : '',
            'game_version'=>            isset($post['game_version']             ) ? $post['game_version']             : '',
            'ip'=>                      isset($post['ip']                       ) ? $post['ip']                       : '',
            'imei'=>                    isset($post['imei']                     ) ? $post['imei']                     : '',
            'mac'=>                     isset($post['mac']                      ) ? $post['mac']                      : '',
            'sdk_version'=>             isset($post['sdk_version']              ) ? $post['sdk_version']              : '',
            'sdk_id'=>                  isset($post['sdk_id']                   ) ? $post['sdk_id']                   : '',
            'os_version'=>              isset($post['os_version']               ) ? $post['os_version']               : '',
            'os_type'=>                 isset($post['os_type']                  ) ? $post['os_type']                  : '',
            'cpu_name'=>                isset($post['cpu_name']                 ) ? $post['cpu_name']                 : '',
            'cpu_version'=>             isset($post['cpu_version']              ) ? $post['cpu_version']              : '',
            'cpu_frequency'=>           isset($post['cpu_frequency']            ) ? $post['cpu_frequency']            : '',
            'cpu_core_number'=>         isset($post['cpu_core_number']          ) ? $post['cpu_core_number']          : '',
            'gpu_name'=>                isset($post['gpu_name']                 ) ? $post['gpu_name']                 : '',
            'gpu_frequency'=>           isset($post['gpu_frequency']            ) ? $post['gpu_frequency']            : '',
            'gpu_core_number'=>         isset($post['gpu_core_number']          ) ? $post['gpu_core_number']          : '',
            'memory'=>                  isset($post['memory']                   ) ? $post['memory']                   : '',
            'now_memory_free'=>         isset($post['now_memory_free']          ) ? $post['now_memory_free']          : '',
            'memory_isFull'=>           isset($post['memory_isFull']            ) ? $post['memory_isFull']            : '',
            'disk_size'=>               isset($post['disk_size']                ) ? $post['disk_size']                : '',
            'now_disk_size_free'=>      isset($post['now_disk_size_free']       ) ? $post['now_disk_size_free']       : '',
            'sd_max_size'=>             isset($post['sd_max_size']              ) ? $post['sd_max_size']              : '',
            'now_sd_free'=>             isset($post['now_sd_free']              ) ? $post['now_sd_free']              : '',
            'resolution'=>              isset($post['resolution']               ) ? $post['resolution']               : '',
            'baseband_version'=>        isset($post['baseband_version']         ) ? $post['baseband_version']         : '',
            'core_version'=>            isset($post['core_version']             ) ? $post['core_version']             : '',
            'OpenGL_RENDERER'=>         isset($post['OpenGL_RENDERER']          ) ? $post['OpenGL_RENDERER']          : '',
            'OpenGL_VENDOR'=>           isset($post['OpenGL_VENDOR']            ) ? $post['OpenGL_VENDOR']            : '',
            'OpenGL_VERSION'=>          isset($post['OpenGL_VERSION']           ) ? $post['OpenGL_VERSION']           : '',
            'statistics_obj'=>          isset($post['statistics_obj']           ) ? $post['statistics_obj']           : '',
            'statistics_type'=>         isset($post['statistics_type']          ) ? $post['statistics_type']          : '',
            'action_code'=>             isset($post['action_code']              ) ? $post['action_code']              : '',
            'associated_obj'=>          isset($post['associated_obj']           ) ? $post['associated_obj']           : '',
            'action_result'=>           isset($post['action_result']            ) ? $post['action_result']            : '',
            'statistics_field'=>        isset($post['statistics_field']         ) ? $post['statistics_field']         : '',
            'vip_level'=>               isset($post['vip_level']                ) ? $post['vip_level']                : '',
            'role_level'=>              isset($post['role_level']               ) ? $post['role_level']               : '',
            'power'=>                   isset($post['power']                    ) ? $post['power']                    : '',
            'career'=>                  isset($post['career']                   ) ? $post['career']                   : '',
            'career_level'=>            isset($post['career_level']             ) ? $post['career_level']             : '',
        ];

    }

    public function index() {
        $this->returnJson(10200);
    }

    //机型首次打开
    public function firstOpen() {
        $must = [
            $this->post['time'],
            $this->post['server_id'],
            $this->post['log_time'],
            $this->post['account_id'],
            $this->post['user_register_channel_id'],
            $this->post['user_login_channel_id'],
            $this->post['mobile_os_type'],
            $this->post['user_add_time'],
        ];
        if(in_array('', $must))
            $this->returnJson(10400, '参数不对');

        $data  = [
            'log_name'                 => 'user_info',
            'type'                     => 'model_first_open',
            'time'                     => $this->post['time'],
            'server_id'                => $this->post['server_id'],
            'log_time'                 => $this->post['log_time'],
            'account_id'               => $this->post['account_id'],
            'uid'                      => $this->post['uid'],
            'user_register_channel_id' => $this->post['user_register_channel_id'],
            'user_login_channel_id'    => $this->post['user_login_channel_id'],
            'mobile_os_type'           => $this->post['mobile_os_type'],
            'user_add_time'            => $this->_getUserAddTime('first_open', $this->post['account_id']),
            'mobile_operator'          => $this->post['mobile_operator'],
            'network_type'             => $this->post['network_type'],
            'client_type'              => $this->post['client_type'],
            'client_version'           => $this->post['client_version'],
            'game_version'             => $this->post['game_version'],
            'ip'                       => $this->post['ip'],
            'imei'                     => $this->post['imei'],
            'mac'                      => $this->post['mac'],
            'sdk_version'              => $this->post['sdk_version'],
            'sdk_id'                   => $this->post['sdk_id'],
            'os_version'               => $this->post['os_version'],
            'os_type'                  => $this->post['os_type'],
            'cpu_name'                 => $this->post['cpu_name'],
            'cpu_version'              => $this->post['cpu_version'],
            'cpu_frequency'            => $this->post['cpu_frequency'],
            'cpu_core_number'          => $this->post['cpu_core_number'],
            'gpu_name'                 => $this->post['gpu_name'],
            'gpu_frequency'            => $this->post['gpu_frequency'],
            'gpu_core_number'          => $this->post['gpu_core_number'],
            'memory'                   => $this->post['memory'],
            'now_memory_free'          => $this->post['now_memory_free'],
            'memory_isFull'            => $this->post['memory_isFull'],
            'disk_size'                => $this->post['disk_size'],
            'now_disk_size_free'       => $this->post['now_disk_size_free'],
            'sd_max_size'              => $this->post['sd_max_size'],
            'now_sd_free'              => $this->post['now_sd_free'],
            'resolution'               => $this->post['resolution'],
            'baseband_version'         => $this->post['baseband_version'],
            'core_version'             => $this->post['core_version'],
            'OpenGL_RENDERER'          => $this->post['OpenGL_RENDERER'],
            'OpenGL_VENDOR'            => $this->post['OpenGL_VENDOR'],
            'OpenGL_VERSION'           => $this->post['OpenGL_VERSION'],
        ];

        $result = $this->connection->name('first_open')->insert($data);

        if($result)
            $this->returnJson(10200, '保存成功');
        else
            $this->returnJson(10400, '保存失败');
    }

    //机型注册
    public function modelRegister() {
        $must = [
            $this->post['time'],
            $this->post['server_id'],
            $this->post['log_time'],
            $this->post['account_id'],
            $this->post['user_register_channel_id'],
            $this->post['user_login_channel_id'],
            $this->post['mobile_os_type'],
            $this->post['user_add_time'],
        ];
        if(in_array('', $must))
            $this->returnJson(10400, '参数不对');

        $data  = [
            'log_name'                 => 'user_info',
            'type'                     => 'model_reg',
            'time'                     => $this->post['time'],
            'server_id'                => $this->post['server_id'],
            'log_time'                 => $this->post['log_time'],
            'account_id'               => $this->post['account_id'],
            'uid'                      => $this->post['uid'],
            'user_register_channel_id' => $this->post['user_register_channel_id'],
            'user_login_channel_id'    => $this->post['user_login_channel_id'],
            'mobile_os_type'           => $this->post['mobile_os_type'],
            'user_add_time'            => $this->_getUserAddTime('model_register', $this->post['account_id']),
            'mobile_operator'          => $this->post['mobile_operator'],
            'network_type'             => $this->post['network_type'],
            'client_type'              => $this->post['client_type'],
            'client_version'           => $this->post['client_version'],
            'game_version'             => $this->post['game_version'],
            'ip'                       => $this->post['ip'],
            'imei'                     => $this->post['imei'],
            'mac'                      => $this->post['mac'],
            'sdk_version'              => $this->post['sdk_version'],
            'sdk_id'                   => $this->post['sdk_id'],
            'os_version'               => $this->post['os_version'],
            'os_type'                  => $this->post['os_type'],
            'cpu_name'                 => $this->post['cpu_name'],
            'cpu_version'              => $this->post['cpu_version'],
            'cpu_frequency'            => $this->post['cpu_frequency'],
            'cpu_core_number'          => $this->post['cpu_core_number'],
            'gpu_name'                 => $this->post['gpu_name'],
            'gpu_frequency'            => $this->post['gpu_frequency'],
            'gpu_core_number'          => $this->post['gpu_core_number'],
            'memory'                   => $this->post['memory'],
            'now_memory_free'          => $this->post['now_memory_free'],
            'memory_isFull'            => $this->post['memory_isFull'],
            'disk_size'                => $this->post['disk_size'],
            'now_disk_size_free'       => $this->post['now_disk_size_free'],
            'sd_max_size'              => $this->post['sd_max_size'],
            'now_sd_free'              => $this->post['now_sd_free'],
            'resolution'               => $this->post['resolution'],
            'baseband_version'         => $this->post['baseband_version'],
            'core_version'             => $this->post['core_version'],
            'OpenGL_RENDERER'          => $this->post['OpenGL_RENDERER'],
            'OpenGL_VENDOR'            => $this->post['OpenGL_VENDOR'],
            'OpenGL_VERSION'           => $this->post['OpenGL_VERSION'],
        ];

        $result = $this->connection->name('model_register')->insert($data);

        if($result)
            $this->returnJson(10200, '保存成功');
        else
            $this->returnJson(10400, '保存失败');

        $this->returnJson(10200);
    }

    //机型注册
    public function accountRegister() {
        $must = [
            $this->post['time'],
            $this->post['server_id'],
            $this->post['log_time'],
            $this->post['account_id'],
            $this->post['user_register_channel_id'],
            $this->post['user_login_channel_id'],
            $this->post['mobile_os_type'],
            $this->post['user_add_time'],
        ];
        if(in_array('', $must))
            $this->returnJson(10400, '参数不对');

        $data  = [
            'log_name'                 => 'user_info',
            'type'                     => 'model_reg',
            'time'                     => $this->post['time'],
            'server_id'                => $this->post['server_id'],
            'log_time'                 => $this->post['log_time'],
            'account_id'               => $this->post['account_id'],
            'uid'                      => $this->post['uid'],
            'user_register_channel_id' => $this->post['user_register_channel_id'],
            'user_login_channel_id'    => $this->post['user_login_channel_id'],
            'mobile_os_type'           => $this->post['mobile_os_type'],
            'user_add_time'            => $this->_getUserAddTime('account_register', $this->post['account_id']),
            'mobile_operator'          => $this->post['mobile_operator'],
            'network_type'             => $this->post['network_type'],
            'client_type'              => $this->post['client_type'],
            'client_version'           => $this->post['client_version'],
            'game_version'             => $this->post['game_version'],
            'ip'                       => $this->post['ip'],
            'imei'                     => $this->post['imei'],
            'mac'                      => $this->post['mac'],
            'sdk_version'              => $this->post['sdk_version'],
            'sdk_id'                   => $this->post['sdk_id'],
            'statistics_obj'           => $this->post['statistics_obj'],
            'statistics_type'          => $this->post['statistics_type'],
            'action_code'              => $this->post['action_code'],
            'associated_obj'           => $this->post['associated_obj'],
            'action_result'            => $this->post['action_result'],
            'statistics_field'         => $this->post['statistics_field'],
        ];

        $result = $this->connection->name('account_register')->insert($data);

        if($result)
            $this->returnJson(10200, '保存成功');
        else
            $this->returnJson(10400, '保存失败');

        $this->returnJson(10200);

    }

    //账号登录
    public function accountLoginLogout(){
        $must = [
            $this->post['time'],
            $this->post['server_id'],
            $this->post['log_time'],
            $this->post['account_id'],
            $this->post['user_register_channel_id'],
            $this->post['user_login_channel_id'],
            $this->post['mobile_os_type'],
            $this->post['user_add_time'],
        ];
        if(in_array('', $must))
            $this->returnJson(10400, '参数不对');

        $data  = [
            'log_name'                 => 'core_account',
            'type'                     => 'account_act',
            'time'                     => $this->post['time'],
            'server_id'                => $this->post['server_id'],
            'log_time'                 => $this->post['log_time'],
            'account_id'               => $this->post['account_id'],
            'uid'                      => $this->post['uid'],
            'user_register_channel_id' => $this->post['user_register_channel_id'],
            'user_login_channel_id'    => $this->post['user_login_channel_id'],
            'mobile_os_type'           => $this->post['mobile_os_type'],
            'user_add_time'            => $this->_getUserAddTime('account_login_logout', $this->post['account_id']),
            'mobile_operator'          => $this->post['mobile_operator'],
            'network_type'             => $this->post['network_type'],
            'client_type'              => $this->post['client_type'],
            'client_version'           => $this->post['client_version'],
            'game_version'             => $this->post['game_version'],
            'ip'                       => $this->post['ip'],
            'imei'                     => $this->post['imei'],
            'mac'                      => $this->post['mac'],
            'sdk_version'              => $this->post['sdk_version'],
            'sdk_id'                   => $this->post['sdk_id'],
            'statistics_obj'           => $this->post['statistics_obj'],
            'statistics_type'          => $this->post['statistics_type'],
            'action_code'              => $this->post['action_code'],
            'associated_obj'           => $this->post['associated_obj'],
            'action_result'            => $this->post['action_result'],
            'statistics_field'         => $this->post['statistics_field'],
        ];

        $result = $this->connection->name('account_login_logout')->insert($data);

        if($result)
            $this->returnJson(10200, '保存成功');
        else
            $this->returnJson(10400, '保存失败');

        $this->returnJson(10200);


    }

    //账号登录
    public function serveridRegister(){
        $must = [
            $this->post['time'],
            $this->post['server_id'],
            $this->post['log_time'],
            $this->post['account_id'],
            $this->post['user_register_channel_id'],
            $this->post['user_login_channel_id'],
            $this->post['mobile_os_type'],
            $this->post['user_add_time'],
        ];
        if(in_array('', $must))
            $this->returnJson(10400, '参数不对');

        $data  = [
            'log_name'                 => 'core_gamesvr',
            'type'                     => 'gamesvr_reg',
            'time'                     => $this->post['time'],
            'server_id'                => $this->post['server_id'],
            'log_time'                 => $this->post['log_time'],
            'account_id'               => $this->post['account_id'],
            'uid'                      => $this->post['uid'],
            'user_register_channel_id' => $this->post['user_register_channel_id'],
            'user_login_channel_id'    => $this->post['user_login_channel_id'],
            'mobile_os_type'           => $this->post['mobile_os_type'],
            'user_add_time'            => $this->_getUserAddTime('serverid_register', $this->post['account_id']),
            'mobile_operator'          => $this->post['mobile_operator'],
            'network_type'             => $this->post['network_type'],
            'client_type'              => $this->post['client_type'],
            'client_version'           => $this->post['client_version'],
            'game_version'             => $this->post['game_version'],
            'ip'                       => $this->post['ip'],
            'imei'                     => $this->post['imei'],
            'mac'                      => $this->post['mac'],
            'sdk_version'              => $this->post['sdk_version'],
            'sdk_id'                   => $this->post['sdk_id'],
            'statistics_obj'           => $this->post['statistics_obj'],
            'statistics_type'          => $this->post['statistics_type'],
            'action_code'              => $this->post['action_code'],
            'associated_obj'           => $this->post['associated_obj'],
            'action_result'            => $this->post['action_result'],
            'statistics_field'         => $this->post['statistics_field'],
        ];

        $result = $this->connection->name('serverid_register')->insert($data);

        if($result)
            $this->returnJson(10200, '保存成功');
        else
            $this->returnJson(10400, '保存失败');
    }

    //账号登录
    public function serveridLoginLogout(){
        $must = [
            $this->post['time'],
            $this->post['server_id'],
            $this->post['log_time'],
            $this->post['account_id'],
            $this->post['user_register_channel_id'],
            $this->post['user_login_channel_id'],
            $this->post['mobile_os_type'],
            $this->post['user_add_time'],
        ];
        if(in_array('', $must))
            $this->returnJson(10400, '参数不对');


        $data  = [
            'log_name'                 => 'core_gamesvr',
            'type'                     => 'gamesvr_act',
            'time'                     => $this->post['time'],
            'server_id'                => $this->post['server_id'],
            'log_time'                 => $this->post['log_time'],
            'account_id'               => $this->post['account_id'],
            'uid'                      => $this->post['uid'],
            'user_register_channel_id' => $this->post['user_register_channel_id'],
            'user_login_channel_id'    => $this->post['user_login_channel_id'],
            'mobile_os_type'           => $this->post['mobile_os_type'],
            'user_add_time'            => $this->_getUserAddTime('serverid_login_logout', $this->post['account_id']),
            'vip_level'                => $this->post['vip_level'],
            'mobile_operator'          => $this->post['mobile_operator'],
            'network_type'             => $this->post['network_type'],
            'client_type'              => $this->post['client_type'],
            'client_version'           => $this->post['client_version'],
            'game_version'             => $this->post['game_version'],
            'ip'                       => $this->post['ip'],
            'imei'                     => $this->post['imei'],
            'mac'                      => $this->post['mac'],
            'sdk_version'              => $this->post['sdk_version'],
            'sdk_id'                   => $this->post['sdk_id'],
            'statistics_obj'           => $this->post['statistics_obj'],
            'statistics_type'          => $this->post['statistics_type'],
            'action_code'              => $this->post['action_code'],
            'associated_obj'           => $this->post['associated_obj'],
            'action_result'            => $this->post['action_result'],
            'statistics_field'         => $this->post['statistics_field'],
        ];

        $result = $this->connection->name('serverid_login_logout')->insert($data);

        if($result)
            $this->returnJson(10200, '保存成功');
        else
            $this->returnJson(10400, '保存失败');
    }

    //账号登录
    public function roleRegister(){
        $must = [
            $this->post['time'],
            $this->post['server_id'],
            $this->post['log_time'],
            $this->post['account_id'],
            $this->post['user_register_channel_id'],
            $this->post['user_login_channel_id'],
            $this->post['mobile_os_type'],
            $this->post['user_add_time'],
            $this->post['vip_level'],
            $this->post['role_level'],
        ];
        if(in_array('', $must))
            $this->returnJson(10400, '参数不对');

        $data  = [
            'log_name'                 => 'core_role',
            'type'                     => 'role_reg',
            'time'                     => $this->post['time'],
            'server_id'                => $this->post['server_id'],
            'log_time'                 => $this->post['log_time'],
            'account_id'               => $this->post['account_id'],
            'uid'                      => $this->post['uid'],
            'user_register_channel_id' => $this->post['user_register_channel_id'],
            'user_login_channel_id'    => $this->post['user_login_channel_id'],
            'mobile_os_type'           => $this->post['mobile_os_type'],
            'user_add_time'            => $this->_getUserAddTime('role_register', $this->post['account_id']),
            'game_version'             => $this->post['game_version'],
            'vip_level'                => $this->post['vip_level'],
            'role_level'               => $this->post['role_level'],
            'power'                    => $this->post['power'],
            'career'                   => $this->post['career'],
            'career_level'             => $this->post['career_level'],
            'statistics_obj'           => $this->post['statistics_obj'],
            'statistics_type'          => $this->post['statistics_type'],
            'action_code'              => $this->post['action_code'],
            'associated_obj'           => $this->post['associated_obj'],
            'action_result'            => $this->post['action_result'],
            'statistics_field'         => $this->post['statistics_field'],
        ];

        $result = $this->connection->name('role_register')->insert($data);

        if($result)
            $this->returnJson(10200, '保存成功');
        else
            $this->returnJson(10400, '保存失败');
    }

    //账号登录
    public function clientError(){
        $must = [
            $this->post['time'],
            $this->post['server_id'],
            $this->post['log_time'],
            $this->post['account_id'],
            $this->post['user_register_channel_id'],
            $this->post['user_login_channel_id'],
            $this->post['mobile_os_type'],
            $this->post['user_add_time'],
        ];
        if(in_array('', $must))
            $this->returnJson(10400, '参数不对');

        $data  = [
            'log_name'                 => 'core_client',
            'type'                     => 'exception',
            'time'                     => $this->post['time'],
            'server_id'                => $this->post['server_id'],
            'log_time'                 => $this->post['log_time'],
            'account_id'               => $this->post['account_id'],
            'uid'                      => $this->post['uid'],
            'user_register_channel_id' => $this->post['user_register_channel_id'],
            'user_login_channel_id'    => $this->post['user_login_channel_id'],
            'mobile_os_type'           => $this->post['mobile_os_type'],
            'user_add_time'            => $this->_getUserAddTime('client_error', $this->post['account_id']),
            'mobile_operator'          => $this->post['mobile_operator'],
            'network_type'             => $this->post['network_type'],
            'client_type'              => $this->post['client_type'],
            'client_version'           => $this->post['client_version'],
            'game_version'             => $this->post['game_version'],
            'ip'                       => $this->post['ip'],
            'imei'                     => $this->post['imei'],
            'mac'                      => $this->post['mac'],
            'sdk_version'              => $this->post['sdk_version'],
            'sdk_id'                   => $this->post['sdk_id'],
            'statistics_obj'           => $this->post['statistics_obj'],
            'statistics_type'          => $this->post['statistics_type'],
            'action_code'              => $this->post['action_code'],
            'associated_obj'           => $this->post['associated_obj'],
            'action_result'            => $this->post['action_result'],
            'statistics_field'         => $this->post['statistics_field'],
        ];

        $result = $this->connection->name('client_error')->insert($data);

        if($result)
            $this->returnJson(10200, '保存成功');
        else
            $this->returnJson(10400, '保存失败');
    }
    //账号登录
    public function patch(){
        $must = [
            $this->post['time'],
            $this->post['server_id'],
            $this->post['log_time'],
            $this->post['account_id'],
            $this->post['user_register_channel_id'],
            $this->post['user_login_channel_id'],
            $this->post['mobile_os_type'],
            $this->post['user_add_time'],
        ];
        if(in_array('', $must))
            $this->returnJson(10400, '参数不对');

        $data  = [
            'log_name'                 => 'core_client',
            'type'                     => 'exception',
            'time'                     => $this->post['time'],
            'server_id'                => $this->post['server_id'],
            'log_time'                 => $this->post['log_time'],
            'account_id'               => $this->post['account_id'],
            'uid'                      => $this->post['uid'],
            'user_register_channel_id' => $this->post['user_register_channel_id'],
            'user_login_channel_id'    => $this->post['user_login_channel_id'],
            'mobile_os_type'           => $this->post['mobile_os_type'],
            'user_add_time'            => $this->_getUserAddTime('patch', $this->post['account_id']),
            'mobile_operator'          => $this->post['mobile_operator'],
            'network_type'             => $this->post['network_type'],
            'client_type'              => $this->post['client_type'],
            'client_version'           => $this->post['client_version'],
            'game_version'             => $this->post['game_version'],
            'ip'                       => $this->post['ip'],
            'imei'                     => $this->post['imei'],
            'mac'                      => $this->post['mac'],
            'sdk_version'              => $this->post['sdk_version'],
            'sdk_id'                   => $this->post['sdk_id'],
            'statistics_obj'           => $this->post['statistics_obj'],
            'statistics_type'          => $this->post['statistics_type'],
            'action_code'              => $this->post['action_code'],
            'associated_obj'           => $this->post['associated_obj'],
            'action_result'            => $this->post['action_result'],
            'statistics_field'         => $this->post['statistics_field'],
        ];

        $result = $this->connection->name('patch')->insert($data);

        if($result)
            $this->returnJson(10200, '保存成功');
        else
            $this->returnJson(10400, '保存失败');
    }

    public function _getUserAddTime($table, $account_id, $field = 'user_add_time'){
        $user_add_time = $this->connection->name($table)->where(['account_id'=>$account_id, $field =>['NEQ', '0'] ])->order('id asc')->limit(1)->value($field);
        return $user_add_time ? $user_add_time : time();
    }
}

