#!/bin/sh
################################################################################
# ����:   ����ΰ  zhangzhongwei@joyintech.com
# ʱ��:   2018��11��6��
# ����:   �ۺϲƸ�ƽ̨΢�ź�˳������ű�
################################################################################

# ������JAVA ��MAVEN �Ļ�����������ȷ��java��mvn����������
source /u01/app/javamvn.sh
java -version
mvn -v


echo "��ʼ���� :"
date +%F" "%H:%M:%S

################################################################################
#��������
# ����Ĭ�Ϻ�̨��Ŀ¼
BASE_DIR=${WORKSPACE}



# ��������Ŀ���Ŀ¼
DIST_USER="reloan"
# Ŀ��Ŀ¼�ĸ�Ŀ¼
BASE_DIST_DIR="/home/reloan"
DIST_IP="158.1.3.116"
DIST_DIR=${DIST_USER}@${DIST_IP}:${BASE_DIST_DIR}

# ����Ҫ���µİ汾
SVN_VERSION="HEAD"

#���Ի������ı���
SKIPSTARTER="false"

# ���ʱ��������
SKIPTEST="true"

BUILD_PROJECTS="all"

#�������������Ŀ   (�����������Ҫ��˳��)
DEPENDENCYARRAY=("commutils" "syscomm" "starter-joyin")

#���� Ҫ�������Ŀ ע��˳���У�ϵͳ���Ҫ��ǰ�ţ�����������. ע�����ĺ���������һ��Ҫ��������
SERVICEARRAY=("fclgate" "fclwechatweb" "fclservice")

PARAMETERS=("PA_fclgate" "PA_fclwechatweb" "PA_fclservice")

################################################################################

################################################################################
# ����������

# ������������
# ������  ����������Ŀ����ͬĿ¼����
# ˵���� ʹ��mvn clean install ��������������������Ҫ�����mvn��������
# ��ָ�����ʹ�õ������ļ� ��������ʱ���������ļ���
function func_service_build()
{
	echo "��ǰ���ڴ������${1}"
	cd $BASE_DIR/${1}
	
	# -q Ϊ��Ĭ����   
	mvn clean install -Dmaven.test.skip=$SKIPTEST  -q
	


}




###############################################################################
# �ű���ʽ�߼�
# �߼�����: һ�������Ŀ¼
#			����ʹ��svn ������³���
#           ��������������Ŀ
#           �ġ�����ָ����Ŀ����ָ����������Ŀ��
###############################

# �ж�ȷ����Ŀ¼����
if [ ! -d "${BASE_DIR}" ] ; then
	echo "��Ŀ¼�����ڣ�����ȷ����Ŀ¼��ȷ��"
	exit 1;
fi


echo "����ʹ��SVN���³���..."

# ���ָ���˰汾�������͸���ָ���汾
# һ�������Ŀ¼
cd ${BASE_DIR}






# ����ֹͣ�ű��������ű���������
scp ${BASE_DIR}/shells/fclDevShells/*.sh  ${DIST_DIR}/shbin
ssh ${DIST_USER}@${DIST_IP} "chmod 755 ${BASE_DIST_DIR}/shbin/*.sh "

# ֹͣ���� TODO:���������ĳ�������񣬾Ͳ�ȫ��ֹͣ��
# ��ʱʹ��kill �������ȫ��ֹͣ��
#ssh ${DIST_USER}@${DIST_IP} "${DIST_DIR}/stopWechatService.sh  -p ${SERVICE_TO_STOPS} "


STOP_PARAMETERS=""
realParameters=()
i=0

echo "$PARAMETERS"

for parameter in ${PARAMETERS[@]}
do	
		
        realParameter=`eval echo '$'"$parameter"`
        #echo "1${realParameter}"
        #echo "1.1${parameter}"
    	#����������ʵ������Ϊtrue,��ô˵���������ѡ��,��ֵ��realParameters
        #if [$realParameter] ;then
        if [ ${realParameter}"x" == "truex" -o ${realParameter}"x" == "truex" ] ;then
        	parameter=${parameter//PA_/}
            
            if [ ${parameter}"x" == "fmsbatchx" -o ${parameter}"x" == "fmsbatchx" ] ;then
            	parameter="fms-batch"
            fi
            #echo "2${parameter}"
            realParameters[i]=$parameter
            let i++
        fi
        
done


#�������������Ŀ�����ǿ�
if [ ${realParameters}"x" == "x" -o ${realParameters}"x" == "x" ] ; then
	ssh ${DIST_USER}@${DIST_IP} "${BASE_DIST_DIR}/shbin/stopReloanService.sh   " 
else
#�������������Ŀ�������ǿ�,��ô�͹���ָ����Ŀ,��ָֹֻͣ����Ŀ
	echo "ѡ�񹹽�����Ŀ:"${realParameters[@]}
    for stop_parameter in ${realParameters[@]}
	do
    	ssh ${DIST_USER}@${DIST_IP} "${BASE_DIST_DIR}/shbin/stopReloanService.sh -p ${stop_parameter} " 
    done
fi



# ��������������Ŀ
# ��������������Ŀ  (Ĭ�ϲ����� �����ָ��ʲôֵ������� )
if [  ${SKIPSTARTER}"x" != "falsex"  ] ; then 
	echo "��������"
else
	echo "���ڹ�������������Ŀ...${DEPENDENCYARRAY}"
	for depend in ${DEPENDENCYARRAY[@]}
	do	
		cd ${BASE_DIR}/${depend}
		mvn clean install -Dmaven.test.skip=${SKIPTEST} -q
 	done
fi

# ��������ָ����Ŀ����ָ����������Ŀ��
# ������Ŀ
if [ ${realParameters}"x" == "allx" -o ${realParameters}"x" == "x" ] ; then
	# ѭ��������̨���� ������ ���������û�в�������ȫ������
	# ѭ������ÿ�������ȹ�������ֹͣ ��Ȼ������)  δ���ǹ���ʧ�ܵ��������Ҫ��ע�����
	
	SERVICETOBUILD=${SERVICEARRAY[@]}
else
	#��ֳ�����
	#SERVICETOBUILD=(${BUILD_PROJECTS})
    SERVICETOBUILD=${realParameters[@]}
fi

echo "Ҫ��������Ŀ:"${SERVICETOBUILD[@]}
for service in ${SERVICETOBUILD[@]}
do	
		# ��������
		echo  "���ڹ�������${service}..."
		func_service_build ${service}	
		#cp target/${service}-0.0.1-SNAPSHOT.jar ${BASE_DIST_DIR}/
		# ������Ŀ�� Ŀ¼ ����
		scp target/${service}-0.0.1-SNAPSHOT.jar ${DIST_DIR}/app/reloan/
done

# �����ͳһ��������ȫ��������  ��������˲�������������������Ӧ���ڷ����н��й���
# local-ip ���ڣ���־ ��  instanceId.  �����������һ������ֻ��ע������ע��һ�����񣡣�����
ssh ${DIST_USER}@${DIST_IP} "${BASE_DIST_DIR}/shbin/startReloanService.sh " 


echo "�����ɣ�����Ŀ��Ŀ¼��${DIST_DIR}/app/reloan"
date +%F" "%H:%M:%S






