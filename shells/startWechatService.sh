#!/bin/sh
################################################################################
# 作者:   张中伟  zhangzhongwei@joyintech.com
# 时间:   2018年11月6日
# 功能:   综合财富平台微信端服务程序启动脚本
# 描述:   一、所有参数都有默认值，也可以在命令行参数中指定。
#			指定参数: 
#			-b 或--base-dir  定义程序主目录所在位置  默认/home/finance/finance
#				例 -b /u01/app 或  --base-dir=/u01/app
#               -d|--dist-dir) DIST_DIR 目标目录
#				-v|--svn-version) SVN_VERSION   SVN版本
#				-t|--skip-test) SKIPTEST       忽略MAVEN测试  默认忽略
#				-s|--skip-starter) SKIPSTARTER  忽略基本依赖构建 默认不忽略
#				-p|--build-projects) BUILD_PROJECTS   要构建的服务，逗号分隔
#				-l|--local_ip) LOG_HOST                本机IP地址
#			
################################################################################

# 使用提示
function show_usage()
{
	echo "综合财富平台微信端服务程序启动脚本"
	echo "所有参数都有默认值，也可以在命令行参数中指定。 \n "
	echo "		指定参数: \n		"
	echo "		-b 或--base-dir  定义程序主目录所在位置  默认/u01/app/finance/source \n "
	echo "		-d|--dist-dir) DIST_DIR 目标目录   \n "
	echo "		-v|--svn-version) SVN_VERSION   SVN版本  \n "
	echo "		-t|--skip-test) SKIPTEST       忽略MAVEN测试  默认忽略 \n "
	echo "		-s|--skip-starter) SKIPSTARTER  忽略基本依赖构建 默认不忽略 \n "
	echo "		-p|--build-projects) BUILD_PROJECTS   要构建的服务，逗号分隔 \n "
	echo "		-l|--local_ip) LOG_HOST                本机IP地址 \n "
	
	echo "-h 或 --help 显示帮助参数信息 "
}

echo "开始构建 :"
date +%F" "%H:%M:%S

show_usage

################################################################################
#参数定义
# 定义程序主目录
BASE_DIR=/home/finance/finance
# 定义日志目录
LOG_DIR=/home/finance/logs

#定义nohup日志目录
NOHUP_LOG_DIR=/home/finance/testlog

#定义JDK环境变量（应用于服务）#注意事项:一头一尾不能有空格!并且这个参数不能为空
JAVA_OPTIONS="-Xms1024m -Xmx2048m"

#定义TOMCAT环境变量#注意事项:一头一尾不能有空格!
TOMCAT_OPTIONS=""

#定义程序参数变量#注意事项:一头一尾不能有空格!
PARAM_OPTIONS=""


#定义服务起始端口
SERVICE_START_PORT=8211


####################################
# 定义参数
# eureka.client.serviceUrl.defaultZone      ,服务地址可以配多个，逗号分隔
EUREKA_PASSWORD='Joyintech2018'
EUREKA_URL='http://joyintech:Joyintech2018@172.16.67.163:8100/eureka/,http://joyintech:Joyintech2018@172.16.67.164:8100/eureka/'
# 使用的配置文件。  'dev' 'test' 'prod'   目录使用这三个开发、测试 、生产
ACTIVE_PROFILE='dev'

# 数据源连接（ 集群使用SCAN地址  或切换为集群连接字符串 ）
DATASOURCE_URL="jdbc:oracle:thin:@158.1.0.193:1521/orcl"
DATASOURCE_USER="wechattest"
DATASOURCE_PASS="wechattest"
DATASOURCE_PASS_DRUID="JgH+0Klfe6VtiC6cG7iI3Sk5O6Qoy1dmcyiWUCiuvCivIRkFPGo2bXBtAqiQKTC62b/scDPYNJgv7Wu5QpvImQ=="
JOYIN_DRUID_PUBLIC_KEY="MFwwDQYJKoZIhvcNAQEBBQADSwAwSAJBAIrwivoiH0tLdNsZDs/4RbdLie3eb0hBERYcyodtwCbCu/rT36+hks6uEO17TRggwCiooW34X4G7eMvTpOFWKbsCAwEAAQ=="

#本机端口,用于日志里面  本机IP地址(用于日志)
LOG_HOST="172.16.67.163"

