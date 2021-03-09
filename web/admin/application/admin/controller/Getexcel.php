<?php
namespace app\admin\controller;

use think\Db;
use think\Log;

/**
 * 
 */
class Getexcel extends Main
{
	
	function getExcel(){
		$type = $this->request->param('type', 0, 'int');

		$type_arr = [
			'1' => ['用户信息', 'userInfo'],
			'2' => ['机型转化', 'model_conversion'],
		];
		if(!isset($type_arr[$type])){
            return ;
		} else {
			list($name,$function) = $type_arr[$type];
			$this->$function($name);
		}
	}

	// 用户信息
	public function userInfo($name){
		$data = $gold_all = [];

		// 获取开服时间
		$create_time = $this->region_connect->name('role_create')->order('time asc')->column('role_id,time');
		$start_time = reset($create_time);
		$start_time = empty($create_time) ? time() : strtotime(date('Y-m-d', reset($create_time)));
		$day = ceil((time() - $start_time) / 86400);
		
		for ($i=0; $i < $day; $i++) { 
			//开始时间 今天 - 几天
			$begin_time = strtotime(date('Y-m-d',time())) - ($i * 86400);
			$end_time = $begin_time + 86400;
			$where = ['time' => ['between', "$begin_time,$end_time"]];

			// 当天登出
			$logout_data = $this->region_connect
			    ->name('role_logout')
			    ->field('role_id,online_time,time')
			    ->where($where)
			    ->select();
			$role_id = $online_time = $role_info = [];
			// 获取每个角色当天的在线时长
			foreach ($logout_data as $key => $v) {
				$online_time[$v['role_id']][] = $v['online_time'];
				if(!in_array($v['role_id'], $role_info))
					$role_info[] = $v['role_id'];
			}

			// 当天消耗元宝
			$where['action'] = ['between', '60000,69999'];
			$gold = $this->region_connect->name('gold')->where($where)->group('role_id')->column('role_id,sum(gold) as gold');
			foreach ($gold as $key => $v) {
				$gold_all[$key][] = $v;
			}
			
			foreach ($role_info as $k => $v) {
				$login_time = $this->region_connect->name('role_login')->where(['role_id'=>$v])->order('time desc')->value('time');
				if(!in_array($v, $role_id)){
					$parm = [
			            'time'      => time(),
			            'ticket'    => md5(time(). config('erlang_salt')),
			            'action'    => 'get_role_info',
			            'role_id'   => $v,
			        ];
			        $role_data = curl( $this->message_send_to_url. '/?'. http_build_query($parm) );
			        $role_data_arr[$v] = isset($role_data['data']) ? $role_data['data'] : [];
			        $role_id[] = $v;
				}

				$data[$k]['role_id'] = ' '.$role_data_arr[$v]['role_basic']['role_id']; //角色ID
				$data[$k]['role_name'] = $role_data_arr[$v]['role_basic']['role_name']; // 角色名
				$data[$k]['vip_level'] = $role_data_arr[$v]['role_basic']['vip_level']; //VIP等级
				$data[$k]['pay'] = '--'; //累计充值
				$data[$k]['die'] = $role_data_arr[$v]['role_basic']['relive_level']; //转生
				$data[$k]['power'] = $role_data_arr[$v]['role_basic']['power']; //战力
				$data[$k]['used_gold'] = isset($gold[$v]) ? $gold[$v] : 0; //当天消耗元宝
				$data[$k]['used_gold_all'] = isset($gold_all[$v]) && !empty($gold_all[$v]) ? array_sum($gold_all[$v]) : 0; //累计消耗元宝
				$data[$k]['category'] = $role_data_arr[$v]['role_basic']['category']; //职业
				$data[$k]['create'] = date('Y-m-d', $create_time[$v]); //注册时间
				$data[$k]['mapid'] = $role_data_arr[$v]['role_basic']['map_id']; //场景id
				$data[$k]['online'] = isset($online_time[$v]) && !empty($online_time[$v]) ? array_sum($online_time[$v]) : 0;//当天在线时长
				$data[$k]['logout_time'] = date('Y/m/d', $login_time); //最后一次登录时间
				$data[$k]['equip'] = '';//装备信息
				foreach ($role_data_arr[$v] as $key => $val) {
					if(isset($val['equip_list'])&&!empty($val['equip_list'])){
						foreach ($val['equip_list'] as $value) {
							$data[$k]['equip'] .= $value['equip_id'].','; //装备信息
						}
						$data[$k]['equip'] = trim($data[$k]['equip'], ',');
					}
				}
				$data[$k]['family'] = $role_data_arr[$v]['role_basic']['family_name'];  //帮派
			}
		}
		

		$title = array_values(['角色ID', '角色名', 'VIP等级', '累计充值', '转生等级', '战力', '当天消耗元宝', '累计消耗元宝', '职业', '注册时间', '流失任务或场景ID', '当天在线时长(min)', '日志时间(最后一次登录时间)', '装备信息', '帮派']);
		$data = array_merge([$title], $data);
		$excel_header = [
			['A', 30],
			['B', 15],
			['C', 10],
			['D', 10],
			['E', 10],
			['F', 10],
			['G', 10],
			['H', 10],
			['I', 10],
			['J', 20],
			['K', 30],
			['L', 20],
			['M', 20],
			['N', 30],
			['O', 30],
		];
		exportExcel($data, $excel_header, $name);
	} 

