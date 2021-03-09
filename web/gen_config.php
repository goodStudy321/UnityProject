<?php

$cfgList = [
    ['config/excel/cfg_item.erl', 'cfg_item.php', 1, [2,3]]
];


$fileDir=dirname(__FILE__);
$serverDir=$fileDir."/../../server/";
$behaviorFile=$serverDir."include/behavior_log.hrl";
$scoreFile=$serverDir."include/role.hrl";
$outDir=$fileDir."/config/server/";

// 生成cfg相关的配置
$cfg=new Cfg();
$cfg->genConfig($serverDir, $outDir, $cfgList);

// 生成货币相关行为
$behavior=new Behavior();
$behavior->genConfig($behaviorFile, $outDir);

// 生成货币key -> name
$score=new Score();
$score->genConfig($scoreFile, $outDir);


// 根据后端配置生成对应映射
class Cfg{
    public function genConfig($serverDir, $outDir, $cfgList)
    {
        $head = "<?php return \n\n";
        $end = ";";
        foreach ($cfgList as $cfg) {
            $erlArray = $this->getConfig($serverDir.$cfg[0]);
            $outArray = array();
            foreach ($erlArray as $erl) {
                $key = $erl[$cfg[2]];
                $value = [];
                foreach ($cfg[3] as $valueKey) {
                    $oneValue = $erl[$valueKey];
                    if (is_string($oneValue)){
                        $oneValue = str_replace('"', '', $oneValue);
                    }
                    array_push($value, $oneValue);
                }
                $outArray[$key] = $value;
            };
            $contents = $head.var_export($outArray, true).$end;
            file_put_contents($outDir.$cfg[1], $contents);
        }
    }

    // 匹配服务器的配置 第二个数组里是配置里{xx,xx,xx}里的内容
    public function getConfig($file)
    {
        $contents = file_get_contents($file);
        if (preg_match_all("/\?C\((\d*)\,\s*{(.*?)}\)/i", $contents, $matches) > 0) {
            $arr=[];
            foreach($matches[2] as $messageDesc) {
                $rs=explode(',',$messageDesc);
                array_push($arr, $rs);
            };
            return $arr;
        } else {
            var_dump($matches);
            throw new Exception ("文件格式出错:$file");
        }
    }
}

// 生成行为日志
class Behavior{
    public function genConfig($file, $outDir)
    {
        $head = "<?php return \n\n";
        $end = ";";
        $outArray = $this->getConfig($file);
        $contents = $head.var_export($outArray, true).$end;
        file_put_contents($outDir."behavior_log.php", $contents);
    }

    public function getConfig($file)
    {
        $contents = file_get_contents($file);
        if (preg_match_all("/\-define\(\w*,\s*(\d*)\s*\).\s*%%\s*(.*)\r/i", $contents, $matches) > 0) {
            $array = [];
            for ($i=0; $i<count($matches[1]); $i++){
                $array[$matches[1][$i]] = $matches[2][$i];
            }
            return $array;
        } else {
            var_dump($matches);
            throw new Exception ("文件格式出错:$file");
        }
    }
}

// 积分字段
class Score{
    public function genConfig($file, $outDir)
    {
        $head = "<?php return \n\n";
        $end = ";";
        $outArray = $this->getConfig($file);
        $contents = $head.var_export($outArray, true).$end;
        file_put_contents($outDir."score.php", $contents);
    }

    public function getConfig($file)
    {
        $contents = file_get_contents($file);
        if (preg_match_all("/\-define\(ASSET_\w*,\s*(\d*)\s*\).\s*%%\s*(.*)\r/i", $contents, $matches) > 0) {
            $array = [];
            for ($i=0; $i<count($matches[1]); $i++){
                $array[$matches[1][$i]] = $matches[2][$i];
            }
            return $array;
        } else {
            var_dump($matches);
            throw new Exception ("文件格式出错:$file");
        }
    }
}
?>