SERVICE_ID=`cat /home/finance/serviceId`
LOG_HOST=$SERVICE_ID

# REDIS连接配置（）
#启用自定义的redis单机(true)与集群(false)
JOYIN_REDIS_ENABLED="false"
#redis单机配置
SPRING_REDIS_HOST="197.68.11.165"
SPRING_REDIS_PORT="6379"
#单机集群
SPRING_REDIS_PASSWORD=""
#集群配置 redis real master node is 165:6380 168:6380 168:6381
SPRING_REDIS_CLUSTER_NODES="172.16.67.165:6380,172.16.67.167:6380,172.16.67.168:6380,172.16.67.168:6381"

#kafka连接配置
SPRING_KAFKA_BOOTSTRAP_SERVERS="197.68.11.165:9092,197.68.11.166:9092,197.68.11.167:9092"

#sysman文件柜
SYS_FILE_PATH="/u01/app/nfsfiles/"

#rest代理
JOYIN_PROXY_HOST="172.16.69.9"
JOYIN_PROXY_PORT="3128"


#网关url权限过滤开关,true为开启,false为关闭
#WE理财权限过滤
GATEWAY_URL_VALIDATE="true"
#理财经理权限过滤
MGATE_URL_VALIDATE="true"

#定义 启动的项目，系统框架排除了,再外面额外定义启动
SERVICETOBUILD=("sysman" "wxservice" "wxpreweb" "wxlcjlweb" "efmanager" "sknow" "pmarketing" "mctools")



################################################################################

################################################################################
# 函数定义区

# 函数，判断端口是否已经占用
function is_port_used()
{
	# 待添加判断端口占用情况，如果占用，持续加1
	#PORTUSEDCOUNT=$(  netstat -an|grep ${1}|wc -l )
	#root用户才能用-lnp!
	PORTUSEDCOUNT=netstat -lnp|grep ${1}|wc -l
	if [ ${PORTUSEDCOUNT}>0 ] ; then
		return 1;
	else
		return 0;
	fi
}


################################################################################
# 参数处理区
# 处理一下命令行参数，并赋值到参数变量中。  添加参数需要同样的格式。

GETOPT_ARGS=`getopt -o b:d:v:t:s:p:l: -al base-dir:,dist-dir:,svn-version:,skip-test:,skip-starter:,build-projects:,local-ip: -- "$@" `

eval  set -- "$GETOPT_ARGS"

while true ; do
        case "$1"  in
                -b|--base-dir) BASE_DIR="$2"; shift 2 ;;
                -d|--dist-dir) DIST_DIR="$2"; shift 2 ;;
				-v|--svn-version) SVN_VERSION="$2" ; shift 2 ;;
				-t|--skip-test) SKIPTEST="$2" ; shift 2 ;;
				-s|--skip-starter) SKIPSTARTER="$2" ; shift 2 ;;
				-p|--build-projects) BUILD_PROJECTS="$2" ; shift 2 ;;
				-l|--local-ip) LOG_HOST="$2" ;  shift 2 ;;
                --) shift; break ;;
                *)  show_usage exit 1 ;
        esac
done


###############################################################################
# 处理完参数后，组合到服务的启动参数中
PARAM_OPTIONS=" "
PARAM_OPTIONS=" ${PARAM_OPTIONS}  -Dspring.cloud.config.profile=${ACTIVE_PROFILE} "
PARAM_OPTIONS=" ${PARAM_OPTIONS}  -Deureka.client.serviceUrl.defaultZone=${EUREKA_URL} "
PARAM_OPTIONS=" ${PARAM_OPTIONS}  -Dspring.datasource.url=${DATASOURCE_URL} "
PARAM_OPTIONS=" ${PARAM_OPTIONS}  -Dspring.datasource.username=${DATASOURCE_USER} "
# 必要时：调用druid的加密，把命令行参数中的密码加密，然后在druid 配置中解密 
#PARAM_OPTIONS=" ${PARAM_OPTIONS}  -Dspring.datasource.password=${DATASOURCE_PASS} "
PARAM_OPTIONS=" ${PARAM_OPTIONS}  -Dspring.datasource.password=${DATASOURCE_PASS_DRUID} "
PARAM_OPTIONS=" ${PARAM_OPTIONS}  -Djoyin.druid.public.key=${JOYIN_DRUID_PUBLIC_KEY} "



