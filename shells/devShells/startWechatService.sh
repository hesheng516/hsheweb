#!/bin/sh
################################################################################
# 作者:   张中伟  zhangzhongwei@joyintech.com
# 时间:   2018年11月6日
# 功能:   综合财富平台管理端程序打包脚本
# 描述:   一、所有参数都有默认值，也可以在命令行参数中指定。
#			指定参数: 
#			-b 或--base-dir  定义程序主目录所在位置  默认/home/finance/finance
#				例 -b /u01/app 或  --base-dir=/u01/app
#			
################################################################################

# 使用提示
function show_usage()
{
	echo "打包管理端程序"
	echo "所有参数都有默认值，也可以在命令行参数中指定。 \n "
	echo "		指定参数: \n		"
	echo "		-b 或--base-dir  定义程序主目录所在位置  默认/u01/app/finance/source \n "
	echo "			例 -b /u01/app 或  --base-dir=/u01/app  \n "
	
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
EUREKA_URL='http://joyintech:Joyintech2018@158.1.0.195:8100/eureka/'
# 使用的配置文件。  'dev' 'test' 'prod'   目录使用这三个开发、测试 、生产
ACTIVE_PROFILE='dev'

# 数据源连接（ 集群使用SCAN地址  或切换为集群连接字符串 ）
DATASOURCE_URL="jdbc:oracle:thin:@158.1.0.193:1521/orcl"
#DATASOURCE_USER="wechatvalidate"
#DATASOURCE_PASS_DRUID="BoryGMzmDRVAiJ6Kx3i9QPZnReDDhKSqe6Bja880km8um/26G85rBonNAGnor9brfZ1K9lT39sA7DUPdC4kH4g=="
#JOYIN_DRUID_PUBLIC_KEY="MFwwDQYJKoZIhvcNAQEBBQADSwAwSAJBAINvmydO4vNEgc5ehUJf7cj/lWueQzvlxzE32t8HQiHexc9C4QLd7yZLpnu+44haKrfqGRHZVV1RHLgOCZ4SJ1sCAwEAAQ=="

#DATASOURCE_PASS="wechatdev"

#本机端口,用于日志里面
LOG_HOST="158.1.0.195"

# REDIS连接配置（）
#启用自定义的redis单机(true)与集群(false)
JOYIN_REDIS_ENABLED="true"
#redis单机配置
SPRING_REDIS_HOST="158.1.0.197"
SPRING_REDIS_PORT="6379"
#单机集群
SPRING_REDIS_PASSWORD=""
#集群配置
SPRING_REDIS_CLUSTER_NODES="192.168.70.233:7001,192.168.70.233:7002,192.168.70.233:7003"

#kafka连接配置
SPRING_KAFKA_BOOTSTRAP_SERVERS="158.1.0.194:9092"

#sysman文件柜
SYS_FILE_PATH="/home/finance/sysFilePath/"

#rest代理
JOYIN_PROXY_HOST="192.68.70.122"
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

GETOPT_ARGS=`getopt -o b:d: -al base-dir:,dist-dir: -- "$@" `
eval  set -- "$GETOPT_ARGS"

while true ; do
        case "$1"  in
                -b|--base-dir) BASE_DIR="$2"; shift 2 ;;
                -d|--dist-dir) DIST_DIR="$2"; shift 2 ;;
				-v|--svn-version) SVN_VERSION="$2" ; shift 2 ;;
				-t|--skip-test) SKIPTEST="$2" ; shift 2 ;;
				-s|--skip-starter) SKIPSTARTER="$2" ; shift 2 ;;
				-p|--build-projects) BUILD_PROJECTS="$2" ; shift 2 ;;
                --) shift; break ;;
                *)  show_usage exit 1 ;
        esac
done


###############################################################################
# 处理完参数后，组合到服务的启动参数中
PARAM_OPTIONS=" "
PARAM_OPTIONS=" ${PARAM_OPTIONS}  -Dspring.cloud.config.profile=${ACTIVE_PROFILE} "
PARAM_OPTIONS=" ${PARAM_OPTIONS} -Deureka.client.serviceUrl.defaultZone=${EUREKA_URL}"
PARAM_OPTIONS=" ${PARAM_OPTIONS} -Dspring.datasource.url=${DATASOURCE_URL}"

#PARAM_OPTIONS=" ${PARAM_OPTIONS} -Dspring.datasource.username=${DATASOURCE_USER}"
## 必要时：调用druid的加密，把命令行参数中的密码加密，然后在druid 配置中解密 
##PARAM_OPTIONS=" ${PARAM_OPTIONS} -Dspring.datasource.password=${DATASOURCE_PASS}"
#PARAM_OPTIONS=" ${PARAM_OPTIONS}  -Dspring.datasource.password=${DATASOURCE_PASS_DRUID} "
#PARAM_OPTIONS=" ${PARAM_OPTIONS}  -Djoyin.druid.public.key=${JOYIN_DRUID_PUBLIC_KEY} "

