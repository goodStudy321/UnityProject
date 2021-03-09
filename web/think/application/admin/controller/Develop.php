<?php
namespace app\admin\controller;

use think\Controller;
use think\Db;


class Develop extends Main {
    //首页
    public function prop(){
        return $this->fetch();
    }

    public function develop_data(){
        $parm = $this->request->param();

        $data = '';
        if(!empty($parm['find'])){
            $map = '';

            if(!empty($parm['role_id'])){
                $map['a.role_id'] = $parm['role_id']; //角色id
            }

            if(!empty($parm['account_name'])){
                $map['b.account_name'] = $parm['account_name']; //条件id
            }

            /*if(!empty($parm['prop_status'])&&$parm['prop_status']!='all'){
                $map['code_status'] = $parm['code_status'];
            }*/

            $res = $this->region_connect
                ->name('role_nurture')
                ->alias('a')
                ->where($map)
                ->join('role_status b','a.role_id = b.role_id')
                ->field("a.*,b.role_name,b.account_name")
                ->select();

            $count = $this->region_connect
                ->name('role_nurture')
                ->alias('a')
                ->where($map)
                ->join('role_status b','a.role_id = b.role_id')
                ->count();

        }else{
            $res = $this->region_connect
                ->name('role_nurture')
                ->alias('a')
                ->join('role_status b','a.role_id = b.role_id')
                ->field("a.*,b.role_name,b.account_name")
                ->limit(($parm['page']-1)*$parm['limit'], $parm['limit'])
                ->select();

            $count = $this->region_connect->name('role_nurture')->count();
        }

        $name = [
            'wing'   => $this->getExcelConfig('excel_wing'),
            'magic'  => $this->getExcelConfig('excel_magic_weapon'),
            'weapon' => $this->getExcelConfig('excel_god_weapon'),
        ];
        foreach ($res as $key=>$val){   //可能会有多个皮肤
            //清空数组
            $weapon_data = array();
            $weapon_star = array();
            $magic_data = array();
            $magic_star = array();
            $wing_data = array();
            $wing_star = array();
            $weapon = explode(',',$val['god_weapon_skins']);
            if(!empty($weapon[0])){
                foreach ($weapon as $kk=>$vv){  //分解多个装备，同时截取星级
                    $weapon_str = substr($vv,0,5);
                    $weapon_data[] =  $name['weapon'][$weapon_str];
                    $weapon_star[] = substr($vv,-1,1);
                }
            }else{
                $weapon_data[0] = '暂无';
                $weapon_star[0] = '暂无';
            }

            $magic = explode(',',$val['magic_weapon_skins']);

            if(!empty($magic[0])){
                foreach ($magic as $kk=>$vv){ //分解多个装备，同时截取星级
                    $magic_str = substr($vv,0,5);
                    $magic_data[] =  $name['magic'][$magic_str];
                    $magic_star[] = substr($vv,-1,1);
                }
            }else{
                $magic_data[0] = '暂无';
                $magic_star[0] = '暂无';
            }

            $wing = explode(',',$val['wing_skins']);
            if(!empty($wing[0])){
                foreach ($wing as $kk=>$vv){ //分解多个装备，同时截取星级
                    $wing_str = substr($vv,0,5);
                    $wing_data[] =  $name['wing'][$wing_str];
                    $wing_star[] = substr($vv,-1,1);
                }
            }else{
                $wing_data[0] = '暂无';
                $wing_star[0] = '暂无';
            }

            $data[$key]['id'] = $val['id'];
            $data[$key]['role_name'] = $val['role_name'];
            $data[$key]['account_name'] = $val['account_name'];

            $data[$key]['weapon_name'] = (count($weapon_data)>=2)?implode(',',$weapon_data):$weapon_data[0];

            $data[$key]['weapon_level'] = $val['god_weapon_level'];

            $data[$key]['weapon_star'] = (count($weapon_star)>=2)?implode(',',$weapon_star):$weapon_star[0];

            $data[$key]['wing_name'] = (count($wing_data)>=2)?implode(',',$wing_data):$wing_data[0];

            $data[$key]['wing_level'] = $val['wing_level'];
            $data[$key]['wing_star'] = (count($wing_star)>=2)?implode(',',$wing_star):$wing_star[0];

            $data[$key]['magic_name'] = (count($magic_data)>=2)?implode(',',$magic_data):$magic_data[0];
            $data[$key]['magic_level'] = $val['magic_weapon_level'];

            $data[$key]['magic_star'] = (count($magic_star)>=2)?implode(',',$magic_star):$magic_star[0];

        }

        $arr = array ('code' => '0', 'msg' => '', 'count' => $count, 'data' =>$data );
        return $arr;
    }

}
