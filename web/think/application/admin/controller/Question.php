<?php
namespace app\admin\controller;

use think\Db;
use app\admin\model\Channel;

class question extends Main {

    public function __construct(){
        parent::__construct();
        $this->write_tag = '@@';
    }

    // 调查问卷
    public function make(){
        $data = Db::name('question')
            ->order('id desc')
            ->paginate();

        $this->assign('page', $data->render());
        $this->assign('data', $data);
        return $this->fetch();
    }
    //添加
    public function makeAdd(){
        $data = Db::name('channel')
            ->order('id asc')
            ->select();

        $this->assign('data', $data);
        return $this->fetch();
    }

    //编辑
    public function makeEdit($id=0){
        $data = Db::name('question')
            ->where("id=$id")
            ->find();

        $channel = Db::name('channel')
            ->order('id desc')
            ->select();

        $this->assign('data', $data);
        $this->assign('channel', $channel);
        return $this->fetch();
    }

    //删除
    public function makeDel($id){
        $res = Db::name('question')
            ->where("id=$id")
            ->delete();
        if($res) {
            return $this->success('success');
        }
    }

    //接收添加和编辑
    public function makeSend(){
        $post     = $this->request->post();

        if(!empty($post)){
            $channel = explode('-',$post['channel']);
            $post['channel_id'] = $channel[0];
            $post['channel_name'] = $channel[1];
            unset($post['channel']);
            if(!empty($post['edit'])){
                $id = $post['edit'];
                unset($post['edit']);
                $res = Db::name('question')->where(array('id'=>$id))->update($post);
            }else{
                $res = Db::name('question')->insert($post);
            }

            if($res !== false)
                return $this->success('操作成功');
            else
                return $this->error('操作失败');
        }
    }

    //问卷列表
    public function questionList($id=0){
        $data = Db::name('questionnaire')
            ->where("question_id=$id")
            ->order('id asc')
            ->paginate();

        $this->assign('page', $data->render());
        $this->assign('data', $data);
        $this->assign('id', $id);
        return $this->fetch();
    }

    //添加问卷问题
    public function questionAdd($id){
        $this->assign('id', $id);
        return $this->fetch();
    }
    //添加
    public function questionSend(){
        $post = $this->request->post();
        if(isset($post['write']) && isset($post['question_value'][$post['write']]))
            $post['question_value'][$post['write']] = $post['question_value'][$post['write']] . $this->write_tag;

        $post['question_value'] = implode('[[',$post['question_value']);

        if((int)$post['question_status'] == 1)
            unset($post['question_value']);

        unset($post['write']);

        if(!empty($post['edit'])){
            $id = $post['edit'];
            unset($post['edit']);
            $res = Db::name('questionnaire')->where(array('id'=>$id))->update($post);
        }else{
            $res = Db::name('questionnaire')->insert($post);
        }

        if($res !== false)
            return $this->success('success');
    }

    //编辑
    public function questionEdit($id){
        $data = Db::name('questionnaire')
            ->where("id=$id")
            ->find();

        $data['question_value'] = explode('[[',$data['question_value']);

        $write_key = -1;
        if(!empty($data['question_value'])){
            foreach($data['question_value'] as $k=>&$v){
                if(strpos($v,$this->write_tag) !== false){
                    $v = str_replace($this->write_tag, '', $v);
                    $write_key = $k;
                    break;
                }
            }
        }
        $this->assign('data', $data);
        $this->assign('write_key', $write_key+1);
        return $this->fetch();
    }

    //删除
    public function questionDel($id){
        $res = Db::name('questionnaire')
            ->where("id=$id")
            ->delete();
        if($res) {
            return $this->success('success');
        }
    }

    public function send($id){
        $data = Db::name('question')->where("id=$id")->find();

        $time = time();
        $ticket = md5(time(). config('erlang_salt'));
        $survey_id = $data['id'];
        $channel_id = $data['channel_id'];
        $rew = explode(',',$data['reward']);
        $num = explode(',',$data['reward_num']);
        foreach ($rew as $key=>$val){
            $str[] = $val.','.$num[$key];
        }
        $rewards =implode('|',$str);
        $min_level = $data['condition'];
        $naire = Db::name('questionnaire')->where("question_id=$id")->select();
        $nastr = '';
        foreach ($naire as $key=>$val){
            $nastr[] = $val['question_name'].'__'.$val['question_status'].'__'.$val['question_value'];
        }

        $text = implode('||',$nastr);

        $url = $this->message_send_to_url . "/?time=$time&ticket=$ticket&action=send_survey&survey_id=$survey_id&channel_id=$channel_id&rewards=$rewards&min_level=$min_level&text=$text";

        //初始化
        $curl = curl_init();
        //设置抓取的url
        curl_setopt($curl, CURLOPT_URL, $url);
        //设置头文件的信息作为数据流输出
        curl_setopt($curl, CURLOPT_HEADER, 0);
        //设置获取的信息以文件流的形式返回，而不是直接输出。
        curl_setopt($curl, CURLOPT_RETURNTRANSFER, 1);
        //执行命令
        $data = curl_exec($curl);
        //关闭URL请求
        curl_close($curl);
        //显示获得的数据
        $ret = json_decode($data,true);
        if(!empty($ret)&&$ret['ret']==1){
            $arr = array ('code' => '1', 'msg' => '发送成功');
            return $arr;
        }else{
            $arr = array ('code' => '0', 'msg' => '发送失败');
            return $arr;
        }

    }

