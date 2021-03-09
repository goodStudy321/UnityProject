<?php

namespace app\admin\model;
use think\Model;

/**
 * 使用样例：
 *
 * $elastic = new Elasticsearch();
 *
 * 1. $elastic->name('my_index')->field('role_id, server_id')->where('channel_id=18')->select();
 *
 * 2. 支持数组条件
 * $map['channel_id'] = 18;
 * $map['server_id'] = 1;
 * $elastic->name('my_index')->where($map)->count();
 *
 * 3. 基本使用和TP的是类似的
 *
*/

class Elasticsearch extends Model {

    public $host;
    public $isdebug;
    private $call;
    private $sql = [
        'field' => '*',
        'name'  => '',
        'where' => '',
    ];

    public function __construct($isdebug = false){
        $this->host = config('database.elasticsearch')['hostname'];
        $this->isdebug = $isdebug;
    }

    //查询字段
    public function field($str = ''){
        $this->sql['field'] = $str ? $str : '*';
        return $this;
    }

    //elasticsearch 的索引名
    public function name($str = ''){
        $this->sql['name'] = 'FROM ' . $str;
        return $this;
    }

    /**
     * where 条件
     * @param  $select  arr|str  条件
    */
    public function where($where){
        if(is_array($where) && !empty($where)){
            $arr = [];
            foreach($where as $k=>$v)
                $arr[] = "$k = '$v'";
            $where = implode(' AND ', $arr);
        }

        $this->sql['where'] = 'WHERE ' . (string)$where;
        return $this;
    }

    //一般查询
    public function select(){
        $result = $this->query();
        if(!isset($result['hits']) || empty($result['hits']))
            return [];

        $result = $result['hits'];
        foreach($result['hits'] as $k=>&$v){
            $v = $v['_source'];
            unset($v['@timestamp'], $v['@version']);
        }
        unset($v);

        return $result;
    }

    //统计数量
    public function count($column = 'count(*)'){
        $this->sql['field'] = $column;
        $result = $this->query();
        return isset($result['aggregations']) ? reset($result['aggregations'])['value'] : 0;
    }

    /**
     * 执行 elasticsearch 查询
     * @param  $sql  str  elasticsearch的查询语句
    */
    public function query($sql = ''){
        $this->sql = $sql ? $sql : $this->sql;
        if(empty($this->sql))
            return [];

        if(is_array($this->sql)){
            $field = $this->sql['field'];
            unset($this->sql['field']);

            $sql = implode(' ', $this->sql);
            $this->sql = "SELECT $field $sql";
        }

        if($this->isdebug){
            echo $this->host . '/_sql?sql=' . $this->sql;
            die;
        }

        $url = $this->host . '/_sql?sql=' . urlencode($this->sql);
        return curl($url);
    }

}
