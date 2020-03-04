#!/bin/bash 
 #作者: 张中伟
 #时间: 2019-1-14
 #描述：清理ZK和KAFKA的历史文件记录
 #      默认保存近100个文件（待确认是否满足需求）
 #      还需要写一个crontab定时调用这个脚本
 
#snapshot file dir  。 ZK的快照文件目录  （目录待修改） 
dataDir=/home/zookeeper/zkdata/version-2
#tran log dir 。    ZK的日志目录（目录待修改）
dataLogDir=/home/zookeeper/zkdatalog/version-2

kafkalogDir=/home/kafka/kafka_2.12-2.0.0/logs

#清理100天之前的jar包备份文件
find $dataDir -mtime +100 | xargs rm -f 

#清理100天之前的jar包备份文件
find $dataLogDir -mtime +100 | xargs rm -f 

#清理100天之前的jar包备份文件
find $kafkalogDir -mtime +100 | xargs rm -f 


#以上这个脚本定义了删除对应两个目录中的文件，保留最新的100个文件，可以将他写到crontab中，设置为每天凌晨2点执行一次就可以了。


#zk log dir   del the zookeeper log
#logDir=
#ls -t $logDir/zookeeper.log.* | tail -n +$count | xargs rm -f