#redis配置
PARAM_OPTIONS=" ${PARAM_OPTIONS} -Djoyin.redis.enabled=${JOYIN_REDIS_ENABLED}"
PARAM_OPTIONS=" ${PARAM_OPTIONS} -Dspring.redis.host=${SPRING_REDIS_HOST}"
PARAM_OPTIONS=" ${PARAM_OPTIONS} -Dspring.redis.port=${SPRING_REDIS_PORT}"
PARAM_OPTIONS=" ${PARAM_OPTIONS} -Dspring.redis.password=${SPRING_REDIS_PASSWORD}"
PARAM_OPTIONS=" ${PARAM_OPTIONS} -Dspring.redis.cluster.nodes=${SPRING_REDIS_CLUSTER_NODES}"

#kafka连接配置
PARAM_OPTIONS=" ${PARAM_OPTIONS} -Dspring.kafka.bootstrap-servers=${SPRING_KAFKA_BOOTSTRAP_SERVERS}"

#增加日志路径
PARAM_OPTIONS=" ${PARAM_OPTIONS} -Djoyin.log.dir=${LOG_DIR} "

#增加机器的ip
PARAM_OPTIONS=" ${PARAM_OPTIONS} -Djoyin.log.host=${LOG_HOST} "

#增加sysman文件柜
PARAM_OPTIONS=" ${PARAM_OPTIONS} -Dfilepath=${SYS_FILE_PATH} "

#配置开发环境连接统一平台地址
#PARAM_OPTIONS=" ${PARAM_OPTIONS} -Dwxfinance.lifebankurl=http://172.16.68.158:9090/lifePerbank "
#PARAM_OPTIONS=" ${PARAM_OPTIONS} -Dwxfinance.feeserverurl=http://172.16.68.158:9188/feeServer "

#wxpreweb
##小程序配置
#WXPREWEB_OPTIONS=" ${WXPREWEB_OPTIONS} -Dwx.small.program.appid=wxd07c5e0b84a323bf "
#WXPREWEB_OPTIONS=" ${WXPREWEB_OPTIONS} -Dwx.small.program.secret=abee7bc568a1ffabfa45e417aa753611 "
##公众号配置
#WXPREWEB_OPTIONS=" ${WXPREWEB_OPTIONS} -Dwx.public.number.appid=wxeed6cda52e7b754d "
#WXPREWEB_OPTIONS=" ${WXPREWEB_OPTIONS} -Dwx.public.number.secret=fe18ba613d5f31045bb6a7173626f5d8 "
#WXPREWEB_OPTIONS=" ${WXPREWEB_OPTIONS} -Dwx.public.number.token=1akWHfn8asdfaAXsfarf "
#WXPREWEB_OPTIONS=" ${WXPREWEB_OPTIONS} -Dwx.public.number.EncodingAESKey=sRnLtVfUSRMgu57k4wwQgQVbWJAYxt8pySw9uUcfezF "
#WXPREWEB_OPTIONS=" ${WXPREWEB_OPTIONS} -Dwx.client.grant.type=client_credential "
##access_token类型（02小程序，03公众号），不要轻易改动，数据库sys_access_token初始化数据需要同步改动
WXPREWEB_OPTIONS=" ${WXPREWEB_OPTIONS} -Dwx.small.program.wx.type=02 "
WXPREWEB_OPTIONS=" ${WXPREWEB_OPTIONS} -Dwx.public.number.wx.type=01 "

#WXPREWEB_OPTIONS=" ${WXPREWEB_OPTIONS} -Djoyin.proxy.host=192.68.70.122 "
#WXPREWEB_OPTIONS=" ${WXPREWEB_OPTIONS} -Djoyin.proxy.port=3128 "
WXPREWEB_OPTIONS=" ${WXPREWEB_OPTIONS} -Dwx.file.get.path=https://test.hccb.cc/wefinance_195 "

