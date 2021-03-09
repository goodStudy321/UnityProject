<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Scripts extends Model {

    public function getScriptByServerId($server_id){
        if($server_id <= 0)
            return [];

        return $this->select('id','server_id','script')->where('server_id', '=', $server_id)->get()->toArray();
    }
    //
}
