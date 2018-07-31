#!/bin/bash
CURRENT_DIR=$(pwd)
VER = 2.3.11

BIN_DIR=${CURRENT_DIR}/bin
BUILD_DIR=${CURRENT_DIR}/build
DATA_DIR=${CURRENT_DIR}/data
EMQ_DIR=${BUILD_DIR}/emq-relx
PROJECT_DEP_DIR=${EMQ_DIR}/deps/emq_policy_server

EMQ_REL_X_REPO_GIT=https://github.com/emqtt/emq-relx
EMQ_REL_X_REPO_GIT_BRANCH=v${VER}

EMQ_RELEASE_DIR=${EMQ_DIR}/_rel
EMQ_RELEASE_TARGET=${BIN_DIR}/release_emq_${VER}.zip

if [ ! -d ${BUILD_DIR} ]; then
mkdir ${BUILD_DIR}
fi

if [ -d ${EMQ_RELEASE_DIR} ]; then
rm -rf ${EMQ_RELEASE_DIR}
fi

if [ -d ${EMQ_RELEASE_TARGET} ]; then
rm -rf ${EMQ_RELEASE_TARGET}
fi

if [ -d ${PROJECT_DEP_DIR} ]; then
rm -rf ${PROJECT_DEP_DIR}
fi

echo -e
echo "======================================="
echo "|       Pull emq-relx from git        |"
echo "======================================="
echo -e

if [ -d ${EMQ_DIR} ]; then
cd ${EMQ_DIR}
git pull
else
cd ${BUILD_DIR}
git clone -b ${EMQ_REL_X_REPO_GIT_BRANCH} ${EMQ_REL_X_REPO_GIT}
fi

echo -e
echo "======================================="
echo "|               Building              |"
echo "======================================="
echo -e

cd ${CURRENT_DIR}
cp ${DATA_DIR}/Makefile ${EMQ_DIR}/Makefile
cp ${DATA_DIR}/relx.config ${EMQ_DIR}/relx.config
cd ${EMQ_DIR}
rm -rf ${EMQ_DIR}/deps/emp_policy_server
make VER=${VER}

if [ ! -d ${EMQ_RELEASE_DIR} ]; then
echo -e
echo "Failure"
else
echo -e
echo "======================================="
echo "|            Compression              |"
echo "======================================="
echo -e
cd ${EMQ_RELEASE_DIR}
zip -r -q -o ${EMQ_RELEASE_TARGET}  ./
echo "Success , release path : ${EMQ_RELEASE_TARGET}"
fi
echo -e
