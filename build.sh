#!/bin/sh
set -e

#--------------------------------------------------------------------------------------------------
# Settings
#--------------------------------------------------------------------------------------------------

SSL_version="3.4.1"

#--------------------------------------------------------------------------------------------------
# Syntax
#--------------------------------------------------------------------------------------------------

if [ $# != 2 ] || [ $1 != "linux" ] || [ $2 != "OpenSSL" ]; then

    echo "Usage: build <linux> <OpenSSL>"

    exit 1
fi

#--------------------------------------------------------------------------------------------------
# Configuration
#--------------------------------------------------------------------------------------------------

external="$PWD/linux"

SSL="$external/OpenSSL/$SSL_version"

#--------------------------------------------------------------------------------------------------
# Build
#--------------------------------------------------------------------------------------------------

if [ $2 = "OpenSSL" ]; then

    echo "BUILDING OpenSSL $SSL_version"

    name="openssl-$SSL_version"

    archive="$name.tar.gz"

    curl -L -O "https://github.com/openssl/openssl/releases/download/$name/$archive"

    tar -xvzf $archive

    rm -rf $archive

    cd $name

    ./config --prefix=/usr/local/ssl --openssldir=/usr/local/ssl shared

    make -j$(nproc)

    mkdir -p "$SSL"

    sudo cp libssl.so.3    "$SSL"
    sudo cp libcrypto.so.3 "$SSL"

    cd ..

    rm -rf $name

fi
