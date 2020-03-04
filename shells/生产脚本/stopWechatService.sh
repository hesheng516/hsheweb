#!/bin/sh
################################################################################
# 作者:   张中伟  zhangzhongwei@joyintech.com
# 时间:   2018年12月11日19:22:25
# 功能:   综合财富平台KEYBOARD后端服务停止脚本
#         停止服务的脚本。
#         不使用参数时， 停止所有服务（测试环境可以使用kill -9)
#         可以使用参数停止某几个服务。（使用参数时，不停止注册中心、配置中心）
################################################################################

# 先配置JAVA 和MAVEN 的环境变量，以确保java和mvn命令正常。（已配置为全局命令）
#source /u01/app/javamvn.sh
#java -version
#mvn -v


# 使用提示
function show_usage()
{
	echo "综合财富平台微信后端服务停止脚本"
	echo  "所有参数都有默认值，也可以在命令行参数中指定。 \n "
	echo "		指定参数: \n		"
	echo "		-b 或--base-dir  定义程序主目录所在位置  默认/u01/app/finance/source \n "
	echo "			例 -b /u01/app 或  --base-dir=/u01/app  \n "
	
	echo "-h 或 --help 显示帮助参数信息 "
}

echo "开始构建 :\n"
date +%F" "%H:%M:%S

show_usage

################################################################################

#定义服务起始端口
SERVICE_START_PORT=8211

#定义可以停止的服务
SERVICETOBUILD=("sysman" "wxservice" "wxpreweb")

#定义要停止的服务
BUILD_PROJECTS=""

################################################################################

################################################################################
# 函数定义区

# 函数，判断端口是否已经占用
function is_port_used()
{
	# 待添加判断端口占用情况，如果占用，持续加1
	#PORTUSEDCOUNT=$(  netstat -an|grep ${1}|wc -l )
	#root用户才能用-lnp!（可以获取所有用户的端口）
	PORTUSEDCOUNT=netstat -lnp|grep ${1}|wc -l
	if [ ${PORTUSEDCOUNT}>0 ] ; then
		return 1;
	else
		return 0;
	fi
}
# 根据服务名取得端口
# 参数: 1 服务名，例如 wxpreweb
# 说明：通过ps 命令，从系统进程中取得启动服务时的命令 ，命令行中包含-Dserver.port=
#       从其中取得端口号
# 返回：端口号,如果未找到-Dserver.port参数，则返回nothing
#
function get_service_port()
{
	
	# 使用PS命令取得命令行参数 （传入参数为服务名）
	COMMANDS_LINE=`ps -aux|grep ${1}|awk ' { if ($11=="java") { print  } }'`
	
	

	# 使用空格拆分命令行为数组
	COM_PARAM_ARRAY=(${COMMANDS_LINE})
	
	#echo "正在根据服务名${1}获取端口 "

	#遍历数组取得端口
	for param in ${COM_PARAM_ARRAY[@]}
	do
			include=$(echo $param | grep 'server.port')
			if [[ ${include}"X" != "X" ]]
			then
					#echo ${include}"取得的端口是"${include#*=}
					# 使用#运算符，截取=号右边的字符
					echo ${include#*=}
					return ${include#*=}			
			fi
	done

	# 如果没有找到
	return "nothing"

}

# 停止单个服务（使用端口号）
# 参数：  1 端口号
# 说明：  根据服务名取得端口，然后进行停止（测试环境暂时直接kill）
# 不指定打包使用的配置文件 ，在启动时处理配置文件。
function func_service_stop_port()
{
	
	
	# 优雅的停止服务，需要先取得端口
	port=${1}
	echo "当前正在根据端口停止服务,端口是${1}! \n"
	
	echo "`curl -X POST http://localhost:${port}/shutdown ` "
	# 使用curl 发送停止命令 ，如果需要密码，在参数中添加密码
	HTTPRESULT=`curl -X POST http://localhost:${port}/shutdown ` 
	
	RESULT=$(echo $HTTPRESULT | grep 'Shutting' )
	if [[ "$RESULT" != "" ]]
	then
		# 等待后台任务执行完成。 时间根据最长业务时间确定
		sleep 5
		echo "${service_name}服务已经成功关闭 "
	else
		# 关闭服务响应不正确。 可能需要再次检查端口和服务状态。。。
		echo "${service_name}关闭服务响应不正确，请检查服务是否关闭 "
		# 或者考虑强行关闭一次
		# ps -aux|grep ${1}|awk ' { if ($11=="java") { print $2 } }' |xargs kill -9
	fi
		
	


}


# 停止单个服务（使用服务名）
# 参数：  1 服务名（项目名，同目录名）   端口号根据服务名获取
# 说明：  根据服务名取得端口，然后进行停止（测试环境暂时直接kill）
# 不指定打包使用的配置文件 ，在启动时处理配置文件。
function func_service_stop()
{
	echo "当前正在根据服务名停止服务${1} "
	service_name=${1}
	# 优雅的停止服务，需要先取得端口
	#这里的port取得是get_service_port函数里面echo的值!!!
	port=`get_service_port "$service_name"`
	
	if [[ "$port" != "nothing" ]]
	then 	
		echo "\n取到端口是$port"
		# 取到端口的，直接按端口关闭
		func_service_stop_port  $port
	else
		echo "未取到服务端口，可能服务没有运行，或服务名错误 "
	fi
		
	


}








################################################################################
# 参数处理区
# 处理一下命令行参数，并赋值到参数变量中。  添加参数需要同样的格式。

GETOPT_ARGS=`getopt -o b:d:p:h -al base-dir:,dist-dir: -- "$@" `
eval  set -- "$GETOPT_ARGS"

while true ; do
        case "$1"  in                
				-p|--build-projects) BUILD_PROJECTS="$2" ; shift 2 ;;
				
				-l|--local_ip) LOG_HOST="$2" ;  shift 2 ;;
				
                --) shift; break ;
                #*)  show_usage exit 1 ;;
                #-h|--help) show_usage exit 1 ;
        esac
done


###############################################################################
# 处理完参数后，组合到服务的启动参数中

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

echo "开始停止服务..."

# 判断是否需要停止所有服务（条件:无服务参数）

# 无参数的情况下，直接停止所有服务（）
if [ ${BUILD_PROJECTS}"X" = "X" ]  ; then

	
	
	
	# 停止每个服务（循环SERVICETOBUID 数组）
	echo "要停止的项目:"${SERVICETOBUILD[@]}
	for service in ${SERVICETOBUILD[@]}
	do	
			# 停止服务
			#echo  "正在停止服务${service}..." 		
			func_service_stop ${service}	
			# 停止单个服务
			
	done
	
	# 停止网关
	func_service_stop 'gateway'
	
	# 停止注册中心
	func_service_stop 'configserver'
	
	# 停止配置服务器
	func_service_stop 'eurekaserver'
	

	
	# 杀死所有JAVA进程（暂时没设置更好的关闭服务的方法。后续修改。 可以按服务关闭或整体关闭）
	# 可以做为最后的手段。
	ps -aux|grep SNAPSHOT|awk ' { if ($11=="java") { print $2 } }' |xargs kill -9

else

	# 停止单个服务的情况，已经调用了关闭服务的方法。

	SERVICETOBUILD=(${BUILD_PROJECTS})

	echo "要停止的项目:"${SERVICETOBUILD[@]}
	for service in ${SERVICETOBUILD[@]}
	do	
			# 停止服务
			#echo  "正在停止服务${service}..." 		
			func_service_stop ${service}	
			# 停止单个服务
			
	done

fi








echo "所有服务已停止。"
date +%F" "%H:%M:%S

