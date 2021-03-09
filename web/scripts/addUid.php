<?php

function mysqlConf(){
    return [
        //'hostname' => '192.168.2.250',
        'hostname' => '115.159.68.105',
        'username' => 'datauser',
        'password' => 'mfpmaLSTAfwQJ13mBoSFDc4m0bmfCQgd',
        //'database' => 'admin_local_1',
        'database' => 'admin_local_1',
    ];
}

function test(){
    $mysql = mysqlConf();
    $link = new mysqli($mysql['hostname'], $mysql['username'], $mysql['password'], 'admin_local_1');
    $sql = "select id,account_name from log_role_status WHERE uid ='' or uid is null\n";
    $result = $link->query($sql);
    if(!$result)
        die("mysqli error\n");

    while($row = $result->fetch_object()){
        print_r($row);
        die;
    }
}


function clean(){
    $mysql = mysqlConf();

    $databases = [
        //'admin_local_1',
        'admin_junhai_1',
        'admin_junhai_2',
        'admin_junhai_3',
        'admin_junhai_4',
    ];

    foreach($databases as $name){
        $data = [];
        $link = new mysqli($mysql['hostname'], $mysql['username'], $mysql['password'], $name);
        $result = $link->query("select id,account_name from log_role_status WHERE uid ='' or uid is null order by id desc");
        if(!$result)
            die("mysqli error\n");

        while($row = $result->fetch_object()){
            $uid = $row->account_name ? explode('_',$row->account_name) : [];
            $uid = $uid ? end($uid) : '';
            $sql = "UPDATE log_role_status SET uid='{$uid}' WHERE id='{$row->id}'";
            echo $sql, "\n";
            $link->query($sql);
        }
        mysqli_close($link);
    }



    die("done \n");
}



clean();
//test();

echo "\n";
