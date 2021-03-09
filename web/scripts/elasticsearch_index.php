<?php

$elasticsearch_connect='http://192.168.2.250:9200/';
$shards=10;

function mysqlConf(){
    return [
        'hostname' => '192.168.2.250',
        'username' => 'datauser',
        'password' => 'mfpmaLSTAfwQJ13mBoSFDc4m0bmfCQgd',
        'database' => 'admin_local_1',
    ];
}

function _curl($elasticsearch_connect, $action, $fields = '{}'){
    $ch = curl_init();
    $header[] = "Content-type: application/json";
    curl_setopt($ch, CURLOPT_URL, $elasticsearch_connect);
    curl_setopt($ch, CURLOPT_CUSTOMREQUEST, $action);
    curl_setopt($ch, CURLOPT_HEADER,0);
    curl_setopt($ch, CURLOPT_HTTPHEADER, $header);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER,1);
    curl_setopt($ch, CURLOPT_POSTFIELDS, $fields);
    $result = curl_exec($ch);
    curl_close($ch);
    return json_decode($result, true);
}

function _getTables(){
    $mysql = mysqlConf();
    $tables = [];
    $link = new mysqli($mysql['hostname'], $mysql['username'], $mysql['password'], $mysql['database']);
    $result = $link->query('show tables');
    if(!$result)
        die("mysqli error\n");

    while($row = $result->fetch_object()){
        $table = implode('', array_values((array)$row));
        $key = $link->query("SHOW KEYS FROM {$table} WHERE Key_name = 'PRIMARY'")->fetch_object()->Column_name;
        $tables[] = [
            'table' => $table,
            'primary' => $key,
        ];
    }
    mysqli_close($link);
    return $tables;
}

function createIndex($elasticsearch_connect, $shards){
    if($elasticsearch_connect == '' || $shards <= 0)
        return false;

    //从日志数据库中取出表来
    $tables = _getTables();

    if(empty($tables))
        die("no mysql table in ". $mysql['database'] . "\n");

    $fields = json_encode([
        "settings" => [
            "number_of_shards" => $shards,
            "number_of_replicas" => 0,
        ],
    ]);

    foreach($tables as $index){
        echo $index['table'];
        $result = _curl($elasticsearch_connect . $index['table'], 'PUT', $fields);
        if(isset($result['index']) && $result['index'] == $index['table']){
            echo ": Success \n";
        }else{
            echo ": Fail \n";
        }
    }

}

function createOne($elasticsearch_connect, $name, $shards){
    $fields = json_encode([
        "settings" => [
            "number_of_shards" => $shards,
            "number_of_replicas" => 0,
        ],
    ]);
    $result = _curl($elasticsearch_connect . $name, 'PUT', $fields);

    echo $name;
    if(isset($result['index']) && $result['index'] == $name){
        echo ": Success \n";
    }else{
        echo ": Fail \n";
    }
}



function delAll($elasticsearch_connect){
   $result = _curl($elasticsearch_connect. '*', 'DELETE');
   print_r($result);
}


function makeJdbcConf(){
    $file = '../logstash/jdbc.conf';
    if(!is_file($file))
        die($file. "is not file \n");

    $elasticsearch_hosts = '["192.168.2.250:9200"]';
    $jdbc = $type = '';
    $tables = _getTables();

    foreach($tables as $value){
        $t = $value['table'];
        $key = $value['primary'];
        $jdbc .= 'jdbc {
              jdbc_connection_string => "jdbc:mysql://192.168.2.250:3306/admin_local_1"
              jdbc_user              => "root"
              jdbc_password          => "SLsl>2017409"
              jdbc_driver_library    => "/usr/local/ElasticSearch/logstash-6.3.2/tools/mysql-connector-java-5.1.36.jar"
              jdbc_driver_class      => "com.mysql.jdbc.Driver"
              jdbc_paging_enabled    => "true"
              jdbc_page_size         => "50000"

              record_last_run => "true"
              use_column_value => "true"
              tracking_column => "'.$key.'"

              statement => "select * from '.$t.'"
              schedule  => "* * * * *"
              type      => "'.$t.'"
          }';
        $type .= 'if[type] == "'.$t.'" {
            elasticsearch {
              hosts => '.$elasticsearch_hosts.'
                user        => ""
                password    => ""
                index       => '.$t.'
                document_id => "%{'.$key.'}"
            }
          }';
    }

    $conent = <<<EOF
input {
  stdin {
  }
  {$jdbc}
}

filter {
  json {
    source => "message"
      remove_field => ["message"]
  }
}

output {
    {$type}
}
EOF;
    file_put_contents($file, $conent);
}


//delAll($elasticsearch_connect); //delete all elasticsearch index
//createIndex($elasticsearch_connect, $shards); //create elasticsearch index from mysql database
//createOne($elasticsearch_connect, 'test', $shards); //create one elasticsearch index
makeJdbcConf();

echo "\n";
