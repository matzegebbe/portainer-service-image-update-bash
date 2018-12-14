# portainer-service-image-update-bash

you need curl and jq installed
```
apt-get update && apt-get install -y curl jq
```

# Example for updating a plain docker swarm service to a new image
```bash
#!/bin/bash

USER=admin_user
PW=admin_pw
SERVER=my-server:9000
SERVICENAME=my-nginx
IMAGE=nginx:latest

echo "$SERVICENAME $IMAGE"

./portainer_update_service_image.sh $USER $PW $SERVER $SERVICENAME $IMAGE
```

# Example updateing a stack to the new image (working with ENV for IMAGE_NAME)
```bash
#!/bin/bash

# GET ENV
IMAGE="nginx:latest"
echo $IMAGE

./portainer_get_env.sh admin password servername:9000 stackname | jq "(.[] | select(.name == \"SERVICE_IMAGE\") | .value) |= \"$IMAGE\"" > env

cat env

# UPDATE STACK
./portainer_update_stack.sh admin password servername:9000 stackname dir/docker-compose.yml true env
```
