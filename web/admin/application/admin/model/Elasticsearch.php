<?php

namespace app\admin\model;

/**
 * 使用样例：
 *
 * $elastic = new Elasticsearch();
 *
 * 1. $elastic->name('my_index')->field('role_id, server_id')->where('channel_id=18')->select();
 *
 * 2. 支持数组和字符串条件
 * $map['channel_id'] = 18;
 * $map['server_id'] = 1;
 * $elastic->name('my_index')->where($map)->count();
 *
 * 3. 基本使用和TP的是类似的
 *
*/

class Elasticsearch {

    public  $conf;
    public  $isdebug;
    private $sql_org = [
        'field' => '*',
        'name'  => '',
        'where' => '',
        'order' => '',
        'limit' => '',
    ];

    public function __construct($isdebug = false){
        $this->conf    = config('database.elasticsearch');
        $this->isdebug = $isdebug;
        $this->sql = $this->sql_org;
    }

    //查询字段
    public function field($str = ''){
        $this->sql['field'] = $str ? $str : '*';
        return $this;
    }

    //elasticsearch 的索引名
    public function name($index = ''){
        $this->sql['name'] = 'FROM ' . $this->conf['prefix'] . $index;
        return $this;
    }

    /**
     * where 条件
     * @param  $select  arr|str  条件
    */
    public function where($where){
        if(is_array($where) && !empty($where)){
            $arr = [];
            foreach($where as $k=>$v){
                $arr[] = "$k = '$v'";
            }

            $where = implode(' AND ', $arr);
        }
        
        if(!empty($where)){
            if($this->sql['where'] == '')
                $this->sql['where'] = 'WHERE ' . (string)$where;
            else
                $this->sql['where'] .= (string)$where;
        }

        return $this;
    }

    /**
     * order
     * @param  $order  arr|str  排序
    */
    public function order($order){
        $this->sql['order'] = 'ORDER BY ' . $order;
        return $this;
    }

    // @param  $limit  int|str  例子：5 或 0,5
    public function limit($limit){
        $this->sql['limit'] = 'LIMIT ' . $limit;
        return $this;
    }

    //一般查询
    public function select($all = false){
        $result = $this->query();
        if(!isset($result['hits']) || empty($result['hits']))
            return [];

        $result = $result['hits'];
        foreach($result['hits'] as $k=>&$v){
            $v = $v['_source'];
            unset($v['@timestamp'], $v['@version']);
        }
        unset($v);

        return $all ? $result : $result['hits'];
    }

    //统计数量
    public function count($column = '*'){
        $this->sql['field'] = "count($column)";
        $result = $this->query();
        return isset($result['aggregations']) ? reset($result['aggregations'])['value'] : 0;
    }

    //单条数据的指定字段
    public function column($column = ''){
        if($column == '')
            return '';

        $this->sql['field'] = $column;
        $result = $this->query();
        if(!isset($result['hits']['hits']))
            return '';

        $result = reset($result['hits']['hits']);
        if(!isset($result['_source']) || empty($result['_source']))
            return '';

        return count($result['_source']) > 1 ? $result['_source'] : reset($result['_source']);
    }

    /**
     * 执行 elasticsearch 查询
     * @param  $sql  str  elasticsearch的查询语句
    */
    public function query($sql = ''){
        $sql = $sql ? $sql : $this->sql;
        if(empty($sql))
            return [];

        if(is_array($sql)){
            $field = $sql['field'];
            unset($sql['field']);

            $sql = implode(' ', array_filter($sql));
            $sql = "SELECT $field $sql";
            $this->sql = $this->sql_org;
        }

        $host = $this->conf['hostname'];
        if($this->isdebug){
            echo $host . '/_sql?sql=' . $sql;
            die;
        }

        $url = $host . '/_sql?sql=' . urlencode($sql);
        return curl($url);
    }

    public function isdebug(){
        $this->isdebug = true;
        return $this;
    }

}
