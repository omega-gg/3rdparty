#!/bin/bash
set -e

#--------------------------------------------------------------------------------------------------
# Settings
#--------------------------------------------------------------------------------------------------

source="http://omega.gg/get/Sky/3rdparty"

#--------------------------------------------------------------------------------------------------

Qt5_version="5.12.3"

MinGW_versionA="7.3.0"
MinGW_versionB="730"

SSL_version="1.0.2p"

VLC_version="3.0.6"
VLC_version="3.0.6"

#--------------------------------------------------------------------------------------------------

thirdparty_artifact="657"
libtorrent_artifact="654"

#--------------------------------------------------------------------------------------------------
# Android

NDK_version="21"

#--------------------------------------------------------------------------------------------------
# Functions
#--------------------------------------------------------------------------------------------------

function getSource
{
    curl -L -o artifacts.json $1

    artifacts=$(cat artifacts.json)

    rm artifacts.json

    echo $artifacts | $grep -Po '"id":.*?[^\\]}}'         | \
                      $grep $2                            | \
                      $grep -Po '"downloadUrl":.*?[^\\]"' | \
                      $grep -o '"[^"]*"$'                 | tr -d '"'
}

#--------------------------------------------------------------------------------------------------
# Syntax
#--------------------------------------------------------------------------------------------------

