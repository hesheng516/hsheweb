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
#BASE_DIST_DIR="/u01/app/wxfinancetarget"

# ��������Ŀ���Ŀ¼
DIST_USER="finance"
# Ŀ��Ŀ¼�ĸ�Ŀ¼
BASE_DIST_DIR="/home/finance"
DIST_IP="158.1.0.195"
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
SERVICEARRAY=("eurekaserver" "configserver" "zipkin" "gateway" "sysman"  "wxpreweb" "wxservice" "mgate" "wxlcjlweb" "efmanager" "sknow" "pmarketing" "mctools")



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
scp ${BASE_DIR}/shells/devShells/*.sh  ${DIST_DIR}/
ssh ${DIST_USER}@${DIST_IP} "chmod 755 ${DIST_DIR}/*.sh "

# ֹͣ���� TODO:���������ĳ�������񣬾Ͳ�ȫ��ֹͣ��
# ��ʱʹ��kill �������ȫ��ֹͣ��
#ssh ${DIST_USER}@${DIST_IP} "${DIST_DIR}/stopWechatService.sh  -p ${SERVICE_TO_STOPS} " 
ssh ${DIST_USER}@${DIST_IP} "${DIST_DIR}/stopWechatService.sh   " 


# ��������������Ŀ
# ��������������Ŀ  (Ĭ�ϲ����� �����ָ��ʲôֵ������� )
if [  ${SKIPSTARTER}"x" != "falsex"  ] ; then 
	echo "��������"
else
	echo "���ڹ�������������Ŀ..."
	for depend in ${DEPENDENCYARRAY[@]}
	do	
		cd ${BASE_DIR}/${depend}
		mvn clean install -Dmaven.test.skip=${SKIPTEST} -q
 	done
fi

# ��������ָ����Ŀ����ָ����������Ŀ��
# ������Ŀ
if [ ${BUILD_PROJECTS}"x" == "allx" -o ${BUILD_PROJECTS}"x" == "x" ] ; then
	# ѭ��������̨���� ������ ���������û�в�������ȫ������
	# ѭ������ÿ�������ȹ�������ֹͣ ��Ȼ������)  δ���ǹ���ʧ�ܵ��������Ҫ��ע�����
	
	SERVICETOBUILD=${SERVICEARRAY[@]}
else
	#��ֳ�����
	SERVICETOBUILD=(${BUILD_PROJECTS})
fi

echo "Ҫ��������Ŀ:"${SERVICETOBUILD[@]}
for service in ${SERVICETOBUILD[@]}
do	
		# ��������
		echo  "���ڹ�������${service}..."
		func_service_build ${service}	
		#cp target/${service}-0.0.1-SNAPSHOT.jar ${BASE_DIST_DIR}/
		# ������Ŀ�� Ŀ¼ ����
		scp target/${service}-0.0.1-SNAPSHOT.jar ${DIST_DIR}/finance/
done

# �����ͳһ��������ȫ��������  ��������˲�������������������Ӧ���ڷ����н��й���
# local-ip ���ڣ���־ ��  instanceId.  �����������һ������ֻ��ע������ע��һ�����񣡣�����
ssh ${DIST_USER}@${DIST_IP} "${DIST_DIR}/startWechatService.sh  --local-ip=${DIST_IP} " 


echo "�����ɣ�����Ŀ��Ŀ¼��${DIST_DIR}/finance"
date +%F" "%H:%M:%S
