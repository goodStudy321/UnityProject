<?php
/**
 * Created by PhpStorm.
 * User: laijichang
 * Date: 2017/12/18
 * Time: 9:58
 */
class ServerModel extends CI_Model {

    public function __construct(){
        parent::__construct();
        // Your own constructor code
    }

    public function getClientServer()
    {
        $agentID = $this->input->get('agent_id');
        if ( !($agentID && $agentID > 0)){
            $agentID = 1;
        }
        $isDebug = $this->input->get('isdebug');
        $titleQuery = $this->db->query("SELECT index_id,name,begin_id,end_id from router_title WHERE agent_id=$agentID ");
        if($isDebug){
            $serverQuery = $this->db->query("SELECT index_id,server_id,name,ip,port,status,is_new from router_server WHERE agent_id=$agentID");
        }else{
            $serverQuery = $this->db->query("SELECT index_id,server_id,name,ip,port,status,is_new from router_server WHERE agent_id=$agentID AND is_debug=false");
        }

        $result = [[
            'titles' => $titleQuery->result(),
            'servers' => $serverQuery->result()
        ]];
        return json_encode($result);
    }

    // 获取当前的服务器列表
    public function getAllServer()
    {
        $query = $query = $this->db->get('server');
        return json_encode($query->result());
    }

    public function getOneServer()
    {
        $id = $this->input->get('id');
        return json_encode($this->db->get_where('server', array('id' => $id))->row_array());
    }

    // 增加服务器
    public function addServer()
    {
        $id = $this->input->get('id');
        if ($this->db->get_where('server', array('id' => $id))->row_array()){
            echo 'id exist';
            throw new Exception("key error");
        } else {
            $this->db->insert('server', $this->getInputData());
        }
    }

    // 删除某个服务器
    public function delServer($id)
    {
        $id = $this->input->get('id');
        $this->db->delete('server', array('id' => $id));
    }

    // 改变服务器的信息
    public function changeServer()
    {
        $id = $this->input->get('id');
        if ($this->db->get_where('server', array('id' => $id))->row_array()){
            $this->db->replace('server', $this->getInputData());
        }
    }

    public function changeStatus()
    {
        $status = $this->input->get('status');
        $this->db->query("UPDATE server set status='$status'");
    }

    // 获取当前输入的服务器信息
    private function getInputData()
    {
        $data = array(
            'id' => $this->input->get('id'),
            'name' => $this->input->get('name'),
            'status' => $this->input->get('status'),
            'ip' => $this->input->get('ip'),
            'port' => $this->input->get('port'),
            'num' => $this->input->get('num'),
        );
        return $data;
    }
}
