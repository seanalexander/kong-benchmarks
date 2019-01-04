FROM debian:jessie
LABEL maintainer="Montana Flynn <montana@montanaflynn.me>"

# Necessities
RUN echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu xenial main" | tee /etc/apt/sources.list.d/webupd8team-java.list
RUN echo "deb-src http://ppa.launchpad.net/webupd8team/java/ubuntu xenial main" | tee -a /etc/apt/sources.list.d/webupd8team-java.list
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys EEA14886
RUN apt-get update && apt-get install -y sudo curl siege wget jq ca-certificates

# Optimizations
ADD config/server/sysctl.conf /etc/sysctl.conf
ADD config/server/limits.conf /etc/security/limits.conf

# Java 8
RUN echo debconf shared/accepted-oracle-license-v1-1 select true | debconf-set-selections
RUN echo debconf shared/accepted-oracle-license-v1-1 seen true | debconf-set-selections

RUN apt-get install -y openjdk-8-jre-headless

# Cassandra
RUN mkdir -p /usr/lib/cassandra/
RUN curl --cacert /etc/ssl/certs/GeoTrust_Global_CA.pem \
    --silent https://archive.apache.org/dist/cassandra/2.1.5/apache-cassandra-2.1.5-bin.tar.gz \
    | tar xz --strip-components=1 -C /usr/lib/cassandra/
ENV CASS_HOME /usr/lib/cassandra
ENV PATH $CASS_HOME/bin:$PATH

# Kong
RUN apt-get update && apt-get install -y lua5.1 openssl dnsmasq netcat libpcre3
RUN curl --cacert /etc/ssl/certs/GeoTrust_Global_CA.pem --silent --location \
    -O https://github.com/Mashape/kong/releases/download/0.3.0/kong-0.3.0.wheezy_all.deb
RUN sudo dpkg -i kong-0.3.0.*.deb

# Cleanup
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Benchark
ENV LOG_DIR /usr/local/kong/logs
RUN mkdir -p $LOG_DIR
RUN touch $LOG_DIR/siege.log
ADD config/server/.siegerc /root/.siegerc
ADD benchmark.sh /usr/local/bin/benchmark

CMD ["benchmark"]