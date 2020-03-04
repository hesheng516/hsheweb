#!/bin/sh
################################################################################
# 作者:   张中伟  zhangzhongwei@joyintech.com
# 时间:   2018年11月6日
# 功能:   综合财富平台微信后端程序打包脚本
# 描述:   一、所有参数都有默认值，也可以在命令行参数中指定。
#			指定参数: 
#			-b 或--base-dir  定义程序主目录所在位置  默认/u01/app/finance/source
#				例 -b /u01/app 或  --base-dir=/u01/app
#			-d 或--dist-dir  定义构建包最后拷贝的位置 默认 /u01/app/finance/dist
#			-v 或 --svn-version 定义要打包的版本（SVN版本号或{时间}），默认HEAD
#			-t 或 --skip-test   默认true忽略测试，指定值非true里，不忽略 
#			-s 或 --skip-starter 默认false 不忽略基本依赖编译，非false时忽略
#			-p 或 --build-projects 项目名列表，逗号分隔
################################################################################

# 使用提示
function show_usage()
{
	echo "打包管理端程序"
	echo "所有参数都有默认值，也可以在命令行参数中指定。 \n "
	echo "		指定参数: \n		"
	echo "		-b 或--base-dir  定义程序主目录所在位置  默认/u01/app/finance/source \n "
	echo "			例 -b /u01/app 或  --base-dir=/u01/app  \n "
	echo "		-d 或--dist-dir  定义构建包最后拷贝的位置 默认 /u01/app/finance/dist "
	echo "		-v 或 --svn-version 定义要打包的版本（SVN版本号或{时间}），默认HEAD "
	echo "		-t 或 --skip-test   默认true忽略测试，指定值非true里，不忽略 "
    echo "		-s 或 --skip-starter 默认false 不忽略基本依赖编译，非false时忽略 "
	echo "-p 或 --build-projects 项目名列表，逗号分隔 "
	echo "-h 或 --help 显示帮助参数信息 "
}

echo "开始构建 :"
date +%F" "%H:%M:%S

show_usage
################################################################################
#参数定义
# 定义默认后台主目录
BASE_DIR="/home/finance/wechatservice/source"

# 定义编译后的拷贝目录
DIST_DIR="/home/finance/wechatservice/dist"

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
SERVICEARRAY=("eurekaserver" "configserver" "zipkin" "gateway" "sysman"  "wxpreweb" "wxservice")



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
	cd $BASE_DIR/wechatservice/${1}
	
	# -q 为静默编译   
	mvn clean install -Dmaven.test.skip=$SKIPTEST  -q
	


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

# 二、使用svn 命令签出或更新程序
if [ "`ls -A `"=""  ] ; then 
	# 默认签出最新版本
	svn checkout http://172.16.68.155:9090/scm/svn/wechatservice/branches . --username zhangzhongwei --password zhangzhongwei
else	
	svn update -r $SVN_VERSION --quiet
fi
echo "SVN 更新程序完成。"



# 三、构建依赖项目
# 构建基本依赖项目  (默认不忽略 ，随便指定什么值都会忽略 )
if [  ${SKIPSTARTER}"x" != "falsex"  ] ; then 
	echo "跳过依赖"
else
	echo "正在构建基本依赖项目..."
	for depend in ${DEPENDENCYARRAY[@]}
	do	
		cd ${BASE_DIR}/wechatservice/${depend}
		mvn clean install -Dmaven.test.skip=${SKIPTEST} -q
 	done
fi

# 四、构建指定项目（不指定则所有项目）
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
		cp target/${service}-0.0.1-SNAPSHOT.jar ${DIST_DIR}/
done

# 最后收集构建包
# 把构建好的项目拷贝到目录（未做检查是否构建成功。 待添加）

#cp ${BASE_DIR}/*/*/*/*SNAPSHOT.jar ${DIST_DIR}/

echo "打包完成！请检查目标目录。${DIST_DIR}"
date +%F" "%H:%M:%S





