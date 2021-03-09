#!/bin/bash
#
#
#将dstat输出到.csv这个文件中 2秒一次 输出10次
#/usr/bin/dstat -tcmdnl --output   /backup_sync/script/monitor.csv 2 10  > /dev/null 2>&1


tmp1="/data/logs/monitor/tmp1.csv"
##tmp2="/data/logs/monitor/tmp2.csv"
datafile="/data/logs/monitor/$1.csv"
rm -f $tmp1
#rm -f $tmp2

## 10分钟
/usr/bin/dstat -tcmdnl 1 650 >> $tmp1  

grep -v "total"  $tmp1|grep -v "usr"  | sed 's#|# #g'| awk   'BEGIN{print "时间\t\tCPU_usr\t\tMem_used\tDisk_writ\tNetwork_Rev\tNetwork_Send\tLoad_1m"  } {print  $2,"\t"$3,"\t""\t"$9,"\t""\t"$14,"\t""\t"$15,"\t""\t"$16,"\t""\t"$17}'  >>  $datafile

<< !
echo -e "CPU_MAX \n` sort  -nrk  2  -t" "  $datafile  |head -1`" > $tmp2
echo -e  "Mem_MAX  \n`sort  -nrk  3  -t" "  $datafile  |head -1 `">> $tmp2
echo -e "Disk_writ \n` sort  -nrk  4  -t" "  $datafile  |head -1 `">> $tmp2
echo -e "Network_Rev \n`  grep "k"  $datafile | sort  -nrk  5  -t" "    |head -1`" >> $tmp2
echo -e "Network_Send \n`  grep  "k"  $datafile| sort  -nrk  6  -t" "    |head -1`" >> $tmp2
echo -e "Load_1m  \n`sort  -nrk  7  -t" "  $datafile  |head -1 `" >> $tmp2 

cat $tmp2 >> $datafile
!

rm -f $tmp1
