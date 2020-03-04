#!/bin/sh
################################################################################
# 作者:   张中伟  zhangzhongwei@joyintech.com
# 时间:   2018年11月6日
# 功能:   综合财富平台微信后端程序打包脚本
################################################################################

# 先配置JAVA 和MAVEN 的环境变量，以确保java和mvn命令正常。
source /u01/app/javamvn.sh
java -version
mvn -v


echo "开始构建 :"
date +%F" "%H:%M:%S

################################################################################
#参数定义
# 定义默认后台主目录
BASE_DIR=${WORKSPACE}

# 定义编译后的拷贝目录
#BASE_DIST_DIR="/u01/app/wxfinancetarget"

# 定义编译后的拷贝目录
DIST_USER="finance"
# 目标目录的根目录
BASE_DIST_DIR="/home/finance"
DIST_IP="158.1.0.195"
DIST_DIR=${DIST_USER}@${DIST_IP}:${BASE_DIST_DIR}

# 定义要更新的版本
SVN_VERSION="HEAD"

#忽略基本包的编译
SKIPSTARTER="false"

# 打包时跳过测试
SKIPTEST="true"

BUILD_PROJECTS="all"

#定义基本依赖项目   (如果有依赖，要按顺序。)
DEPENDENCYARRAY=("commutils" "syscomm" "starter-joyin")

#定义 要打包的项目 注意顺序中，系统框架要往前放，以优先启动. 注册中心和配置中心一定要先启动。
SERVICEARRAY=("eurekaserver" "configserver" "zipkin" "gateway" "sysman"  "wxpreweb" "wxservice" "mgate" "wxlcjlweb" "efmanager" "sknow" "pmarketing" "mctools")



################################################################################

################################################################################
# 函数定义区

# 构建单个服务
# 参数：  服务名（项目名，同目录名）
# 说明： 使用mvn clean install 命令打包（因依赖服务需要打包到mvn服务器）
# 不指定打包使用的配置文件 ，在启动时处理配置文件。
function func_service_build()
{
	echo "当前正在处理服务${1}"
	cd $BASE_DIR/${1}
	
	# -q 为静默编译   
	mvn clean install -Dmaven.test.skip=$SKIPTEST  -q
	


}




###############################################################################
# 脚本正式逻辑
# 逻辑描述: 一、进入根目录
#			二、使用svn 命令更新程序
#           三、构建依赖项目
#           四、构建指定项目（不指定则所有项目）
###############################

# 判断确认主目录存在
if [ ! -d "${BASE_DIR}" ] ; then
	echo "主目录不存在，请先确认主目录正确！"
	exit 1;
fi


echo "正在使用SVN更新程序..."

# 如果指定了版本参数，就更新指定版本
# 一、进入根目录
cd ${BASE_DIR}

# 拷贝停止脚本和启动脚本到服务器
scp ${BASE_DIR}/shells/devShells/*.sh  ${DIST_DIR}/
ssh ${DIST_USER}@${DIST_IP} "chmod 755 ${DIST_DIR}/*.sh "

# 停止服务（ TODO:如果仅启动某几个服务，就不全部停止）
# 暂时使用kill 命令进行全部停止。
#ssh ${DIST_USER}@${DIST_IP} "${DIST_DIR}/stopWechatService.sh  -p ${SERVICE_TO_STOPS} " 
ssh ${DIST_USER}@${DIST_IP} "${DIST_DIR}/stopWechatService.sh   " 


# 二、构建依赖项目
# 构建基本依赖项目  (默认不忽略 ，随便指定什么值都会忽略 )
if [  ${SKIPSTARTER}"x" != "falsex"  ] ; then 
	echo "跳过依赖"
else
	echo "正在构建基本依赖项目..."
	for depend in ${DEPENDENCYARRAY[@]}
	do	
		cd ${BASE_DIR}/${depend}
		mvn clean install -Dmaven.test.skip=${SKIPTEST} -q
 	done
fi

# 三、构建指定项目（不指定则所有项目）
# 构建项目
if [ ${BUILD_PROJECTS}"x" == "allx" -o ${BUILD_PROJECTS}"x" == "x" ] ; then
	# 循环构建后台服务 并启动 如果命令行没有参数，就全部构建
	# 循环构建每个服务（先构建，再停止 ，然后启动)  未考虑构建失败的情况，需要关注输出！
	
	SERVICETOBUILD=${SERVICEARRAY[@]}
else
	#拆分成数组
	SERVICETOBUILD=(${BUILD_PROJECTS})
fi

echo "要构建的项目:"${SERVICETOBUILD[@]}
for service in ${SERVICETOBUILD[@]}
do	
		# 构建服务
		echo  "正在构建服务${service}..."
		func_service_build ${service}	
		#cp target/${service}-0.0.1-SNAPSHOT.jar ${BASE_DIST_DIR}/
		# 拷贝到目标 目录 （）
		scp target/${service}-0.0.1-SNAPSHOT.jar ${DIST_DIR}/finance/
done

# 如果是统一构建，就全部启动。  如果配置了参数仅构建单个服务，则应该在服务中进行构建
# local-ip 肜于：日志 和  instanceId.  如果两个机子一样，会只在注册中心注册一个服务！！！！
ssh ${DIST_USER}@${DIST_IP} "${DIST_DIR}/startWechatService.sh  --local-ip=${DIST_IP} " 


echo "打包完成！请检查目标目录。${DIST_DIR}/finance"
date +%F" "%H:%M:%S
