#!/bin/sh
set -e

#--------------------------------------------------------------------------------------------------
# Settings
#--------------------------------------------------------------------------------------------------

VLC_artifact="8336"

VLC3_version="3.0.21"
VLC4_version="4.0.0"

#--------------------------------------------------------------------------------------------------
# Linux

VLC3_versionA="5.6.1"
VLC3_versionB="5"

libvlccore3_versionA="9.0.1"
libvlccore3_versionB="9"

VLC4_versionA="12.0.0"
VLC4_versionB="12"

libvlccore4_versionA="9.0.0"
libvlccore4_versionB="9"

#--------------------------------------------------------------------------------------------------
# Functions
#--------------------------------------------------------------------------------------------------

extract()
{
    echo "EXTRACTING $1"

    path="$VLC/snap/$1/usr/lib"

    output="$VLC/$1"

    mkdir -p "$output"

    cp "$path"/libvlc.so.$2     "$output"/libvlc.so.$3
    cp "$path"/libvlccore.so.$4 "$output"/libvlccore.so.$5

    # NOTE: libidn is required for linking against libvlccore.
    cp "$path"/../../lib/x86_64-linux-gnu/libidn.so* "$output"

    cp -r "$path"/vlc "$output"
}

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

VLC="$external/VLC"

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

    extract $VLC3_version $VLC3_versionA $VLC3_versionB $libvlccore3_versionA $libvlccore3_versionB
    extract $VLC4_version $VLC4_versionA $VLC4_versionB $libvlccore4_versionA $libvlccore4_versionB
fi
