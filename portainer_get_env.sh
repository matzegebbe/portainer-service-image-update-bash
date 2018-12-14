#!/bin/bash

if [ $# -eq 0 ]
  then
    echo "USAGE: USERNAME PASSWORD HOST STACKNAME"
    echo "admin admin_pw server:9000 stackname" 
    exit 0
fi

USERNAME=$1
PASSWORD=$2
HOST=$3
STACKNAME=$4

# GENERATE LOGIN TOKEN
LOGIN_TOKEN=$(curl -s -H "Content-Type: application/json" -d "{\"username\":\"$USERNAME\",\"password\":\"$PASSWORD\"}" -X POST $HOST/api/auth | jq -r .jwt)

# GET STACK ID OF $NAME
ID=$(curl -s -H "Authorization: Bearer $LOGIN_TOKEN" $HOST/api/stacks | jq -c ".[] | select( .Name | contains(\"$STACKNAME\"))" | jq -r .Id)

# GET THE ENV
if [ -z "$ENV_FILE" ]; then
   ENV=$(curl -s -H "Authorization: Bearer $LOGIN_TOKEN" $HOST/api/stacks/$ID | jq .Env)
else
   ENV=$(cat ${ENV_FILE})
fi

echo $ENV
