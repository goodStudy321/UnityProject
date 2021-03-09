<?php

namespace App\Http\Controllers;

use Illuminate\Support\Facades\DB;
use Illuminate\Http\Request;
use App\Models\Servers;
use App\Models\Scripts;
use App\Models\ScriptCodes;

class HomeController extends Controller {

    public function __construct() {
        $this->middleware('auth');
    }

    public function index(Servers $server, Scripts $scripts) {
        $data = $server->orderBy('id', 'desc')->get()->toArray();
        if(!empty($data)){
            foreach($data as $k=>&$v){
                $v['scripts'] = $scripts->getScriptByServerId($v['id']);
            }
        }
        //echo "<pre>";
        //print_r($data);
        //die;
        return view('home.home', ['data'=>$data]);
    }

    public function addserver(Request $request, Servers $server){
        $url  = trim($request->input('url', ''));
        $user = trim($request->input('user', ''));
        $id   = (int)$request->input('id', 0);
        if($url == '' || $user == '')
            return redirect('home/index')->withErrors('参数有误');

        $res = '';
        if($id > 0){
            $res = $server->where('id', '=', $id)->update([
                'user' => $user,
                'url'  => $url,
            ]);
        }else{
            $server->user = $user;
            $server->url  = $url;
            $res = $server->save();
        }

        if($res){
            return redirect('home/index');
            die;
        }

        return redirect('home/index')->withErrors('操作失败');
    }

    public function delserver(Request $request, Servers $server){
        $id = (int)$request->input('id', 0);
        if($id <= 0){
            return redirect('home/index')->withErrors('参数有误');
        }

        if($server->find($id)->delete()) //同时删除脚本 //fixme
            return redirect('home/index');
        else
            return redirect('home/index')->withErrors('操作失败');
    }

    public function loading(Servers $server){
        $data = $server->orderBy('id', 'desc')->get();

        $data = view('home.loading', ['data'=>$data]);
        $this->returnJson(10200, '', "$data");
    }

    public function addscript(Request $request, Scripts $scripts, ScriptCodes $scriptcodes){
        $post = $request->all();

        $status    = array_combine($post['code'], $post['name']);
        $script    = $post['script'];
        $server_id = $post['server_id'];

        if($script == '' || $server_id <= 0 || empty($status)){
            return redirect('home/index')->withErrors('参数有误');
            die;
        }

        DB::transaction(function() use($server_id, $post, $status, $scripts, $scriptcodes){
            //1.
            $scripts->script    = $post['script'];
            $scripts->server_id = $server_id;
            $scripts->save();

            //2.
            $data = [];
            foreach($status as $k=>$v){
                $data[] = [
                    'name'        => $v,
                    'script_code' => $k,
                    'script_id'   => $scripts->id,
                ];
            }
            $scriptcodes->insert($data);
        });

        return redirect('home/index');
    }


}