#redis配置
PARAM_OPTIONS=" ${PARAM_OPTIONS} -Djoyin.redis.enabled=${JOYIN_REDIS_ENABLED}"
PARAM_OPTIONS=" ${PARAM_OPTIONS} -Dspring.redis.host=${SPRING_REDIS_HOST}"
PARAM_OPTIONS=" ${PARAM_OPTIONS} -Dspring.redis.port=${SPRING_REDIS_PORT}"
PARAM_OPTIONS=" ${PARAM_OPTIONS} -Dspring.redis.password=${SPRING_REDIS_PASSWORD}"
PARAM_OPTIONS=" ${PARAM_OPTIONS} -Dspring.redis.cluster.nodes=${SPRING_REDIS_CLUSTER_NODES}"

#kafka配置
PARAM_OPTIONS=" ${PARAM_OPTIONS} -Dspring.kafka.bootstrap-servers=${SPRING_KAFKA_BOOTSTRAP_SERVERS}"

#增加日志路径
PARAM_OPTIONS=" ${PARAM_OPTIONS}  -Djoyin.log.dir=${LOG_DIR} "

#增加机器的ip
PARAM_OPTIONS=" ${PARAM_OPTIONS}  -Djoyin.log.host=${LOG_HOST} "

#增加sysman文件柜
PARAM_OPTIONS=" ${PARAM_OPTIONS} -Dfilepath=${SYS_FILE_PATH} "

#增加rest代理地址
PARAM_OPTIONS=" ${PARAM_OPTIONS} -Djoyin.proxy.host=${JOYIN_PROXY_HOST} "
PARAM_OPTIONS=" ${PARAM_OPTIONS} -Djoyin.proxy.port=${JOYIN_PROXY_PORT} "

SYSMAN_OPTIONS=""
#自定义上传文件临时文件夹
SYSMAN_OPTIONS=" ${SYSMAN_OPTIONS} -Dserver.tomcat.basedir=/home/finance/file/sysmanMultipartTemp "

###############################################################################

###############################################################################
# 脚本正式逻辑
# 逻辑描述: 一、启动eurekaserver
#			二、启动configserver (需要eurekaserver 启动成功）
#			三、启动gateway      (可以不需要判断和等待）
#			四、启动其他节点
# 注意事项:
#           一、需要添加判断eurekaserver是否已启动。
#			二、注册中心、配置中心、网关端口固定 。
#			三、其他服务端口使用递增（不使用数据库中的配置端口），从
#
###############################

# 判断确认主目录存在
if [ ! -d "${BASE_DIR}" ] ; then
	echo "主目录不存在，请先确认主目录正确！"
	exit 1;
fi

#进入主目录
cd ${BASE_DIR}
echo "cd ${BASE_DIR}";

#赋予jar可执行权限
chmod +x *.jar
echo "chmod +x *.jar";

# 杀死所有JAVA进程（暂时没设置更好的关闭服务的方法。后续修改。 可以按服务关闭或整体关闭）
# 关闭脚本独立提供
# ps -aux|grep SNAPSHOT|awk ' { if ($11=="java") { print $2 } }' |xargs kill -9


# 判断EUREKA启动情况 （如果已经启动则不变，未启动则启动. 或停止后再启动？）
# 主要使用端口配置和注册地址配置。  其他几个配置原则上也应该指定，后续添加
# 端口如果修改了，注册地址也要跟着改（还有集群的注册地址）
# 应固定注册中心的端口
# 注册中心每服务器只启动一个，保证集群中最少有两个节点就可以了。

PROCESSID=$(ps -aux | grep "eurekaserver" | awk '{ if($11=="java") { print $2} } ' )
if [ ! -z "${PROCESSID}" ] ; then
	echo "eurekaserver 服务已经启动!";
