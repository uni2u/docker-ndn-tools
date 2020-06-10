FROM ubuntu:18.04
ARG VERSION_CXX=ndn-cxx-0.7.0
ARG VERSION_NFD=NFD-0.7.0
ARG VERSION_UTIL=ndn-tools-0.7

# install tools
RUN apt update \
    && apt install -y git build-essential

# install ndn-cxx and NFD dependencies
RUN apt install -y python libsqlite3-dev libboost-all-dev libssl-dev pkg-config libpcap-dev

# install ndn-cxx
RUN git clone https://github.com/named-data/ndn-cxx.git \
    && cd ndn-cxx \
    && git checkout $VERSION_CXX \
    && ./waf configure \
    && ./waf \
    && ./waf install \
    && cd .. \
    && rm -rf ndn-cxx \
    && ldconfig

# install NFD
RUN git clone --recursive https://github.com/named-data/NFD \
    && cd NFD \
    && git checkout $VERSION_NFD \
    && ./waf configure \
    && ./waf \
    && ./waf install \
    && cd .. \
    && rm -rf NFD

# install ndn-tools
RUN git clone --recursive https://github.com/named-data/ndn-tools.git \
    && cd ndn-tools \
    && git checkout $VERSION_UTIL \
    && ./waf configure \
    && ./waf \
    && ./waf install \
    $$ cd .. \
    $$ rm -rf ndn-tools

# initial configuration
RUN cp /usr/local/etc/ndn/nfd.conf.sample /usr/local/etc/ndn/nfd.conf \
    && ndnsec-keygen /`whoami` | ndnsec-install-cert - \
    && mkdir -p /usr/local/etc/ndn/keys \
    && ndnsec-cert-dump -i /`whoami` > default.ndncert \
    && mv default.ndncert /usr/local/etc/ndn/keys/default.ndncert

RUN mkdir /share \
    && mkdir /logs

# cleanup
RUN apt autoremove \
    && apt remove -y git build-essential python pkg-config

EXPOSE 6363/tcp
EXPOSE 6363/udp

ENV CONFIG=/usr/local/etc/ndn/nfd.conf
ENV LOG_FILE=/logs/nfd.log

CMD /usr/local/bin/nfd -c $CONFIG > $LOG_FILE 2>&1
