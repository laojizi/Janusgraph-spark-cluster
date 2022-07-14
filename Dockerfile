FROM singularities/hadoop:2.8


MAINTAINER Singularities

# Version
ENV SPARK_VERSION=2.4.0
ARG JANUS_VERSION=0.5.2

# Set home
ENV SPARK_HOME=/usr/local/spark-$SPARK_VERSION
#ENV SPARK_TMP=/user/local/
ENV JANUS_VERSION=${JANUS_VERSION} \
    JANUS_HOME=/opt/janusgraph


# Install dependencies
RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install \
    -yq --no-install-recommends  \
      python python3 \
  && apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

COPY janusgraph.zip /opt/janusgraph/
COPY janusgraph.zip.asc /opt/janusgraph/

COPY docker-entrypoint.sh /usr/local/bin/
COPY load-initdb.sh /usr/local/bin/

RUN chmod 755 /usr/local/bin/docker-entrypoint.sh && \
    chmod 755 /usr/local/bin/load-initdb.sh

# Install Spark
RUN mkdir -p "${SPARK_HOME}" 
COPY spark-$SPARK_VERSION-bin-without-hadoop.tgz /usr/local/
#RUN export ARCHIVE=spark-$SPARK_VERSION-bin-without-hadoop.tgz \
#  && export DOWNLOAD_PATH=dist/spark/spark-$SPARK_VERSION/$ARCHIVE \
#  && curl -sSL https://archive.apache.org/$DOWNLOAD_PATH | \
RUN tar -xvf /usr/local/spark-$SPARK_VERSION-bin-without-hadoop.tgz -C $SPARK_HOME --strip-components 1 \
    && rm -rf /usr/local/spark-$SPARK_VERSION-bin-without-hadoop.tgz
COPY spark-env.sh $SPARK_HOME/conf/spark-env.sh
ENV PATH=$PATH:$SPARK_HOME/bin

# Ports
EXPOSE 6066 7077 8080 8081  8182  8030 8031 8032 8033 8040 8041 8042 8088

# Copy yarn mapred
COPY /confyarn/*.xml $HADOOP_CONF_DIR/
# Copy start script
COPY start-spark /opt/util/bin/start-spark

RUN chmod 777 /opt/util/bin/start-spark

# Fix environment for other users
RUN echo "export SPARK_HOME=$SPARK_HOME" >> /etc/bash.bashrc \
  && echo 'export PATH=$PATH:$SPARK_HOME/bin'>> /etc/bash.bashrc

# Add deprecated commands
RUN echo '#!/usr/bin/env bash' > /usr/bin/master \
  && echo 'start-spark master' >> /usr/bin/master \
  && chmod +x /usr/bin/master \
  && echo '#!/usr/bin/env bash' > /usr/bin/worker \
  && echo 'start-spark worker $1' >> /usr/bin/worker \
  && chmod +x /usr/bin/worker



WORKDIR /opt/janusgraph/

ENTRYPOINT [ "docker-entrypoint.sh" ]

LABEL org.opencontainers.image.title="JanusGraph Docker Image" \
      org.opencontainers.image.description="Official JanusGraph Docker image" \
      org.opencontainers.image.url="https://janusgraph.org/" \
      org.opencontainers.image.documentation="https://docs.janusgraph.org/v0.5/" \
      org.opencontainers.image.revision="${REVISION}" \
      org.opencontainers.image.source="https://github.com/JanusGraph/janusgraph-docker/" \
      org.opencontainers.image.vendor="JanusGraph" \
      org.opencontainers.image.version="${JANUS_VERSION}" \
      org.opencontainers.image.created="${CREATED}" \
      org.opencontainers.image.license="Apache-2.0"
