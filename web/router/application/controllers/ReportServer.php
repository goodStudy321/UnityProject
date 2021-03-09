<?php
/**
 * Created by PhpStorm.
 * User: laijichang
 * Date: 2017/12/15
 * Time: 16:12
 */
defined('BASEPATH') OR exit('No direct script access allowed');

class ReportServer extends CI_Controller {

    public function report()
    {
        $time = $this->input->get('time');
        $id = $this->input->get('id');
        $key = $this->input->get('key');
//        $num = $this->input->get('num');
        if (checkMD5($id . $time, $key)){
            echo 'true';
        } else {
            echo 'false';
        }
    }
}
