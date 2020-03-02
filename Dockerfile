FROM debian:jessie
MAINTAINER Vagabondan <strannix.vagabondan@gmail.com>

RUN groupadd -r node && useradd -m -g node node

# Gosu
ENV GOSU_VERSION 1.11

# MongoDB
ENV MONGO_VERSION 3.4.10
ENV MONGO_MAJOR 3.4
ENV MONGO_PACKAGE mongodb-org

# PhantomJS
ENV PHANTOM_VERSION 2.1.1

# build directories
ENV APP_SOURCE_DIR /opt/meteor/src
ENV APP_BUNDLE_DIR /opt/meteor/dist
ENV BUILD_SCRIPTS_DIR /opt/build_scripts

# Add entrypoint and build scripts
COPY scripts $BUILD_SCRIPTS_DIR
RUN chmod -R 750 $BUILD_SCRIPTS_DIR

# Define all --build-arg options
ARG METEOR_VERSION
ENV METEOR_VERSION ${METEOR_VERSION:-1.9.2}

ARG APT_GET_INSTALL
ENV APT_GET_INSTALL $APT_GET_INSTALL

ARG NODE_VERSION
ENV NODE_VERSION ${NODE_VERSION:-12.14.1}

ARG NPM_TOKEN
ENV NPM_TOKEN $NPM_TOKEN

ARG INSTALL_MONGO
ENV INSTALL_MONGO $INSTALL_MONGO

ARG INSTALL_PHANTOMJS
ENV INSTALL_PHANTOMJS $INSTALL_PHANTOMJS

ARG INSTALL_GRAPHICSMAGICK
ENV INSTALL_GRAPHICSMAGICK $INSTALL_GRAPHICSMAGICK

# Node flags for the Meteor build tool
ARG TOOL_NODE_FLAGS
ENV TOOL_NODE_FLAGS $TOOL_NODE_FLAGS

# optionally custom apt dependencies at app build time
RUN if [ "$APT_GET_INSTALL" ]; then apt-get update && apt-get install -y $APT_GET_INSTALL; fi

COPY launchpad.conf $APP_SOURCE_DIR/

# install all common dependencies
RUN cd $APP_SOURCE_DIR && \
  $BUILD_SCRIPTS_DIR/install-deps.sh && \
  $BUILD_SCRIPTS_DIR/install-node.sh

# install other deps
RUN cd $APP_SOURCE_DIR && \
  $BUILD_SCRIPTS_DIR/install-phantom.sh && \
  $BUILD_SCRIPTS_DIR/install-graphicsmagick.sh && \
  $BUILD_SCRIPTS_DIR/install-mongo.sh && \
  $BUILD_SCRIPTS_DIR/install-meteor.sh

# copy the app to the container
ONBUILD COPY . $APP_SOURCE_DIR

# build the app
ONBUILD RUN  cd $APP_SOURCE_DIR && \
  $BUILD_SCRIPTS_DIR/build-meteor.sh && \
  $BUILD_SCRIPTS_DIR/post-build-cleanup.sh

# Default values for Meteor environment variables
ENV ROOT_URL http://localhost
ENV MONGO_URL mongodb://127.0.0.1:27017/meteor
ENV PORT 3000

EXPOSE 3000

WORKDIR $APP_BUNDLE_DIR/bundle

# start the app
ENTRYPOINT ["./entrypoint.sh"]
CMD ["node", "main.js"]
