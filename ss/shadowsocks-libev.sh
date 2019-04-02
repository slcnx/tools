#!/bin/bash
#
# Description: only CentOS 7
yum -y install epel-release
yum -y install git
yum -y install openssl-devel gettext gcc autoconf libtool automake make asciidoc xmlto c-ares-devel libev-devel autoconf automake libtool gettext pkg-config libmbedtls libsodium libpcre3 libev libc-ares asciidoc xmlto gettext gcc autoconf libtool automake make asciidoc xmlto c-ares-devel libev-devel pcre-devel

git clone https://github.com/shadowsocks/shadowsocks-libev.git
cd shadowsocks-libev
git submodule update --init --recursive

# Installation of Libsodium
export LIBSODIUM_VER=1.0.13
wget https://download.libsodium.org/libsodium/releases/libsodium-$LIBSODIUM_VER.tar.gz
tar xvf libsodium-$LIBSODIUM_VER.tar.gz
pushd libsodium-$LIBSODIUM_VER
./configure --prefix=/usr && make
sudo make install
popd
sudo ldconfig

# Installation of MbedTLS
export MBEDTLS_VER=2.6.0
wget https://tls.mbed.org/download/mbedtls-$MBEDTLS_VER-gpl.tgz
tar xvf mbedtls-$MBEDTLS_VER-gpl.tgz
pushd mbedtls-$MBEDTLS_VER
make SHARED=1 CFLAGS=-fPIC
make DESTDIR=/usr install
popd
ldconfig

# Start building
./autogen.sh && ./configure && make
make install

useradd shadowsocks

cd ~
rm -fr shadowsocks-libev 