PARAM_OPTIONS=" ${PARAM_OPTIONS} -Djoyin.proxy.host=192.68.70.122 "
PARAM_OPTIONS=" ${PARAM_OPTIONS} -Djoyin.proxy.port=3128 "

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
#cp /u01/app/wxfinancetarget/*.jar ${BASE_DIR}
chmod +x *.jar
echo "chmod +x *.jar";


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
	EUREKA_SERVER_PARAM="-Xms128m -Xmx256m"
	EUREKA_SERVER_PARAM="${EUREKA_SERVER_PARAM} -Dserver.port=8100"
	EUREKA_SERVER_PARAM="${EUREKA_SERVER_PARAM} -Djoyin.log.name=eurekaserver"
	EUREKA_SERVER_PARAM="${EUREKA_SERVER_PARAM}  -Deureka.client.serviceUrl.defaultZone=${EUREKA_URL}"
	EUREKA_SERVER_PARAM="${EUREKA_SERVER_PARAM}  -Dsecurity.user.password=${EUREKA_PASSWORD}"

	#多个空格变成单个空格
	#EUREKA_SERVER_PARAM="${EUREKA_SERVER_PARAM}"|tr -s''
	
	nohup java ${EUREKA_SERVER_PARAM} -jar eurekaserver-0.0.1-SNAPSHOT.jar >${NOHUP_LOG_DIR}/eurekaserver.log &
	#nohup java ${EUREKA_SERVER_PARAM} -jar eurekaserver-0.0.1-SNAPSHOT.jar > /dev/null 2>&1 &
	
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
	CONFIG_SERVER_PARAM="-Xms128m -Xmx256m"
	CONFIG_SERVER_PARAM="${CONFIG_SERVER_PARAM} -Dserver.port=8888"
	CONFIG_SERVER_PARAM="${CONFIG_SERVER_PARAM} -Djoyin.log.name=configserver"
	CONFIG_SERVER_PARAM="${CONFIG_SERVER_PARAM}  -Deureka.client.serviceUrl.defaultZone=${EUREKA_URL}"
	CONFIG_SERVER_PARAM="${CONFIG_SERVER_PARAM} -Dspring.datasource.url=${DATASOURCE_URL}"
	#数据库连接相关
#  CONFIG_SERVER_PARAM="${CONFIG_SERVER_PARAM} -Dspring.datasource.url=${DATASOURCE_URL}"
#  CONFIG_SERVER_PARAM="${CONFIG_SERVER_PARAM} -Dspring.datasource.username=${DATASOURCE_USER}"   
#  CONFIG_SERVER_PARAM="${CONFIG_SERVER_PARAM} -Dspring.datasource.password=${DATASOURCE_PASS_DRUID}"
#  CONFIG_SERVER_PARAM="${CONFIG_SERVER_PARAM} -Djoyin.druid.public.key=${JOYIN_DRUID_PUBLIC_KEY}"
  
#	CONFIG_SERVER_PARAM="${CONFIG_SERVER_PARAM} -Dspring.datasource.username=${DATASOURCE_USER}"	
#	CONFIG_SERVER_PARAM="${CONFIG_SERVER_PARAM} -Dspring.datasource.password=${DATASOURCE_PASS}"
	#多个空格变成单个空格
	#CONFIG_SERVER_PARAM="${CONFIG_SERVER_PARAM}"|tr -s''
	
	nohup java ${CONFIG_SERVER_PARAM} -jar configserver-0.0.1-SNAPSHOT.jar >${NOHUP_LOG_DIR}/configserver.log &
	#nohup java ${CONFIG_SERVER_PARAM} -jar configserver-0.0.1-SNAPSHOT.jar > /dev/null 2>&1 &
	
	# 打印启动命令观察启动参数是否正确
	echo "nohup java ${CONFIG_SERVER_PARAM} -jar configserver-0.0.1-SNAPSHOT.jar > /dev/null 2>&1 &";
	echo "";
	#等待配置中心启动完成 
	sleep 45
	
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
	GATEWAY_SERVER_PARAM="${GATEWAY_SERVER_PARAM} -Djoyin.zuul.url.validate=${GATEWAY_URL_VALIDATE}"
	GATEWAY_SERVER_PARAM="${GATEWAY_SERVER_PARAM} -Dserver.tomcat.basedir=/home/finance/tmp/gatewayMultipartTemp"
	
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
    			if [ ${service} == "wxpreweb" ];then
                  	BUSI_SERVER_PARAM="${BUSI_SERVER_PARAM} ${WXPREWEB_OPTIONS}"
                  	echo "${service} 添加wxpreweb项目内需要的特殊参数!";
                fi
                  
                if [ ${service} == "sysman" ];then
            		BUSI_SERVER_PARAM="${BUSI_SERVER_PARAM} ${SYSMAN_OPTIONS}"
            		echo "${service} 添加sysman项目内需要的特殊参数!";
            	fi
            	
            	if [ ${service} == "wxlcjlweb" ];then
            		BUSI_SERVER_PARAM="${BUSI_SERVER_PARAM} ${WXLCJLWEB_OPTIONS}"
            		echo "${service} 添加wxlcjlweb项目内需要的特殊参数!";
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