else
	# 参数处理
	EUREKA_SERVER_PARAM="${JAVA_OPTIONS}"
	EUREKA_SERVER_PARAM="${EUREKA_SERVER_PARAM} -Dserver.port=8100"
	EUREKA_SERVER_PARAM="${EUREKA_SERVER_PARAM} -Djoyin.log.name=eurekaserver"
	EUREKA_SERVER_PARAM="${EUREKA_SERVER_PARAM}  -Deureka.client.serviceUrl.defaultZone=${EUREKA_URL}"
	EUREKA_SERVER_PARAM="${EUREKA_SERVER_PARAM}  -Dsecurity.user.password=${EUREKA_PASSWORD}"
  #使用IP+端口注册eureka
	EUREKA_SERVER_PARAM="${EUREKA_SERVER_PARAM} -Deureka.instance.preferIpAdress=true"
	EUREKA_SERVER_PARAM="${EUREKA_SERVER_PARAM}  -Deureka.instance.instance-id=${LOG_HOST}:8100"
	#
	EUREKA_SERVER_PARAM="${EUREKA_SERVER_PARAM}  -Dhystrix.command.default.execution.isolation.thread.timeoutInMilliseconds=60000 "
	#注册中心的保护机制,为true时,默认心跳三次超时后剔除服务
  EUREKA_SERVER_PARAM="${EUREKA_SERVER_PARAM}  -Deureka.server.enable-self-preservation=true"
  #增加日志路径
	EUREKA_SERVER_PARAM=" ${EUREKA_SERVER_PARAM}  -Djoyin.log.dir=${LOG_DIR} "
	#增加机器的ip
	EUREKA_SERVER_PARAM=" ${EUREKA_SERVER_PARAM}  -Djoyin.log.host=${LOG_HOST} "

	#多个空格变成单个空格
	#EUREKA_SERVER_PARAM="${EUREKA_SERVER_PARAM}"|tr -s''
	
	#nohup java ${EUREKA_SERVER_PARAM} -jar eurekaserver-0.0.1-SNAPSHOT.jar > /dev/null 2>&1 &
	nohup java ${EUREKA_SERVER_PARAM} -jar eurekaserver-0.0.1-SNAPSHOT.jar > ${NOHUP_LOG_DIR}/eurekaserver.log &
	#参数打印
	echo "nohup java ${EUREKA_SERVER_PARAM} -jar eurekaserver-0.0.1-SNAPSHOT.jar > /dev/null 2>&1 &";
	echo "";
	# 注册服务启动是否可以不需要等待就启动其他服务？  最好是等启动完毕？需要确认。
	# 等待20秒以保证启动完成 
	sleep 25
	
fi



# 判断配置中心的启动情况  启动配置中心. 配置中心每个服务器只启动一个，保证集群即可。
# 配置中心端口可以跟随总体端口递归，这里也指定固定值。
PROCESSID=$(ps -aux | grep "configserver" | awk '{ if($11=="java") { print $2} } ' )
if [ ! -z "${PROCESSID}" ] ; then
	echo "configserver 服务已经启动!";
else
	# java参数需要重新组合
	CONFIG_SERVER_PARAM="${JAVA_OPTIONS}"
	CONFIG_SERVER_PARAM="${CONFIG_SERVER_PARAM} -Dserver.port=8888"
	CONFIG_SERVER_PARAM="${CONFIG_SERVER_PARAM} -Djoyin.log.name=configserver"
	CONFIG_SERVER_PARAM="${CONFIG_SERVER_PARAM}  -Deureka.client.serviceUrl.defaultZone=${EUREKA_URL}"
	#使用IP+端口注册eureka
	CONFIG_SERVER_PARAM="${CONFIG_SERVER_PARAM} -Deureka.instance.preferIpAdress=true"
	CONFIG_SERVER_PARAM="${CONFIG_SERVER_PARAM} -Deureka.instance.instance-id=${LOG_HOST}:8888"
	#数据库连接相关
	CONFIG_SERVER_PARAM="${CONFIG_SERVER_PARAM} -Dspring.datasource.url=${DATASOURCE_URL}"
  CONFIG_SERVER_PARAM="${CONFIG_SERVER_PARAM} -Dspring.datasource.username=${DATASOURCE_USER}"   	
	#CONFIG_SERVER_PARAM="${CONFIG_SERVER_PARAM} -Dspring.datasource.password=${DATASOURCE_PASS}"
	CONFIG_SERVER_PARAM="${CONFIG_SERVER_PARAM} -Dspring.datasource.password=${DATASOURCE_PASS_DRUID}"
	CONFIG_SERVER_PARAM="${CONFIG_SERVER_PARAM} -Djoyin.druid.public.key=${JOYIN_DRUID_PUBLIC_KEY}"
	#增加日志路径
	CONFIG_SERVER_PARAM=" ${CONFIG_SERVER_PARAM}  -Djoyin.log.dir=${LOG_DIR} "
	#增加机器的ip
	CONFIG_SERVER_PARAM=" ${CONFIG_SERVER_PARAM}  -Djoyin.log.host=${LOG_HOST} "
	
	#多个空格变成单个空格
	#CONFIG_SERVER_PARAM="${CONFIG_SERVER_PARAM}"|tr -s''
	
	#nohup java ${CONFIG_SERVER_PARAM} -jar configserver-0.0.1-SNAPSHOT.jar > /dev/null 2>&1 &
	nohup java ${CONFIG_SERVER_PARAM} -jar configserver-0.0.1-SNAPSHOT.jar >${NOHUP_LOG_DIR}/configserver.log &
	# 打印启动命令观察启动参数是否正确
	echo "nohup java $CONFIG_SERVER_PARAM} -jar configserver-0.0.1-SNAPSHOT.jar > /dev/null 2>&1 &";
	echo "";
	#等待配置中心启动完成 
	sleep 40
	