if [ $# != 1 -a $# != 2 ] \
   || \
   [ $1 != "win32"     -a \
     $1 != "win64"     -a \
     $1 != "macOS"     -a \
     $1 != "linux"     -a \
     $1 != "android32" -a \
     $1 != "android64" ] || [ $# = 2 -a "$2" != "build" -a "$2" != "clean" ]; then

    echo \
    "Usage: generate <win32 | win64 | macOS | linux | android32 | android64> [build | clean]"

    exit 1
fi

#--------------------------------------------------------------------------------------------------
# Configuration
#--------------------------------------------------------------------------------------------------

if [ $1 = "win32" -o $1 = "win64" ]; then

    os="windows"

elif [ $1 = "android32" -o $1 = "android64" ]; then

    os="android"
else
    os="other"
fi

#--------------------------------------------------------------------------------------------------
# NOTE: We use ggrep on macOS because it supports Perl regexp.

if [[ "$OSTYPE" == "darwin"* ]]; then

    brew install grep

    grep="ggrep"
else
    grep="grep"
fi

source="$source/$1"

external="$1"

install_qt="dist/install-qt.sh"

Qt5="$external/Qt/$Qt5_version"

MinGW="$external/MinGW/$MinGW_versionA"

SSL="$external/OpenSSL"

VLC="$external/VLC/$VLC_version"

NDK="$external/NDK/$NDK_version"

#--------------------------------------------------------------------------------------------------

thirdparty_url="https://dev.azure.com/bunjee/3rdparty/_apis/build/builds/$thirdparty_artifact/artifacts"

libtorrent_url="https://dev.azure.com/bunjee/libtorrent/_apis/build/builds/$libtorrent_artifact/artifacts"

if [ $os = "windows" ]; then

    if [ $1 = "win32" ]; then

        MinGW_url="http://ftp1.nluug.nl/languages/qt/online/qtsdkrepository/windows_x86/desktop/tools_mingw/qt.tools.win32_mingw730/7.3.0-1-201903151311i686-7.3.0-release-posix-dwarf-rt_v5-rev0.7z"

        SSL_url="https://indy.fulgan.com/SSL/Archive/openssl-$SSL_version-i386-win32.zip"
    else
        MinGW_url="http://ftp1.nluug.nl/languages/qt/online/qtsdkrepository/windows_x86/desktop/tools_mingw/qt.tools.win64_mingw730/7.3.0-1x86_64-7.3.0-release-posix-seh-rt_v5-rev0.7z"

        SSL_url="https://indy.fulgan.com/SSL/Archive/openssl-$SSL_version-x64_86-win64.zip"
    fi

    VLC_url="http://download.videolan.org/pub/videolan/vlc/$VLC_version/$1/vlc-$VLC_version-$1.7z"

elif [ $1 = "macOS" ]; then

    VLC_url="http://download.videolan.org/pub/videolan/vlc/$VLC_version/macosx/vlc-$VLC_version.dmg"

elif [ $os = "android" ]; then

    NDK_url="https://dl.google.com/android/repository/android-ndk-r$NDK_version-linux-x86_64.zip"
fi

#--------------------------------------------------------------------------------------------------
# Clean
#--------------------------------------------------------------------------------------------------

echo "CLEANING"

rm -rf $1
mkdir  $1
touch  $1/.gitignore

if [ "$2" = "clean" ]; then

    exit 0
fi

echo ""

#--------------------------------------------------------------------------------------------------
# Linux
#--------------------------------------------------------------------------------------------------

if [ $1 = "linux" ]; then

    sh install.sh $1

    exit 0
fi

#--------------------------------------------------------------------------------------------------
# Artifact
#--------------------------------------------------------------------------------------------------

if [ "$2" != "build" -a "$2" != "clean" ]; then

    echo "ARTIFACT 3rdparty-$1"
    echo $thirdparty_url

    thirdparty_url=$(getSource $thirdparty_url 3rdparty-$1)

    echo ""
    echo "DOWNLOADING 3rdparty-$1"
    echo $thirdparty_url

    curl -L -o 3rdparty.zip $thirdparty_url

    echo ""
    echo "EXTRACTING 3rdparty-$1"

    unzip -q 3rdparty.zip

    rm 3rdparty.zip

    unzip -qo 3rdparty-$1/3rdparty.zip

    rm -rf 3rdparty-$1

    exit 0
fi

#--------------------------------------------------------------------------------------------------
# Install
#--------------------------------------------------------------------------------------------------
# NOTE: We need 7z on macOS and Linux.

if [[ "$OSTYPE" == "darwin"* ]]; then

    brew install p7zip

    echo ""

elif [[ "$OSTYPE" == "linux"* ]]; then

    sudo apt-get install -y p7zip-full

    echo ""
fi

#--------------------------------------------------------------------------------------------------
# 3rdparty
#--------------------------------------------------------------------------------------------------

if [ $1 = "win32" ]; then

    echo "DOWNLOADING 3rdparty"
    echo "$source"
    echo ""

    curl --retry 3 -L -o 3rdparty.zip "$source"

    unzip -q 3rdparty.zip

    rm 3rdparty.zip

    mv 3rdparty/$1/* .

    rm -rf 3rdparty

    echo ""
fi

#--------------------------------------------------------------------------------------------------
# Qt5
#--------------------------------------------------------------------------------------------------

echo "DOWNLOADING Qt5"

if [ $os = "windows" ]; then

    bash $install_qt --directory Qt --version $Qt5_version --host windows_x86 \
                     --toolchain $1_mingw73 qtbase qtdeclarative qtxmlpatterns qtsvg qtwinextras

    if [ $1 = "win32" ]; then

        Qt="Qt/$Qt5_version/mingw73_32"
    else
        Qt="Qt/$Qt5_version/mingw73_64"
    fi

elif [ $1 = "macOS" ]; then

    bash $install_qt --directory Qt --version $Qt5_version --host mac_x64 \
                     --toolchain clang_64 qtbase qtdeclarative qtxmlpatterns qtsvg

    Qt="Qt/$Qt5_version/clang_64"

elif [ $1 = "android32" ]; then

    bash $install_qt --directory Qt --version $Qt5_version --host linux_x64 --target android \
                     --toolchain android_armv7 qtbase qtdeclarative qtxmlpatterns qtsvg

    Qt="Qt/$Qt5_version/android_armv7"

elif [ $1 = "android64" ]; then

    bash $install_qt --directory Qt --version $Qt5_version --host linux_x64 --target android \
                     --toolchain android_arm64_v8a qtbase qtdeclarative qtxmlpatterns qtsvg

    Qt="Qt/$Qt5_version/android_arm64_v8a"
fi

#--------------------------------------------------------------------------------------------------

echo "COPYING Qt5"

mkdir -p "$Qt5"/bin
mkdir -p "$Qt5"/plugins/imageformats
mkdir -p "$Qt5"/plugins/platforms
mkdir -p "$Qt5"/qml

cp "$Qt"/bin/qt.conf "$Qt5"/bin

cp -r "$Qt"/lib "$Qt5"

cp -r "$Qt"/include "$Qt5"

cp -r "$Qt"/qml/QtQuick.2 "$Qt5"/qml

cp -r "$Qt"/mkspecs "$Qt5"

if [ $os = "windows" ]; then

    cp "$Qt"/bin/qmake.exe       "$Qt5"/bin
    cp "$Qt"/bin/moc.exe         "$Qt5"/bin
    cp "$Qt"/bin/rcc.exe         "$Qt5"/bin
    cp "$Qt"/bin/qmlcachegen.exe "$Qt5"/bin

    cp "$Qt"/bin/lib*.dll "$Qt5"/bin

    cp "$Qt"/bin/Qt*.dll "$Qt5"/bin

    cp "$Qt"/plugins/imageformats/q*.dll "$Qt5"/plugins/imageformats
    cp "$Qt"/plugins/platforms/q*.dll    "$Qt5"/plugins/platforms

    #----------------------------------------------------------------------------------------------

    rm "$Qt5"/bin/*d.*

    rm "$Qt5"/plugins/imageformats/*d.*
    rm "$Qt5"/plugins/platforms/*d.*

    rm "$Qt5"/lib/*d.*

elif [ $1 = "macOS" ]; then

    cp "$Qt"/bin/qmake       "$Qt5"/bin
    cp "$Qt"/bin/moc         "$Qt5"/bin
    cp "$Qt"/bin/rcc         "$Qt5"/bin
    cp "$Qt"/bin/qmlcachegen "$Qt5"/bin

    cp "$Qt"/plugins/imageformats/libq*.dylib "$Qt5"/plugins/imageformats
    cp "$Qt"/plugins/platforms/libq*.dylib    "$Qt5"/plugins/platforms

    #----------------------------------------------------------------------------------------------

    rm "$Qt5"/plugins/imageformats/*debug*
    rm "$Qt5"/plugins/platforms/*debug*

    find "$Qt5"/lib -name "*_debug*" -delete

elif [ $os = "android" ]; then

    cp "$Qt"/bin/qmake       "$Qt5"/bin
    cp "$Qt"/bin/moc         "$Qt5"/bin
    cp "$Qt"/bin/rcc         "$Qt5"/bin
    cp "$Qt"/bin/qmlcachegen "$Qt5"/bin

    cp "$Qt"/plugins/imageformats/libq*.so "$Qt5"/plugins/imageformats

    cp -r "$Qt"/plugins/platforms/android "$Qt5"/plugins/platforms
fi

rm -rf Qt

#--------------------------------------------------------------------------------------------------
# MinGW
#--------------------------------------------------------------------------------------------------

if [ $os = "windows" ]; then

    echo ""
    echo "DOWNLOADING MinGW"
    echo $MinGW_url

    curl -L -o MinGW.7z $MinGW_url

    mkdir -p "$MinGW"

    7z x MinGW.7z -o"$MinGW"

    rm MinGW.7z

    if [ $1 = "win32" ]; then

        path="$MinGW"/Tools/mingw"$MinGW_versionB"_32
    else
        path="$MinGW"/Tools/mingw"$MinGW_versionB"_64
    fi

    mv "$path"/* "$MinGW"

    rm -rf "$MinGW/Tools"
fi

#--------------------------------------------------------------------------------------------------
# SSL
#--------------------------------------------------------------------------------------------------

if [ $os = "windows" ]; then

    echo ""
    echo "DOWNLOADING SSL"
    echo $SSL_url

    curl -L -o ssl.zip $SSL_url

    mkdir -p "$SSL"

    7z x ssl.zip -o"$SSL"

    rm ssl.zip
fi

#--------------------------------------------------------------------------------------------------
# VLC
#--------------------------------------------------------------------------------------------------

if [ $os = "windows" ]; then

    echo ""
    echo "DOWNLOADING VLC"
    echo $VLC_url

    curl -L -o VLC.7z $VLC_url

    mkdir -p "$VLC"

    7z x VLC.7z -o"$VLC"

    rm VLC.7z

    path="$VLC/vlc-$VLC_version"

    mv "$path"/* "$VLC"

    rm -rf "$path"

elif [ $1 = "macOS" ]; then

    echo ""
    echo "DOWNLOADING VLC"
    echo $VLC_url

    curl -L -o VLC.dmg $VLC_url

    mkdir -p "$VLC"

    if [[ "$OSTYPE" == "darwin"* ]]; then

        hdiutil attach VLC.dmg

        cp -r "/Volumes/VLC media player/VLC.app/Contents/MacOS/"* "$VLC"

        # TODO: Detach the mounted drive.

        rm VLC.dmg
    else
        #------------------------------------------------------------------------------------------
        # NOTE: We get a header error when extracting the archive with 7z.

        set +e

        7z x VLC.dmg -o"$VLC"

        set -e

        #------------------------------------------------------------------------------------------

        rm VLC.dmg

        path="$VLC/VLC media player"

        mv "$path"/VLC.app/Contents/MacOS/* "$VLC"

        rm -rf "$path"
    fi
fi

#--------------------------------------------------------------------------------------------------
# libtorrent
#--------------------------------------------------------------------------------------------------

echo "ARTIFACT libtorrent-$1"
echo $thirdparty_url

libtorrent_url=$(getSource $libtorrent_url libtorrent-$1)

echo ""
echo "DOWNLOADING libtorrent"
echo $libtorrent_url

curl -L -o libtorrent.zip $libtorrent_url

unzip -q libtorrent.zip

rm libtorrent.zip

unzip -q libtorrent-$1/libtorrent.zip -d "$external"

rm -rf libtorrent-$1

#--------------------------------------------------------------------------------------------------
# NDK
#--------------------------------------------------------------------------------------------------

if [ $os = "android" ]; then

    echo ""
    echo "DOWNLOADING NDK"
    echo $NDK_url

    curl -L -o NDK.zip $NDK_url

    mkdir -p "$NDK"

    unzip -q NDK.zip -d "$NDK"

    rm NDK.zip

    path="$NDK/android-ndk-r$NDK_version"

    mv "$path"/* "$NDK"

    rm -rf "$path"
fi
