FROM nginx:1.10.0

RUN printf 'server { \nlisten 9090; \nlocation /health { \naccess_log off; \nreturn 200; \n} \n}' >> /etc/nginx/conf.d/default.conf

RUN > /etc/nginx/conf.d/artifactory.conf

COPY runNginx.sh /usr/local/bin/
COPY updateConf.sh /usr/local/bin/

# Install curl and jq to do some http requests
RUN \
  apt-get update && \
  apt-get install -y curl jq && \
  rm -rf /var/lib/apt/lists/* 
  
# Generate self-signed certificate
RUN mkdir -p /etc/pki/tls/private && mkdir -p /etc/pki/tls/certs
RUN openssl req -nodes -x509 -newkey rsa:4096 -keyout /etc/pki/tls/private/example.key -out /etc/pki/tls/certs/example.pem -days 356 \
    -subj "/C=US/ST=California/L=SantaClara/O=IT/CN=localhost"

CMD ["runNginx.sh"]