fi

# 网关指定固定端口启动
PROCESSID=$(ps -aux | grep "gateway" | awk '{ if($11=="java") { print $2} } ' )
if [ ! -z "${PROCESSID}" ] ; then
	echo "gateway 服务已经启动!";
else
	#定义业务服务启动参数
	GATEWAY_SERVER_PARAM="${JAVA_OPTIONS}"
	GATEWAY_SERVER_PARAM="${GATEWAY_SERVER_PARAM} ${TOMCAT_OPTIONS}"
	GATEWAY_SERVER_PARAM="${GATEWAY_SERVER_PARAM} ${PARAM_OPTIONS}"
	GATEWAY_SERVER_PARAM="${GATEWAY_SERVER_PARAM} -Dserver.port=8130"
	GATEWAY_SERVER_PARAM="${GATEWAY_SERVER_PARAM} -Djoyin.log.name=gateway"
	#使用IP+端口注册eureka
  GATEWAY_SERVER_PARAM="${GATEWAY_SERVER_PARAM} -Deureka.instance.preferIpAdress=true"
  GATEWAY_SERVER_PARAM="${GATEWAY_SERVER_PARAM} -Deureka.instance.instance-id=${LOG_HOST}:8130"
  GATEWAY_SERVER_PARAM="${GATEWAY_SERVER_PARAM} -Djoyin.zuul.url.validate=${GATEWAY_URL_VALIDATE}"
	GATEWAY_SERVER_PARAM="${GATEWAY_SERVER_PARAM} -Dserver.tomcat.basedir=/home/finance/file/gatewayMultipartTemp"
	
	nohup java ${GATEWAY_SERVER_PARAM} -jar gateway-0.0.1-SNAPSHOT.jar >  ${NOHUP_LOG_DIR}/gateway.log &	
	#nohup java ${GATEWAY_SERVER_PARAM} -jar gateway-0.0.1-SNAPSHOT.jar > /dev/null 2>&1 &
	
	# 打印启动命令观察启动参数是否正确
	echo "nohup java ${GATEWAY_SERVER_PARAM} -jar gateway-0.0.1-SNAPSHOT.jar > /dev/null 2>&1 &";
	echo "";
	#不需要等待配置中心启动完成 
	#sleep 20
	
fi


# 理财经理网关指定固定端口启动
PROCESSID=$(ps -aux | grep "mgate" | awk '{ if($11=="java") { print $2} } ' )
if [ ! -z "${PROCESSID}" ] ; then
	echo "mgate 服务已经启动!";
