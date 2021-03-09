<?php
namespace app\index\model;

use think\Model;

class DataServer extends Base {

    public function getServer($id = 0){
        if($id > 0)
            return $this->where("index_id=$id")->find();

        return $this->select();
    }
}