	// 机型转化
	public function model_conversion($name){
		$data = [];
		$imei = $where = [];

		// 连接技术埋点数据库获取数据
		$game_logs = config('database.game_logs');
		$link = DB::connect($game_logs);
		$where['imei'] = [
			['neq', ''],
			['neq', 'unknown'],
		];
		$imei_data = $link->name('patch')->group('imei')->where($where)->column('imei');
		$imei = implode(',', $imei_data);
		$patch = array_flip($imei_data);
		$where['imei'] = array_merge([['in', "$imei"]], $where['imei']);

		$first_open 	 	  = $link->name('first_open')->where($where)->column('imei');  // 首次打开
		$first_open 		  = array_flip($first_open);
		// $patch 				  = $link->name('patch')->where('imei', 'in', $imei)->column('imei'); // 补丁相关
		// $patch 				  = array_flip($patch);
		$account_register 	  = $link->name('account_register')->where($where)->column('imei,client_type,client_version');  // 账号注册
		$account_login_logout = $link->name('account_login_logout')->where($where)->column('imei');  // 账号登录登出
		$account_login_logout = array_flip($account_login_logout);
		$serverid_login_logout= $link->name('serverid_login_logout')->where($where)->column('imei');  // 区账号登录登出
		$serverid_login_logout= array_flip($serverid_login_logout);

		// 获取日志数据库数据
		$databases = [
			'admin_junhai_1',
            'admin_junhai_2',
            'admin_junhai_3',
            'admin_junhai_4',
		];
		$role_login_all = $role_create_all = [];
		foreach ($databases as $key => $value) {
			$database_config = [
                'hostname' => '115.159.68.105',
                'database' => $value,
                'type'     => 'mysql',
                'username' => 'datauser',
                'password' => 'mfpmaLSTAfwQJ13mBoSFDc4m0bmfCQgd',
                'hostport' => '3306',
                'charset'  => 'utf8',
                'prefix'   => 'log_',
            ];
            $role_create = DB::connect($database_config)->name('role_create')->where('imei', 'in', $imei)->column('imei');
            $role_create_all += array_flip($role_create);
            $role_login = DB::connect($database_config)->name('role_login')->where('imei', 'in', $imei)->column('imei');
            $role_login_all += array_flip($role_login);
		}
		foreach ($imei_data as $k => $v) {
			$data[$k]['model'] = '';
			foreach ($account_register as $val) {
				if($val['imei'] == $v)
					$data[$k]['model'] = $val['client_type'].'('.$val['client_version'].')'; // 机型
			}
			$data[$k]['first_open'] 	 	  = isset($first_open[$v]) ? 1 : ''; // 机型首次打开
			$data[$k]['patch']    		  	  = isset($patch[$v]) ? 1 : ''; // 补丁相关
			$data[$k]['account_register'] 	  = isset($account_register[$v]) ? 1 : ''; // 账号注册
			$data[$k]['account_login_logout'] = isset($account_login_logout[$v]) ? 1 : ''; // 账号登录登出
			$data[$k]['serverid_login_logout']= isset($serverid_login_logout[$v]) ? 1 : ''; // 区账号登录登出
			$data[$k]['create'] 			  = isset($role_create_all[$v]) ? 1 : ''; // 创建角色
			$data[$k]['login'] 			 	  = isset($role_login_all[$v]) ? 1 : ''; // 进入游戏
		}
		
		$title = array_values([
			'model'=>'手机品牌(具体机型)', 
			'first_open'=>'首次打开', 
			'patch'=>'更新加载', 
			'account_register'=>'账号注册', 
			'account_login_logout'=>'账号登录', 
			'serverid_login_logout'=>'进入区服', 
			'create'=>'创建角色', 
			'login'=>'进入游戏',
		]);
		$data = array_merge([$title], $data);
		$excel_header = [
			['A', 20],
			['B', 10],
			['C', 10],
			['D', 10],
			['E', 10],
			['F', 10],
			['G', 10],
			['H', 10],
		];
		exportExcel($data, $excel_header, $name);
	}
}
