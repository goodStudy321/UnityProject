<?php

namespace App\Http\Controllers;

use Illuminate\View;
use Illuminate\Foundation\Bus\DispatchesJobs;
use Illuminate\Routing\Controller as BaseController;
use Illuminate\Foundation\Validation\ValidatesRequests;
use Illuminate\Foundation\Auth\Access\AuthorizesRequests;



class Controller extends BaseController {
    use AuthorizesRequests, DispatchesJobs, ValidatesRequests;

    public function returnJson($code, $msg = '', $data = []){
        die(json_encode(['status'=>['code'=>$code, 'msg'=>$msg], 'data'=>$data]));
    }
}
