#!/bin/bash

if [[ $TRAVIS_OS_NAME = 'osx' ]]; then
  :
elif [[ $TRAVIS_OS_NAME = 'linux' ]]; then
  RELEASE_DOT=$(lsb_release -sr)
  RELEASE_NUM=${RELEASE_DOT//[-._]/}
  
  if [[ $RELEASE_DOT == "20.04" ]]; then
    sudo apt-get update
    sudo apt-get -y install \
            binutils \
            git \
            gnupg2 \
            libc6-dev \
            libcurl4 \
            libedit2 \
            libgcc-9-dev \
            libpython2.7 \
            libsqlite3-0 \
            libstdc++-9-dev \
            libxml2 \
            libz3-dev \
            pkg-config \
            tzdata \
            zlib1g-dev
    fi
    
  if [[ $TRAVIS_CPU_ARCH == "arm64" ]]; then
    curl -s https://packagecloud.io/install/repositories/swift-arm/release/script.deb.sh | sudo bash
    sudo apt-get install swift-lang
  else 
    wget https://swift.org/builds/swift-${SWIFT_VER}-release/ubuntu${RELEASE_NUM}/swift-${SWIFT_VER}-RELEASE/swift-${SWIFT_VER}-RELEASE-ubuntu${RELEASE_DOT}.tar.gz
    tar xzf swift-${SWIFT_VER}-RELEASE-ubuntu${RELEASE_DOT}.tar.gz
  fi 
fi
