#!/bin/sh
set -e

#--------------------------------------------------------------------------------------------------
# Settings
#--------------------------------------------------------------------------------------------------

VLC_version="3.0.20"

VLC_artifact="6021"

#--------------------------------------------------------------------------------------------------
# Linux

VLC_versionA="5.6.1"
VLC_versionB="5"

libvlccore_versionA="9.0.1"
libvlccore_versionB="9"

#--------------------------------------------------------------------------------------------------
# Functions
#--------------------------------------------------------------------------------------------------

getSource()
{
    curl -L -o artifacts.json $1

    artifacts=$(cat artifacts.json)

    rm artifacts.json

    echo $artifacts | grep -Po '"id":.*?[^\\]}}'         | \
                      grep "$2\""                        | \
                      grep -Po '"downloadUrl":.*?[^\\]"' | \
                      grep -o '"[^"]*"$'                 | tr -d '"'
}

#--------------------------------------------------------------------------------------------------
# Syntax
#--------------------------------------------------------------------------------------------------

if [ $# != 2 ] || [ $1 != "linux" ] || [ $2 != "vlc" ]; then

    echo "Usage: snap <linux> <vlc>"

    exit 1
fi

#--------------------------------------------------------------------------------------------------
# Configuration
#--------------------------------------------------------------------------------------------------

external="$PWD/linux"

VLC="$external/VLC/$VLC_version"

VLC_url="https://dev.azure.com/bunjee/snap/_apis/build/builds/$VLC_artifact/artifacts"

#--------------------------------------------------------------------------------------------------
# Configuration
#--------------------------------------------------------------------------------------------------

if [ $2 = "vlc" ]; then

    artifact="VLC-linux64"

    echo ""
    echo "ARTIFACT $artifact"
    echo $VLC_url

    VLC_url=$(getSource $VLC_url $artifact)

    echo ""
    echo "DOWNLOADING VLC"
    echo $VLC_url

    curl --retry 3 -L -o VLC.zip $VLC_url

    mkdir -p "$VLC"

    unzip -q VLC.zip -d "$VLC"

    rm VLC.zip

    path="$VLC/$artifact"

    unzip -q "$path"/VLC.zip -d "$VLC"/snap

    rm -rf "$path"

    path="$VLC/snap/usr/lib"

    cp "$path"/libvlc.so.$VLC_versionA            "$VLC"/libvlc.so.$VLC_versionB
    cp "$path"/libvlccore.so.$libvlccore_versionA "$VLC"/libvlccore.so.$libvlccore_versionB

    # NOTE: libidn is required for linking against libvlccore.
    cp "$path"/../../lib/x86_64-linux-gnu/libidn.so* "$VLC"

    cp -r "$path"/vlc "$VLC"
fi
