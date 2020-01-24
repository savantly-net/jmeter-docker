# inspired by https://github.com/vmarrazzo/docker-jmeter/
FROM openjdk:8-jre-alpine
LABEL maintainer="Jeremy Branham<Jeremy@Savantly.net>"

ARG JMETER_VERSION="5.2.1"

ENV JMETER_HOME /opt/apache-jmeter-${JMETER_VERSION}
ENV JMETER_BIN  ${JMETER_HOME}/bin
ENV MIRROR_HOST https://archive.apache.org/dist/jmeter
ENV JMETER_DOWNLOAD_URL ${MIRROR_HOST}/binaries/apache-jmeter-${JMETER_VERSION}.tgz

RUN    apk update \
	&& apk upgrade \
	&& apk add ca-certificates \
	&& update-ca-certificates \
	&& apk add --update tzdata curl unzip bash \
	&& rm -rf /var/cache/apk/* \
	&& mkdir -p /tmp/dependencies  \
	&& curl -L --silent ${JMETER_DOWNLOAD_URL} > /tmp/dependencies/apache-jmeter-${JMETER_VERSION}.tgz  \
	&& mkdir -p /opt  \
	&& tar -xzf /tmp/dependencies/apache-jmeter-${JMETER_VERSION}.tgz -C /opt  \
	&& rm -rf /tmp/dependencies \
	&& rm -rf /opt/apache-jmeter-${JMETER_VERSION}/docs/ \
	&& rm -rf /opt/apache-jmeter-${JMETER_VERSION}/printable_docs/ \
	&& rm -rf /opt/apache-jmeter-${JMETER_VERSION}/licenses/ \
	&& mkdir -p /opt/userclasspath

ENV PATH $PATH:$JMETER_BIN

COPY include/launch.sh /

WORKDIR ${JMETER_HOME}

ENTRYPOINT ["/launch.sh"]