    //问卷结果
    public function outcome(){
        $this->assign('survey_id', $this->request->param('survey_id', 0, 'int'));
        return $this->fetch();
    }

    public function outcomeData($limit = 0, $forExcel = false){
        $where = [];

        //按渠道ID查找
        $survey_id = $this->request->param('survey_id', 0, 'int');
        if($survey_id <= 0)
            $this->error('参数有误');

        $where['s.survey_id'] = $survey_id;

        //按渠道ID查找
        $channel_id = $this->request->param('channel_id', 0, 'int');
        if($channel_id > 0)
            $where['s.channel_id'] = $channel_id;

        //按包渠道ID查找
        $game_channel_id = $this->request->param('game_channel_id', 0, 'int');
        if($game_channel_id > 0)
            $where['s.game_channel_id'] = $game_channel_id;

        //按时间查找
        $begin_org = $this->request->param('begin', '', 'trim');
        $end_org   = $this->request->param('end', '', 'trim');
        $begin = strtotime($begin_org);
        $end   = strtotime($end_org);
        if($begin_org != '' && $end_org != '')
            $where['s.time'] = [['>', $begin], ['<', $end]];

        $limit= max($limit, $this->request->param('limit', 30, 'int'));
        $res = $this->region_connect
            ->name('role_survey')
            ->alias('s')
            ->join('role_status r','s.role_id = r.role_id', "LEFT")
            ->field("s.id, s.time, s.role_id, s.survey_id, s.texts, s.channel_id, s.game_channel_id, r.role_name, r.server_id, r.role_level, r.role_vip_level, r.create_time, r.power, r.category")
            ->where($where)
            ->order('s.id desc')
            ->paginate($limit)
            ->toArray();

        $count = $this->region_connect
            ->name('role_survey')
            ->alias('s')
            ->where($where)
            ->count();

        $data = $res['data'];

        //渠道相关的数据
        extract( (new Channel())->processChannels($data) );

        //取出问卷名称
        $survey_id = array_column($data, 'survey_id');
        $survey_id = array_unique($survey_id);
        if(!empty($survey_id)){
            $survey_id = implode(',', $survey_id);
            $survey_name = DB::name('question')
                ->where("id in($survey_id)")
                ->column('id, question');
            $arr = DB::name('questionnaire')
                ->where("question_id in($survey_id)")
                ->column('id, question_id, question_name, question_value, question_status');

            $question_arr = [];
            foreach($arr as $v)
                $question_arr[$v['question_id']][] = $v;
        }

        $return_arr = [];
        foreach($data as &$v){
            $res = explode('__', $v['texts']);
            $texts = '';
            if(isset($question_arr[$v['survey_id']])){
                foreach($question_arr[$v['survey_id']] as $key=>$value){
                    $value_str = [];
                    $question_value = explode('[[', $value['question_value']);
                    $str = isset($res[$key]) ? $res[$key] : '';
                    if($str != ''){
                        $str = explode('||', $str);
                        if(!empty($str)){
                            foreach($str as $qv){
                                $value_str[] = $qv;
                                //if(is_numeric($qv)){
                                //    $qv = $qv - 1;
                                //    if(isset($question_value[$qv]) && $question_value[$qv] != '' && strpos($question_value[$qv], $this->write_tag) === false)
                                //        $value_str[] = $question_value[$qv];
                                //}else{
                                //    if($qv)
                                //        $value_str[] = $qv;
                                //}
                            }
                        }
                    }
                    $value_str = array_filter($value_str);
                    $value_str = implode(',', $value_str);
                    if($forExcel){
                        $texts[] = [
                            //'q' => $value['question_name'],
                            'q' => $value['id'],
                            'a' => $value_str,
                            'type' => $value['question_status'],
                            'question_value' => $value['question_value'],
                        ];
                    }else{
                        //$texts .= $value['question_name']. '('. $value_str .')；';
                        $texts .= $value['id']. '('. $value_str .')；';
                    }
                }
            }

            $return_arr[] = [
                'id'                => $v['id'],
                'time'              => date('Y-m-d H:i:s', $v['time']),
                'role_name'         => $v['role_name'],
                'channel_name'      => isset($channel_name[$v['channel_id']]) ? $channel_name[$v['channel_id']] : '--',
                'game_channel_name' => isset($game_channel_name[$v['game_channel_id']]) ? $game_channel_name[$v['game_channel_id']] : '--',
                'surver_name'       => isset($survey_name[$v['survey_id']]) ? $survey_name[$v['survey_id']] : '--',
                'server_id'         => $v['server_id'],
                'role_level'        => $v['role_level'],
                'role_vip_level'    => $v['role_vip_level'],
                'create_time'       => $v['create_time'] > 0 ? date('Y-m-d H:i:s', $v['create_time']) : '--',
                'power'             => $v['power'],
                'category'          => $v['category'],
                'texts'             => $texts,
            ];
        }

        return [
            'code'  => '0',
            'msg'   => '',
            'count' => $count,
            'data'  => $return_arr,
        ];
    }


