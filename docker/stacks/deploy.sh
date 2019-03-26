#!/bin/sh

deploy_stack()
{
  STACK_NAME=$1
  docker stack deploy -c $STACK_NAME/docker-compose.yml $STACK_NAME
}

docker network create --attachable --internal --scope swarm --driver overlay web_proxy

deploy_stack iot
deploy_stack network

# Create certs somehow...
# docker secret create web_proxy_certificate.key $(tmp cert file)
# docker secret create web_proxy_certificate.crt $(tmp cert file)

deploy_stack web_proxy

echo "Remove config"
docker service update --config-rm="web_proxy_nginx.conf" web_proxy_www_proxy
echo "Delete config"
docker config rm web_proxy_nginx.conf
echo "Rebuild config"
./web_proxy/build_config.sh | docker config create web_proxy_nginx.conf -
echo "Add config"
docker service update --config-add src=web_proxy_nginx.conf,target="/etc/nginx/nginx.conf" web_proxy_www_proxy
