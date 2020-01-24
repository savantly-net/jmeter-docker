#!/bin/sh

# modified version of https://github.com/vmarrazzo/docker-jmeter/blob/jmeter_4_0/docker_distributed_jmeter.sh

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
TEST_PLAN_DIR=${DIR}/example_tests
TEST_PLAN_FILE=test.jmx

while getopts ":d:t:" opt; do
  case $opt in
    d) TEST_PLAN_DIR="$OPTARG"
    ;;
    t) TEST_PLAN_FILE="$OPTARG"
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
    ;;
  esac
done

usage(){
  echo "usage: $0 -d '/absolute/path/to/folder' -t 'testName.jmx'"
  echo ""
  echo "Flags"
  echo "-d\t absolute path to test plan dir"
  echo "-t\t test plan file name, relative to test plan dir"
  exit 1
}

if [[ ! -d "$TEST_PLAN_DIR" ]]; then
  echo "The test plan dir does not exist: $TEST_PLAN_DIR"
  usage
fi

if [[ ! -f "$TEST_PLAN_DIR/$TEST_PLAN_FILE" ]]; then
  echo "The test plan file does not exist: $TEST_PLAN_DIR/$TEST_PLAN_FILE"
  usage
fi

EXISTING_CONTAINERS=$(docker ps -a -q --filter ancestor=jmeter --format="{{.ID}}")
if [[ ! -z "$EXISTING_CONTAINERS" ]]; then
  echo "stop existing jmeter images"
  docker rm $(docker stop $EXISTING_CONTAINERS)
fi


cd $DIR
docker build -t jmeter .

#1
SUB_NET="172.18.0.0/16"
CLIENT_IP=172.18.0.23
declare -a SERVER_IPS=("172.18.0.101" "172.18.0.102" "172.18.0.103")
 
#2
timestamp=$(date +%Y%m%d_%H%M%S)
volume_path=${TEST_PLAN_DIR}
jmeter_path=/mnt/jmeter
TEST_NET=jmeter-dummy-net
 
#3
echo "Create testing network"
docker network create --subnet=$SUB_NET $TEST_NET

#4
echo "Create servers"
for IP_ADD in "${SERVER_IPS[@]}"
do
	docker run \
	-dit \
	--net $TEST_NET --ip $IP_ADD \
	-v "${volume_path}":${jmeter_path} \
	--rm \
	jmeter \
	-n -s \
	-Jclient.rmi.localport=7000 -Jserver.rmi.localport=60000 \
    -Jserver.rmi.ssl.disable=true \
	-j ${jmeter_path}/server/slave_${timestamp}_${IP_ADD:9:3}.log 
done

#5 
echo "Create client and execute test"
docker run \
  --net $TEST_NET --ip $CLIENT_IP \
  -v "${volume_path}":${jmeter_path} \
  --rm \
  jmeter \
  -n -X \
  -Jclient.rmi.localport=7000 \
  -Jserver.rmi.ssl.disable=true \
  -R $(echo $(printf ",%s" "${SERVER_IPS[@]}") | cut -c 2-) \
  -t ${jmeter_path}/${TEST_PLAN_FILE} \
  -l ${jmeter_path}/client/result_${timestamp}.jtl \
  -j ${jmeter_path}/client/jmeter_${timestamp}.log 
 
#6
docker network rm $TEST_NET
