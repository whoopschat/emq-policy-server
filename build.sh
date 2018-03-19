#!/bin/bash

BUILD_DIR=$(pwd)/build
EMQ_DIR=$BUILD_DIR/emq-relx
EMQ_REPO_GIT=https://github.com/emqtt/emq-relx

if [ -d $BUILD_DIR ]; then
else
mkdir $BUILD_DIR
fi

echo "Pull emq-relx from git"

if [ -d $EMQ_DIR ]; then
cd $EMQ_DIR
git pull
else
cd $BUILD_DIR
git clone $EMQ_REPO_GIT
fi

echo "Replacement Makefile configuration"

cd $EMQ_DIR

make


