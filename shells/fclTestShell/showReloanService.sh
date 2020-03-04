#!/bin/sh 
#作者: 史骏马
#时间: 2019年2月21日 16:45:14
#描述：
#      reloan.show即展示 服务状态


# 使用提示
function show_usage()
{
	echo "综合财富平台微信后端服务查看脚本"
	echo  "所有参数都有默认值，也可以在命令行参数中指定。 \n "
	echo "		指定参数: \n		"
	echo "		-b 或--base-dir  定义程序主目录所在位置  默认/u01/app/reloan/source \n "
	echo "			例 -b /u01/app 或  --base-dir=/u01/app  \n "
	
	echo "-h 或 --help 显示帮助参数信息 "
}

echo "开始构建 :\n"
date +%F" "%H:%M:%S

show_usage

################################################################################

#定义服务起始端口
SERVICE_START_PORT=8211

#定义查询的服务
SERVICETOBUILD=("fclgate" "fclwechatweb" "fclservice")


#定义查询的服务
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




# 查看单个服务（使用服务名）
# 参数：  1 服务名（项目名，同目录名）   端口号根据服务名获取
# 说明：  根据服务名取得端口，然后用curl查看
# 不指定打包使用的配置文件 ，在启动时处理配置文件。
function func_service_show()
{
	echo "当前正在根据服务名查看服务${1} "
	service_name=${1}
	
	# 查看服务，需要先取得端口
	#这里的port取得是get_service_port函数里面echo的值!!!
	port=`get_service_port "$service_name"`

	if [[ "$port" != "nothing" ]]
	then 	
		#COMMANDS_CURL=`curl http://localhost:${port}/testOk`
		#CURL_RESULT=(${COMMANDS_CURL})
		echo "${service_name}服务端口是${port}!,返回是"`curl http://localhost:${port}/testOk`
	else
		echo "未取到服务端口，可能服务没有运行，或服务名错误 "
	fi
		
	


}


function func_eureka_show()
{
	echo "当前正在根据服务名查看服务${1} "
	service_name=${1}
	
	# 查看服务，需要先取得端口
	#这里的port取得是get_service_port函数里面echo的值!!!
	port=`get_service_port "$service_name"`
	if [[ "$port" != "nothing" ]]
	then 	
		# 使用curl 发送查看命令 ，如果需要密码，在参数中添加密码
		HTTPRESULT=`curl http://localhost:${port}/info `
					
		RESULT=$(echo $HTTPRESULT | grep '{}' )
		if [[ "$RESULT" != "" ]]
		then
			echo "${service_name}服务端口是${port}!,返回是正常"
		else
			echo "${service_name}服务没有完全启动-------"
		fi
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
# 逻辑描述: 一、先查看业务服务的启动情况
#			二、 查看eurekaserver的启动情况
#
###############################

echo "开始查看服务启动情况..."

# 无参数的情况下，直接查看所有服务（）
if [ ${BUILD_PROJECTS}"X" = "X" ]  ; then

	
	
	
	# 查看每个服务（循环SERVICETOBUID 数组）
	echo "要查看的项目:"${SERVICETOBUILD[@]}
	for service in ${SERVICETOBUILD[@]}
	do	
			# 查看服务
			#echo  "正在查看服务${service}..." 		
			func_service_show ${service}	
			# 查看单个服务
			
	done

else

	# 查看单个服务的情况，已经调用了查看服务的方法。

	SERVICETOBUILD=(${BUILD_PROJECTS})

	echo "要查看的项目:"${SERVICETOBUILD[@]}
	for service in ${SERVICETOBUILD[@]}
	do	
			# 查看服务
			#echo  "正在查看服务${service}..." 		
			func_service_show ${service}	
			# 查看单个服务
			
	done

fi








echo "所有服务已查看。"
date +%F" "%H:%M:%S

