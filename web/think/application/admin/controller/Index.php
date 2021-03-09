<?php
namespace app\admin\controller;
use think\Db;

class Index extends Main {
    /**
     * 首页展示
    */
    public function index()
    {
        return $this->fetch();
    }
    /**
     * 桌面页
    */
    public function welcome()
    {
        return $this->fetch();
    }

    //流失相关导出
    public function lossUserData(){ //fixme
        $region_connect = Db::connect([
            'hostname' => '192.168.2.250',
            //'hostname' => '115.159.68.105',
            'database' => 'admin_local_1',
            //'database' => 'admin_junhai_1',
            'type'     => 'mysql',
            'username' => 'datauser',
            'password' => 'mfpmaLSTAfwQJ13mBoSFDc4m0bmfCQgd',
            'hostport' => '3306',
            'charset'  => 'utf8',
            'prefix'   => 'log_',
        ]);

        $allData = [];
        $i = 0;
        while($i <= 3){
            $day = 6 + $i;
            $begin = strtotime('2018-07-0'.$day);
            $end   = $begin+86400;
            $data = $region_connect->name('role_login')
                ->alias('l')
                ->join('log_role_status s', 'l.role_id=s.role_id', 'LEFT')
                ->where("l.time >= $begin and l.time <= $end")
                ->field('s.server_id, s.role_id, s.role_name, s.role_level, s.id, s.power, s.id as gold, s.id as id1, s.category, s.create_time, s.map_id, s.id as online_time, l.time')
                ->order('l.role_id,l.time ASC')
                ->select();
            $data = array_column($data, null, 'role_id');
            $role_ids = array_keys($data);

            //当天在线时长
            $online_time = $region_connect->name('role_logout')
                ->where("time >= $begin and time <= $end")
                ->where('role_id', 'IN', $role_ids)
                ->field('role_id,online_time')
                ->select();
            $onlineTime = [];
            foreach($online_time as $v){
                if(isset($onlineTime[$v['role_id']]))
                    $onlineTime[$v['role_id']] += $v ['online_time'];
                else
                    $onlineTime[$v['role_id']] = $v ['online_time'];
            }

            //当天消耗元宝
            $loss_gold = $region_connect->name('gold')
                ->where("time >= $begin and time <= $end")
                ->where('role_id', 'IN', $role_ids)
                ->where("action >= 60000 and action <= 69999")
                ->field('role_id,gold')
                ->select();

            $lossGold = [];
            foreach($loss_gold as $v){
                if(isset($lossGold[$v['role_id']]))
                    $lossGold[$v['role_id']] += $v['gold'];
                else
                    $lossGold[$v['role_id']] = $v['gold'];
            }

            //组装
            foreach($data as &$value){
                $value['id']          = '(暂无)';
                $value['id1']         = '(暂无)';
                $value['gold']        = isset($lossGold[$value['role_id']]) ? $lossGold[$value['role_id']] : 0;
                $value['online_time'] = isset($onlineTime[$value['role_id']]) ? round($onlineTime[$value['role_id']]/60) : 0;
                $value['create_time'] = date('Y-m-d H:i:s', $value['create_time']);
                $value['time']        = date('Y-m-d H:i:s', $value['time']);
            }
            unset($value);
            ++$i;
            $allData = array_merge($allData, array_values($data));
        }

        $data = array_merge([['区服', '玩家ID', '角色名', '等级', '转生', '战力', '当天消耗元宝', '累计消耗元宝', '职业', '注册时间', '流失任务或场景/ID', '当天在线时长（min）', '日志时间(最后一次登陆时间)']], $allData);

        $title    = '流失相关';
        $T_arr    = ['A','B','C','D','E','F','G', 'H', 'I', 'J', 'K', 'L', 'M'];
        $PHPExcel = new \PHPExcel();
        $PHPSheet = $PHPExcel->getActiveSheet();
        $PHPSheet->setTitle($title);
        $PHPExcel->getActiveSheet()->getColumnDimension('A')->setWidth(15);
        $PHPExcel->getActiveSheet()->getColumnDimension('B')->setWidth(20);
        $PHPExcel->getActiveSheet()->getColumnDimension('C')->setWidth(20);
        $PHPExcel->getActiveSheet()->getColumnDimension('D')->setWidth(20);
        $PHPExcel->getActiveSheet()->getColumnDimension('E')->setWidth(15);
        $PHPExcel->getActiveSheet()->getColumnDimension('F')->setWidth(15);
        $PHPExcel->getActiveSheet()->getColumnDimension('G')->setWidth(20);
        $PHPExcel->getActiveSheet()->getColumnDimension('H')->setWidth(20);
        $PHPExcel->getActiveSheet()->getColumnDimension('I')->setWidth(10);
        $PHPExcel->getActiveSheet()->getColumnDimension('J')->setWidth(20);
        $PHPExcel->getActiveSheet()->getColumnDimension('K')->setWidth(20);
        $PHPExcel->getActiveSheet()->getColumnDimension('L')->setWidth(25);
        $PHPExcel->getActiveSheet()->getColumnDimension('M')->setWidth(30);

        foreach($data as $k=>$v){
            if($k != 0)
                $v = array_values($v);

            ++$k;
            foreach($v as $key=>$value){
                $list = $T_arr[$key];
                $t = $list.$k;
                $PHPSheet->setCellValue($t,$value);
            }
        }


        $PHPWriter = \PHPExcel_IOFactory::createWriter($PHPExcel,'Excel2007');//按照指定格式生成Excel文件，‘Excel2007’表示生成2007版本的xlsx，‘Excel5’表示生成2003版本Excel文件

        header('Content-Type: application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');//告诉浏览器输出07Excel文件
        header('Content-Disposition: attachment;filename="'.$title.'.xlsx"');//告诉浏览器输出浏览器名称
        header('Cache-Control: max-age=0');//禁止缓存
        $PHPWriter->save("php://output");
    }

}
