FROM jfrog-docker-reg2.bintray.io/jfrog/artifactory-pro
MAINTAINER jayd@jfrog.com

COPY run.sh /run.sh

# set up mysql in artifactory
RUN curl https://bintray.com/artifact/download/bintray/jcenter/mysql/mysql-connector-java/5.1.38/mysql-connector-java-5.1.38.jar -O -L
RUN mv -f mysql-connector* ~artifactory/tomcat/lib
RUN cp ~artifactory/misc/db/mysql.properties ~artifactory/etc/storage.properties
RUN sed -i 's/localhost/mysql/' ~artifactory/etc/storage.properties

RUN mkdir -p ~artifactory/etcback
RUN cp ~artifactory/etc/* ~artifactory/etcback

COPY server.xml /opt/jfrog/artifactory/tomcat/conf/server.xml
COPY nginx.ftl /var/opt/jfrog/artifactory/etc/nginx.ftl

EXPOSE 8081 10042

CMD /run.sh
