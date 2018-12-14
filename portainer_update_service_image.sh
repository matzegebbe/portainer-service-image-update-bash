#!/bin/bash

if [ $# -eq 0 ]
  then
    echo "you need curl an jq installed"
    echo "USERNAME PASSWORD HOST SERVICE_NAME IMAGE_NAME"
    exit 0
fi

USERNAME=$1
PASSWORD=$2
HOST=$3
SERVICE_NAME=$4
IMAGE_NAME=$5

LOGIN_TOKEN=$(curl -s -H "Content-Type: application/json" -d "{\"username\":\"$USERNAME\",\"password\":\"$PASSWORD\"}" -X POST $HOST/api/auth | jq -r .jwt)

ENDPOINT_ID=$(curl -s -H "Authorization: Bearer $LOGIN_TOKEN" $HOST/api/endpoints | jq ."[].Id")

SERVICE=$(curl -s -H "Authorization: Bearer $LOGIN_TOKEN" $HOST/api/endpoints/${ENDPOINT_ID}/docker/services | jq -c ".[] | select( .Spec.Name==(\"$SERVICE_NAME\"))")

ID=$(echo $SERVICE | jq  -r .ID)
SPEC=$(echo $SERVICE | jq .Spec)
VERSION=$(echo $SERVICE | jq .Version.Index)
UPDATE=$(echo $SPEC | jq ".TaskTemplate.ContainerSpec.Image |= \"$IMAGE_NAME\" " | jq ".TaskTemplate.ForceUpdate |= 1 ")

echo $UPDATE

curl -s -H "Content-Type: text/json; charset=utf-8" \
-H "Authorization: Bearer $LOGIN_TOKEN" -X POST -d "${UPDATE}" \
"$HOST/api/endpoints/${ENDPOINT_ID}/docker/services/$ID/update?version=$VERSION"
