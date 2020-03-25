FROM handcraftedbits/pgmodeler-builder-postgres:latest
LABEL Author="HandcraftedBits <opensource@handcraftedbits.com>"

# required by plugins
RUN apt-get update
RUN apt-get install -y qt5-default qttools5-dev qttools5-dev-tools libqt5designer5
RUN cd /opt/mxe && \
  make MXE_TARGETS='x86_64-w64-mingw32.shared' qtbase qtimageformats qtsvg qttools && \
  rm -rf pkg .ccache

COPY data /

WORKDIR /opt
ENTRYPOINT ["/bin/bash", "src/script/build.sh"]
