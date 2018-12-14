#!/bin/bash

if [ $# -eq 0 ]
  then
    echo "USAGE: USERNAME PASSWORD HOST STACKNAME ENDPOINT_ID FILE_LOCATION USE_LOCAL_STACK_FILE ENV_FILE"
    echo "admin password server:9000 stack-name dir/docker-compose.yml true" 
    echo "admin password server:9000 stack-name dir/docker-compose.yml true localEnvironmentFile" 
    exit 0
fi

USERNAME=$1
PASSWORD=$2
HOST=$3
STACKNAME=$4
COMPOSE_FILE=$5
USE_LOCAL_STACKFILE=$6
ENV_FILE=$7

# GENERATE LOGIN TOKEN
LOGIN_TOKEN=$(curl -s -H "Content-Type: application/json" -d "{\"username\":\"$USERNAME\",\"password\":\"$PASSWORD\"}" -X POST $HOST/api/auth | jq -r .jwt)

# GET STACK ID OF $NAME
ID=$(curl -s -H "Authorization: Bearer $LOGIN_TOKEN" $HOST/api/stacks | jq -c ".[] | select( .Name==(\"$STACKNAME\"))" | jq -r .Id)

# GET THE ENV
if [ -z "$ENV_FILE" ]; then
   ENV=$(curl -s -H "Authorization: Bearer $LOGIN_TOKEN" $HOST/api/stacks/$ID | jq .Env)
else
   ENV=$(cat ${ENV_FILE})
fi

# GET THE STACK LIVE FILE

EXTERNAL_STACKFILE=$(curl -s -H "Authorization: Bearer $LOGIN_TOKEN" $HOST/api/stacks/$ID/file | jq .StackFileContent) 
ENDPOINT_ID=$(curl -s -H "Authorization: Bearer $LOGIN_TOKEN" $HOST/api/stacks/$ID | jq .EndpointId) 

# GET LOCAL STACKFILE AND FORMAT NEWLINE TO \n
echo "compose file: "$COMPOSE_FILE
LOCAL_STACKFILE="$(sed ':a;N;$!ba;s/\n/\\n/g' $COMPOSE_FILE)"

if [ "$USE_LOCAL_STACKFILE" = true ] ; then
    echo "local stack file used"
    UPDATE="{
      \"StackFileContent\": \"${LOCAL_STACKFILE}\",
      \"Env\": ${ENV},
      \"Prune\": true
    }"
else
    echo "remote stack file used"
    UPDATE="{
      \"StackFileContent\": ${EXTERNAL_STACKFILE},
      \"Env\": ${ENV},
      \"Prune\": true
    }"
fi

# UPDATE THE STACK > /dev/null beacuse the $ENV contains passwords
curl -s -H 'Content-Type: text/json; charset=utf-8' \
-H "Authorization: Bearer $LOGIN_TOKEN" -X PUT -d "${UPDATE}" \
$HOST/api/stacks/$ID?endpointId=$ENDPOINT_ID \
> /dev/null
