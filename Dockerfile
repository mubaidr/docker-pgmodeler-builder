FROM ubuntu:latest
LABEL author="Muhammad Ubaid Raza <mubaidr@gmail.com>"
LABEL maintainer="Muhammad Ubaid Raza <mubaidr@gmail.com>"
LABEL version="1.0"
LABEL description="A [Docker](https://www.docker.com) container that allows you to build [pgModeler](https://pgmodeler.io/) with one simple command."

RUN apt-get update && \
  apt-get install -y \
  build-essential \
  qt5-default \
  qttools5-dev \
  qttools5-dev-tools

RUN apt-get install -y \
  autoconf \
  automake \
  autopoint \
  bash \
  bison \
  bzip2 \
  flex \
  g++ \
  g++-multilib \
  gettext \
  git \
  gperf \
  intltool \
  libc6-dev-i386 \
  libgdk-pixbuf2.0-dev \
  libltdl-dev \
  libssl-dev \
  libtool-bin \
  libxml-parser-perl \
  lzip \
  make \
  openssl \
  p7zip-full \
  patch \
  perl \
  pkg-config \
  python \
  ruby \
  sed \
  unzip \
  wget \
  xz-utils

RUN cd /opt && \
  git clone https://github.com/mxe/mxe.git && \
  cd mxe && \
  make MXE_TARGETS='x86_64-w64-mingw32.shared x86_64-w64-mingw32.static' cc zlib

RUN cd /opt/mxe && \
  make MXE_TARGETS='x86_64-w64-mingw32.shared' cc dbus fontconfig freetds freetype harfbuzz jpeg libmysqlclient \
  libpng libxml2 openssl pcre2 postgresql sqlite

RUN cd /opt/mxe && \
  make MXE_TARGETS='x86_64-w64-mingw32.shared' qtbase qtimageformats qtsvg && \
  rm -rf pkg .ccache

RUN mkdir -p /opt/src && \
  cd /opt/src && \
  git clone https://github.com/digitalist/pydeployqt.git

ARG VERSION_POSTGRESQL=REL_12_0

RUN cd /opt/src && \
  git clone https://github.com/postgres/postgres.git && \
  cd postgres && \
  git checkout -b ${VERSION_POSTGRESQL} ${VERSION_POSTGRESQL} && \
  cd /opt/src/postgres && \
  PATH=/opt/mxe/usr/bin:${PATH} ./configure --host=x86_64-w64-mingw32.static --prefix=/opt/postgresql && \
  PATH=/opt/mxe/usr/bin:${PATH} make && \
  PATH=/opt/mxe/usr/bin:${PATH} make install && \
  cd /opt/src && \
  rm -rf postgres

COPY data /
WORKDIR /opt
ENTRYPOINT ["/bin/bash", "src/script/build.sh"]
