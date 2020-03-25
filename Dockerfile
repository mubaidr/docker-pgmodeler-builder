FROM handcraftedbits/pgmodeler-builder-postgres:latest
LABEL Author="HandcraftedBits <opensource@handcraftedbits.com>"

# required by plugins
RUN apt-get update
RUN apt-get install -y qt5-default qttools5-dev qttools5-dev-tools libqt5designer5

COPY data /

WORKDIR /opt
ENTRYPOINT ["/bin/bash", "src/script/build.sh"]
