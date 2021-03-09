<?php
namespace app\admin\controller;

use think\Controller;
use think\Db;
use think\Session;
use think\Validate;

class Config extends Main {
    //数据库配置
    public function check(){
        $role  = Db::name('config')->order('id desc')->paginate();

        $this->assign('page', $role->render());
        $this->assign('role',$role);
        $this->assign('count', count($role));
        return $this->fetch();
    }

    //添加
    public function configAdd(){
        $post = $this->request->post();
        if(!empty($post)){
            $data = [
                'title_name' => trim($post['title_name']),
                'title'      => json_encode([
                    'mysql' => $post['mysql'],
                    'other' => $post['other'],
                ]),
            ];
            if(in_array('', $data))
                return $this->error('操作失败');

	    $data['agent_id']   = (int)$post['agent_id'];
	    $data['server_id']  = (int)$post['server_id'];
	    $id = Db::name('config')->insertGetId($data);
            if($id > 0){
                //$this->_makeDatabaseMapping([
                //    'hostname'     => $post['mysql']['hostname'],
                //    'database' => $post['mysql']['database'],
                //]);
                return $this->success('添加成功');
            }else{
                return $this->error('添加失败');
            }
        }else{
            return $this->fetch();
        }
    }

    //编辑
    public function configEdit($id){
         $data = Db::name('config')->where("id=$id")->find();
         $data = $data + json_decode($data['title'],true);

         $this->assign('data', $data);
         return $this->fetch();
    }
    //接收编辑信息
    public function configEditBack($id){
        $post = $this->request->post();
        $data = [
            'id'         => (int)$post['id'],
            'title_name' => trim($post['title_name']),
            'title'      => json_encode([
                'mysql' => $post['mysql'],
                'other' => $post['other'],
            ]),
        ];
        if(in_array('', $data))
            return $this->error('操作失败');

	$data['agent_id']   = (int)$post['agent_id'];
	$data['server_id']  = (int)$post['server_id'];
        $ret = Db::name('config')->update($data);
        if($ret !== false){
            $old_config = session('data_server');
            if(isset($old_config['id']) && $old_config['id'] == $data['id']){
                $config = Db::name('config')->find($data['id']);
                session('data_server', $config);
            }
            //$this->_makeDatabaseMapping([
            //    'hostname' => trim($post['mysql']['hostname']),
            //    'database' => trim($post['mysql']['database']),
            //]);
            return $this->success('操作成功');
        }else{
            return $this->error('操作失败');
        }
    }

    //删除配置
    public function delConfig($id){
        $ret = Db::name('config')->where(array("id"=>$id))->delete();
        if($ret){
            $config = Db::name('config')->limit(1)->select();
            $config = reset($config);
            session('data_server', $config);
            $this->success('删除成功');
        }else{
            $this->error('删除失败');
        }
    }

    //切换服务器
    public function doChangeConfigStatus(){
        $id = $this->request->post('id', 0, 'int');
        $config = Db::name('config')->find($id);
        session('data_server', $config);
        $this->returnJson(10200);
    }

    //创建数据库对应的映射数据库 //@fixme
    protected function _makeDatabaseMapping($data){
        $log_data_account = config('log_data_account');
        $connect_account  = $log_data_account + $data;
        if(in_array('', $connect_account))
            return false;

        extract($connect_account);

        $mapping_database = 'mapping_'.$database;
        $server_name      = 'connection_'. str_replace('.', '_', $hostname) .'_'.$database. '_name';

        DB::startTrans();
        try{
            //1. create server
            //DB::query("DROP SERVER IF EXISTS $server_name");
            //echo $create_server = "CREATE SERVER $server_name FOREIGN DATA WRAPPER mysql OPTIONS (HOST '$hostname',USER '$username',PASSWORD '$password' ,PORT $hostport,DATABASE '$database')";

            //2. create mapping database
            DB::query("DROP DATABASE IF EXISTS $mapping_database");
            DB::query("CREATE DATABASE $mapping_database");
            $server_name = "$type://$username:$password@$hostname/$database";
            $remote_connect  = Db::connect($connect_account);

            $all_tables = $remote_connect->query("SHOW TABLES FROM $database");
            if(!empty($all_tables)){
                $all_tables = array_column($all_tables, 'Tables_in_'.$database);
                foreach($all_tables as $table){
                    $structure = $remote_connect->query("SHOW CREATE TABLE $database.$table");
                    $structure = end($structure[0]);
                    $structure = str_replace("`$table`", "$mapping_database.$table", $structure) . " ENGINE=FEDERATED CONNECTION='$server_name/$table';";
                    DB::query($structure);
                }
            }

            Db::commit();
        }catch(\Exception $e){
            Db::rollback();
            echo $e->getMessage();
            die('===');
            return false;
        }

        return true;
    }

}
