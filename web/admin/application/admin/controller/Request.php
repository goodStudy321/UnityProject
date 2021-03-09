<?php
namespace app\admin\controller;

use think\Controller;
use think\Db;

//激活码类
class Request extends controller {

    public function produce(){
        $post = file_get_contents('php://input');
        $post = json_decode($post,true);
        //$post = array('code_name'=>'7f4269b66a12245f','role_name'=>'杭莺','account_name'=>'hs35','role_level'=>'18','time'=>'123','ticket'=>'20480116c6c53b49bd7b6d3a9cb22db6','role_id'=>'1001');

        if(empty($post))
            return json_encode(array('code'=>101,'msg'=>'参数有误'));

        //验证
        if( $post['ticket'] != md5($post['time']. config('erlang_salt')) )
            return json_encode(array('code'=>305,'msg'=>'验证失败'));

        $actCreateModel  = Db::name('act_create');
        $actCodeModel    = Db::name('act_code');
        $actCodeOldModel = Db::name('act_code_old');

        //获取激活码数据
        $act_code = $actCodeModel->where('code_name="'.$post['code_name'].'"')->find();
        if(empty($act_code))
            return json_encode(array('code'=>401,'msg'=>'激活码错误或已被使用'));

        //查询此激活码是否被领取过
        $code_old = $actCodeOldModel->where('code_id='.$act_code['id'])->find();
        if(!empty($code_old)) //未领取执行领取操作
            return json_encode(array('code'=>401,'msg'=>'激活码错误或已被使用'));


        $act_create = $actCreateModel->where('id='.$act_code['create_id'])->find(); //当前激活码的所属属性

        $result = [];
        switch($act_create['code_status']){
            case 4: //4. "每个服务器/每个角色" 只能领取一次
                $result = $actCodeOldModel->where('create_id='.$act_code['create_id'])
                    ->where('role_id='.$post['role_id'].' OR server_id="'.$act_create['server_id'].'"')
                    ->find();
                break;
            case 3: //3. 每个服务器只能领取一次 (同一个激活码分类下)
                $result = $actCodeOldModel->where([
                    'server_id' => $act_create['server_id'],
                    'create_id' => $act_code['create_id'], //待定 fixme
                ])->find();
                break;
            case 2: //2. 每个账号只能领取一次 (同一个激活码分类下)
                $result = $actCodeOldModel->where([
                    'account_name' => $post['account_name'],
                    'create_id'    => $act_code['create_id'],
                ])->find();
                break;
            case 1:
            default: //1. 每个角色只能领取一次(同一个激活码分类下)
                $result = $actCodeOldModel->where([
                    'role_id'   => $post['role_id'],
                    'create_id' => $act_code['create_id'],
                ])->find();
        }

        if(!empty($result))
            return json_encode(array('code'=>301,'msg'=>'您已领取过了'));

        //所有的条件都通过后可以领取了
        return $this->_receive($post, $act_code, $act_create);
    }

    //领取激活码动作
    protected function _receive(&$post, &$code_data, &$code_create){
        $insertData = [
            'code_id'      => $code_data['id'],
            'create_id'    => $code_data['create_id'],
            'server_id'    => $code_create['server_id'],
            'role_name'    => $post['role_name'],
            'role_id'      => $post['role_id'],
            'account_name' => $post['account_name'],
            'role_level'   => $post['role_level'],
            'time'         => $post['time'],
        ];

        $res = Db::name('act_code_old')->insert($insertData);  //添加到已使用表

        $rew = explode(',',$code_create['reward']);
        $num = explode(',',$code_create['reward_num']);
        foreach ($rew as $key=>$val){
            $str[] = $val.','.$num[$key];
        }
        $rewards =implode('|',$str);
        //发送奖励
        return json_encode(array('code'=>200,'msg'=>'领取成功','rewards'=>$rewards));
    }

}
