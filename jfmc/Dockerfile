FROM java
MAINTAINER Alexis Tual <alexist@jfrog.com>

ENV MC_VERSION 1.0

RUN apt-get update;\
    apt-get install unzip curl -y;\
    curl -L -O "http://jfrog.bintray.com/jfrog-mission-control/jfrog-mission-control-$MC_VERSION.zip";\
    unzip jfrog-mission-control-$MC_VERSION.zip;\
    mv mission-control-$MC_VERSION mission-control;\
    rm jfrog-mission-control-$MC_VERSION.zip

VOLUME /mission-control/data
VOLUME /mission-control/etc

EXPOSE 8080

CMD /mission-control/bin/mission-control.sh


