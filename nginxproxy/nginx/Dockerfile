FROM nginx

COPY artifactory.conf /etc/nginx/conf.d/

RUN mkdir -p /etc/pki/tls/private && mkdir -p /etc/pki/tls/certs

RUN openssl req -nodes -x509 -newkey rsa:4096 -keyout /etc/pki/tls/private/example.key -out /etc/pki/tls/certs/example.pem -days 356 \
    -subj "/C=US/ST=California/L=SantaClara/O=IT/CN=localhost"

CMD ["nginx", "-g", "daemon off;"]
