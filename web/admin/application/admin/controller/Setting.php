<?php
namespace app\admin\controller;

use app\admin\model\Setting as SettingModel;

class Setting extends Main {

    public function index() {
        $model = new SettingModel();
        if($this->request->isPost()){
            $all  = $this->request->param('all', 'int', 0);

            //新增一个
            if($all == 0){
                $data = [
                    'name'  => $this->request->param('name', 'trim', ''),
                    'key'   => $this->request->param('key', 'trim', ''),
                    'value' => $this->request->param('value', 'trim', ''),
                    'add_time' => date('Y-m-d H:i:s', time()),
                ];

                if(!in_array('', $data))
                    $model->save($data);
            }else{ //修改所有
                $data = [];
                $param = $this->request->post();
                unset($param['all']);
                if(!empty($param)){
                    foreach($param as $k=>$v){
                        $data[] = [
                            'id'    => (int)$k,
                            'value' => trim($v),
                        ];
                    }
                }
                if(!empty($data))
                    $model->saveAll($data);
            }
        }

        $data = $model->order('id DESC')->column('id,name,value,key');//->select();
        cache('setting', array_column($data, null, 'key'));

        $this->assign('data', $data);
        return $this->fetch();
    }

}
