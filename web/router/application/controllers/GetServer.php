<?php
/**
 * Created by PhpStorm.
 * User: laijichang
 * Date: 2017/12/15
 * Time: 15:11
 */
defined('BASEPATH') OR exit('No direct script access allowed');

class GetServer extends CI_Controller {

    /**
     * Index Page for this controller.
     *
     * Maps to the following URL
     * 		http://example.com/index.php/welcome
     *	- or -
     * 		http://example.com/index.php/welcome/index
     *	- or -
     * Since this controller is set as the default controller in
     * config/routes.php, it's displayed at http://example.com/
     *
     * So any other public methods not prefixed with an underscore will
     * map to /index.php/welcome/<method_name>
     * @see https://codeigniter.com/user_guide/general/urls.html
     */
    public function getClientServer()
    {
        $result = $this->ServerModel->getClientServer();
        echo $result;
    }

    public function getAll()
    {
        $result = $this->ServerModel->getAllServer();
        echo $result;
    }

    public function getOne()
    {
        $result = $this->ServerModel->getOneServer();
        echo $result;
    }
}
