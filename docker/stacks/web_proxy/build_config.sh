#!/bin/sh

CONFIG_FILE=config/nginx.conf.2

add_docker_hosts() {
  CONTAINERS=$(docker network inspect web_proxy -f '{{range $key, $value := .Containers}}{{$key}} {{end}}')
  HOST_INFO=$(docker container inspect -f "{{with .Config.Labels}}{{ index . \"external-hostname\"}},{{ index . \"external-port\"}},{{ index . \"com.docker.swarm.service.name\"}} {{end}}" $CONTAINERS)
  
  for HOST in $HOST_INFO; do
    set -f; IFS=","
    set -- $HOST
    set +f; unset IFS
    if [ ! -z $1 ]; then
      cat << EOF
    server {
        server_name $1.*;

        listen 443 ssl http2;
        ssl_certificate /run/secrets/web_proxy_certificate.crt;
        ssl_certificate_key /run/secrets/web_proxy_certificate.key;

        proxy_set_header X-Real-IP  \$remote_addr;
        proxy_set_header X-Forwarded-For \$remote_addr;
        proxy_set_header X-Forwarded-Proto https;
        proxy_set_header Host \$host;

        location / {
            proxy_pass  http://$3:$2;
        }
    }
EOF
    fi
  done
}

cat << EOF
user  nginx;
worker_processes  1;

error_log  /var/log/nginx/error.log warn;
pid        /var/run/nginx.pid;


events {
    worker_connections  1024;
}


http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                      '\$status \$body_bytes_sent "\$http_referer" '
                      '"\$http_user_agent" "\$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile        on;
    #tcp_nopush     on;

    keepalive_timeout  65;

    #gzip  on;

    server {
      server_name _;
      listen [::]:80 default_server;
      listen 80 default_server;
      return 301 https://\$host\$request_uri;
    }

    server {
      server_name _;

      listen 443 ssl http2;
      ssl_certificate /run/secrets/web_proxy_certificate.crt;
      ssl_certificate_key /run/secrets/web_proxy_certificate.key;

      location / {
        root /usr/share/nginx/html;
      }
    }
EOF

add_docker_hosts

cat << EOF
}
EOF