else
	#定义业务服务启动参数
	MGATE_SERVER_PARAM="${JAVA_OPTIONS}"
	MGATE_SERVER_PARAM="${MGATE_SERVER_PARAM} ${TOMCAT_OPTIONS}"
	MGATE_SERVER_PARAM="${MGATE_SERVER_PARAM} ${PARAM_OPTIONS}"
	MGATE_SERVER_PARAM="${MGATE_SERVER_PARAM} -Dserver.port=9130"
	MGATE_SERVER_PARAM="${MGATE_SERVER_PARAM} -Djoyin.log.name=mgate"
    MGATE_SERVER_PARAM="${MGATE_SERVER_PARAM} -Djoyin.zuul.url.validate=${MGATE_URL_VALIDATE}"
	#使用IP+端口注册eureka
  MGATE_SERVER_PARAM="${MGATE_SERVER_PARAM} -Deureka.instance.preferIpAdress=true"
  MGATE_SERVER_PARAM="${MGATE_SERVER_PARAM} -Deureka.instance.instance-id=${LOG_HOST}:9130"
	MGATE_SERVER_PARAM="${MGATE_SERVER_PARAM} -Dserver.tomcat.basedir=/home/finance/tmp/mgateMultipartTemp"
	
	nohup java ${MGATE_SERVER_PARAM} -jar mgate-0.0.1-SNAPSHOT.jar >  ${NOHUP_LOG_DIR}/mgate.log &	
	#nohup java ${MGATE_SERVER_PARAM} -jar mgate-0.0.1-SNAPSHOT.jar > /dev/null 2>&1 &
	
	# 打印启动命令观察启动参数是否正确
	echo "nohup java ${MGATE_SERVER_PARAM} -jar mgate-0.0.1-SNAPSHOT.jar > /dev/null 2>&1 &";
	echo "";
	#不需要等待配置中心启动完成 
	#sleep 20
	
fi

###############################################################################
# zipkin 启动 （暂时未用到 后续添加）
###############################################################################

#遍历启动各个服务
echo "要启动的服务:"${SERVICETOBUILD[@]}
for service in ${SERVICETOBUILD[@]}
do

		# 端口自增
		SERVICE_START_PORT=$((${SERVICE_START_PORT}+1))
		


                BUSI_PROCESSID=$(ps -aux | grep ${service}-0.0.1-SNAPSHOT.jar| awk '{ if($11=="java") { print $2} } ' )
                if [ ! -z "${BUSI_PROCESSID}" ] ; then
                        echo "${service} 服务已经启动!";
                else
                        # 只有当这个服务需要时才能够加1,否则和上面的自增重复,导致反复重启端口不一致
                        # 判断自增后的端口是否被占用
                        while [ $(netstat -lnp|grep ${SERVICE_START_PORT}|wc -l)"x" != "0x" ] ; do
                                SERVICE_START_PORT=$((${SERVICE_START_PORT}+1))
                        done
                        
                        #定义业务服务启动参数
                        BUSI_SERVER_PARAM="${JAVA_OPTIONS}"
                        BUSI_SERVER_PARAM="${BUSI_SERVER_PARAM} ${PARAM_OPTIONS}"
                        BUSI_SERVER_PARAM="${BUSI_SERVER_PARAM} -Dserver.port=${SERVICE_START_PORT} "
                        BUSI_SERVER_PARAM="${BUSI_SERVER_PARAM} -Djoyin.log.name=${service}"
                        BUSI_SERVER_PARAM="${BUSI_SERVER_PARAM} -Deureka.instance.preferIpAdress=true"
                        BUSI_SERVER_PARAM="${BUSI_SERVER_PARAM} -Deureka.instance.instance-id=${LOG_HOST}:${SERVICE_START_PORT}"
												
												if [ ${service} == "sysman" ];then
      										BUSI_SERVER_PARAM="${BUSI_SERVER_PARAM} ${SYSMAN_OPTIONS}"
      										echo "${service} 添加sysman项目内需要的特殊参数!";
												fi
      
                        # 启动服务
                        echo  "正在启动服务${service}...端口${SERVICE_START_PORT}"
                        nohup java ${BUSI_SERVER_PARAM} -jar ${service}-0.0.1-SNAPSHOT.jar > ${NOHUP_LOG_DIR}/${service}.log &
                        #nohup java ${BUSI_SERVER_PARAM} -jar ${service}-0.0.1-SNAPSHOT.jar > /dev/null 2>&1 &

                        sleep 1
                        # 打印启动命令观察启动参数是否正确
                        echo "nohup java ${BUSI_SERVER_PARAM} -jar ${service}-0.0.1-SNAPSHOT.jar > /dev/null 2>&1 &";
                        echo "";
                        # 暂不判断启动结果
                fi
done



echo "启动完成,请检查启动的程序是否正确。"
date +%F" "%H:%M:%S





