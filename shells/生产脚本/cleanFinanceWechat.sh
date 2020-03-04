#!/bin/bash 
 #作者: 张中伟
 #时间: 2019-1-14
 #描述：清理ZK和KAFKA的历史文件记录
 #      默认保存近100个文件（待确认是否满足需求）
 #      还需要写一个crontab定时调用这个脚本
 
#定义app服务jar包备份路径
APP_BAK_DIR=/home/finance/backup

# 定义日志目录
LOG_DIR=/home/finance/logs

#上传文件临时目录
UPLOAD_TEMP_DIR=/home/finance/file/joyintech/temporary

#清理100天之前的jar包备份文件
find $APP_BAK_DIR -mtime +100 | xargs rm -f 

#清理100天之前的日志文件
find $LOG_DIR -mtime +100 | xargs rm -f 

#清理100天之前的上传文件
find $UPLOAD_TEMP_DIR -mtime +100 | xargs rm -f 


#以上这个脚本定义了删除对应两个目录中的文件，保留最新的100个文件，可以将他写到crontab中，设置为每天凌晨2点执行一次就可以了。


#zk log dir   del the zookeeper log
#logDir=
#ls -t $logDir/zookeeper.log.* | tail -n +$count | xargs rm -f