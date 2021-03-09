<?php
/**
 * Created by PhpStorm.
 * User: laijichang
 * Date: 2017/12/18
 * Time: 10:24
 */
defined('BASEPATH') OR exit('No direct script access allowed');

class EditServer extends CI_Controller {

    public function __construct()
    {
        parent::__construct();
        $id = $this->input->get('id');
        $time = $this->input->get('time');
        $key = $this->input->get('key');
        if (!checkMD5($id . $time, $key)){
            throw new Exception("key error");
        }
    }

    public function addServer()
    {
        $this->ServerModel->addServer();
    }

    public function delServer()
    {
        $id = $this->input->get('id');
        $this->ServerModel->delServer($id);
    }

    public function changeServer()
    {
        $this->ServerModel->changeServer();
    }

    public function changeStatus()
    {
        $this->ServerModel->changeStatus();
    }
}
