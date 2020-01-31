FROM centos:7

# set locale
RUN yum reinstall -y glibc-common && yum clean all
RUN yum install -y vim kbd ibus-kkc vlgothic-* && yum clean all
RUN localedef -f UTF-8 -i ja_JP ja_JP.UTF-8
ENV LANG ja_JP.UTF-8
ENV LANGUAGE ja_JP:ja
ENV LC_ALL ja_JP.UTF-8
RUN unlink /etc/localtime
RUN ln -s /usr/share/zoneinfo/Japan /etc/localtime

WORKDIR /usr/local/src
# 必要パッケージインストール
RUN yum update -y && \
  yum install -y wget \
  vim \
  make \
  gcc-c++ \
  zlib-devel \
  lzo-devel.x86_64 \
  lzma-devel.x86_64 \
  xz-devel.x86_64 \
  lua-devel.x86_64

ENV KYOTO_CABINET_VERSION 1.2.76
ENV KYOTO_TYCOON_VERSION 0.9.56

# install KyotoCabinet
RUN wget http://fallabs.com/kyotocabinet/pkg/kyotocabinet-1.2.76.tar.gz && \
  tar zxfv kyotocabinet-1.2.76.tar.gz && \
  cd kyotocabinet-1.2.76 && \
  ./configure && make && make install

# install KyotoTycoon
RUN wget http://fallabs.com/kyototycoon/pkg/kyototycoon-0.9.56.tar.gz && \
  tar zxfv kyototycoon-0.9.56.tar.gz && \
  sed -i '24a\#include <unistd.h>' /usr/local/src/kyototycoon-0.9.56/ktdbext.h && \
  cd kyototycoon-0.9.56 && \
  ./configure && make && make install && \
  cp /usr/local/src/kyototycoon-0.9.56/lab/ktservctl /usr/local/sbin/ && \
  cp /usr/local/src/kyototycoon-0.9.56/lab/ktservctl /etc/rc.d/init.d/ktserver

# add memcache interchangeable
RUN sed -i '65a\cmd="$cmd -plsv /usr/local/src/kyototycoon-0.9.56/ktplugservmemc.so"' /etc/rc.d/init.d/ktserver
RUN sed -i '66a\cmd="$cmd -plex port=11401#opts=f#tout=10"' /etc/rc.d/init.d/ktserver

# add setting
RUN sed -i '$ a /usr/local/lib' /etc/ld.so.conf
RUN ldconfig

# clean
RUN yum clean all && \
  rm -rf /tmp/* \
  /var/tmp/* \
  kyotocabinet-1.2.76.tar.gz \
  kyototycoon-0.9.56.tar.gz

EXPOSE 1978 11401
CMD /etc/rc.d/init.d/ktserver start && tail -F /var/ktserver/log