    public function outcomeExportExcel(){
        $data = $this->outcomeData(99999999, true);
        $data = $data['data'];
        if(empty($data))
            return $this->error('还没有数据');

        $question_ids = [];
        foreach($data as $k=>&$v){
            foreach($v['texts'] as $key=>$value){
                if($value['type'] == 2){
                    $question = explode('[[', $value['question_value']);
                    $arr = array_flip(explode(',', $value['a']));
                    foreach($question as $i=>$t){
                        if(isset($arr[$i+1])){
                            $v[$value['q'].'_'.$i] = 1;
                            unset($arr[$i+1]);
                        } else{
                            $v[$value['q'].'_'.$i] = '';
                        }
                    }
                    foreach($question as $i=>$t){
                        if($t == '') //填空项的
                            $v[$value['q'].'_'.$i] = $arr ? reset($arr) : '';
                    }
                }else{
                    $v[$value['q']] = $value['a'] ;
                }

                $question_ids[$value['q']] = '';
            }
            unset($v['texts']);
        }
        unset($v);

        //取出问题名称
        $question_name = Db::name('questionnaire')
            ->where('id in ('.implode(',', array_keys($question_ids)).')')
            ->column('id,question_name,question_value,question_status');

        $title = [];
        $i = 1;
        foreach($question_name as $key=>$v){
            if($v['question_status'] == 2){
                $child = explode('[[', $v['question_value']);
                foreach($child as $k=>$name){
                    $name = $name ? $name : '可填写';
                    $title[$key.'_'.$k] = $i.'. '.$v['question_name'].'('.$name.')';
                }
            }else{
                $title[$key] = $i.'. '.$v['question_name'];
            }

            ++$i;
        }

        $title = ['记录ID', '提交时间', '角色名称', '渠道', '包渠道', '问卷', '区服ID', '角色等级', 'VIP等级', '创号时间', '战力', '职业'] + $title;
        $title = array_values($title);

        $data  = array_merge([$title], $data);
        $T_arr = excelColumn('CZ');
        $PHPExcel = new \PHPExcel();
        $PHPSheet = $PHPExcel->getActiveSheet();
        $PHPSheet->setTitle('问卷结果');
        $PHPExcel->getActiveSheet()->getColumnDimension('A')->setWidth(15);
        $PHPExcel->getActiveSheet()->getColumnDimension('B')->setWidth(20);
        $PHPExcel->getActiveSheet()->getColumnDimension('C')->setWidth(20);
        $PHPExcel->getActiveSheet()->getColumnDimension('D')->setWidth(20);
        $PHPExcel->getActiveSheet()->getColumnDimension('E')->setWidth(15);
        $PHPExcel->getActiveSheet()->getColumnDimension('F')->setWidth(15);
        $PHPExcel->getActiveSheet()->getColumnDimension('G')->setWidth(10);
        $PHPExcel->getActiveSheet()->getColumnDimension('H')->setWidth(10);
        $PHPExcel->getActiveSheet()->getColumnDimension('J')->setWidth(20);

        $style = array(
            'alignment' => array(
                'horizontal' => \PHPExcel_Style_Alignment::HORIZONTAL_LEFT,
            )
        );
        $PHPExcel->getActiveSheet()->getDefaultStyle()->applyFromArray($style);

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
        header('Content-Disposition: attachment;filename="问卷结果.xlsx"');//告诉浏览器输出浏览器名称
        header('Cache-Control: max-age=0');//禁止缓存
        $PHPWriter->save("php://output");
    }
}


