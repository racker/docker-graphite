FROM         ubuntu:12.04
MAINTAINER   Silas Sewell "silas@sewell.org"

RUN echo "deb http://archive.ubuntu.com/ubuntu precise main universe" > /etc/apt/sources.list
RUN apt-get update

RUN apt-get install -y python-software-properties
RUN apt-add-repository -y ppa:chris-lea/node.js
RUN apt-get update

RUN apt-get install -y \
  build-essential \
  git \
  libcairo2 \
  libcairo2-dev \
  memcached \
  nodejs \
  pkg-config \
  python-cairo \
  python-dev \
  python-pip \
  sqlite3 \
  supervisor

RUN pip install --upgrade pip

ADD ./supervisor/ /etc/supervisor/conf.d/
ADD ./scripts /tmp/scripts
RUN /bin/bash /tmp/scripts/setup.sh
RUN chown -R www-data:www-data /opt/graphite

EXPOSE 80 8125/udp 2003 2004 7002
CMD exec supervisord -n
