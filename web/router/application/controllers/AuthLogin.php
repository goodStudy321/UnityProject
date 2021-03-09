<?php
/**
 * Created by PhpStorm.
 * User: laijichang
 * Date: 2017/12/18
 * Time: 10:24
 */
defined('BASEPATH') OR exit('No direct script access allowed');

class AuthLogin extends CI_Controller {

    public function __construct()
    {
        parent::__construct();
    }

    public function auth()
    {
        $this->AuthLoginModel->auth();
    }
}
