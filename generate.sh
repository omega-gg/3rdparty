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

VLC_version="3.0.6"

#--------------------------------------------------------------------------------------------------
# Android

NDK_version="21"

#--------------------------------------------------------------------------------------------------
# Functions
#--------------------------------------------------------------------------------------------------

function artifact
{
    echo $artifacts | $grep -Po '"id":.*?[^\\]}}'         | \
                      $grep $1                            | \
                      $grep -Po '"downloadUrl":.*?[^\\]"' | \
                      $grep -o '"[^"]*"$'                 | tr -d '"'
}

#--------------------------------------------------------------------------------------------------
# Syntax
#--------------------------------------------------------------------------------------------------

if [ $# != 1 -a $# != 2 ] \
   || \
   [ $1 != "win32" -a \
     $1 != "win64" -a \
     $1 != "macOS" -a \
     $1 != "linux" -a \
     $1 != "android32" -a $1 != "android64" ] || [ $# = 2 -a "$2" != "clean" ]; then

    echo "Usage: generate <win32 | win64 | macOS | linux | android32 | android64> [clean]"

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

if [[ "$OSTYPE" == "darwin"* ]]; then

    # NOTE: We use ggrep on macOS because it supports Perl regexp (brew install grep).
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

libtorrent_url="https://dev.azure.com/bunjee/libtorrent/_apis/build/builds/627/artifacts"

if [ $os = "windows" ]; then

    if [ $1 = "win32" ]; then

        MinGW_url="http://ftp1.nluug.nl/languages/qt/online/qtsdkrepository/windows_x86/desktop/tools_mingw/qt.tools.win32_mingw730/7.3.0-1-201903151311i686-7.3.0-release-posix-dwarf-rt_v5-rev0.7z"

        SSL_url="https://indy.fulgan.com/SSL/Archive/openssl-1.0.2p-i386-win32.zip"
    else
        MinGW_url="http://ftp1.nluug.nl/languages/qt/online/qtsdkrepository/windows_x86/desktop/tools_mingw/qt.tools.win64_mingw730/7.3.0-1x86_64-7.3.0-release-posix-seh-rt_v5-rev0.7z"

        SSL_url="https://indy.fulgan.com/SSL/Archive/openssl-1.0.2p-x64_86-win64.zip"
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
echo ""

rm -rf $1
mkdir  $1
touch  $1/.gitignore

if [ "$2" = "clean" ]; then

    exit 0
fi

#--------------------------------------------------------------------------------------------------
# Install
#--------------------------------------------------------------------------------------------------

if [ $1 = "linux" ]; then

    sh install.sh $1

    exit 0
fi

#--------------------------------------------------------------------------------------------------
# NOTE: We need 7z on macOS and Linux.

if [[ "$OSTYPE" == "darwin"* ]]; then

    brew install grep p7zip

    echo ""

elif [[ "$OSTYPE" == "linux"* ]]; then

    sudo apt-get install -y p7zip-full

    echo ""
fi

#--------------------------------------------------------------------------------------------------
# 3rdparty
#--------------------------------------------------------------------------------------------------

if [ $os = "windows" ]; then

    echo "DOWNLOADING 3rdparty"
    echo "$source"
    echo ""

    curl --retry 3 -L -o 3rdparty.zip "$source"

    unzip -q 3rdparty.zip

    rm 3rdparty.zip

    mv 3rdparty/$1/* $1

    rm -rf 3rdparty

    echo ""
fi

#--------------------------------------------------------------------------------------------------
# Qt5
#--------------------------------------------------------------------------------------------------

echo "DOWNLOADING Qt5"

test -d "$Qt5" && rm -rf "$Qt5"/*

if [ $os = "windows" ]; then

    bash $install_qt --directory "$Qt5" --version $Qt5_version --host windows_x86 \
                     --toolchain $1_mingw73 qtbase qtdeclarative qtxmlpatterns qtsvg qtwinextras

    if [ $1 = "win32" ]; then

        mv "$Qt5"/$Qt5_version/mingw73_32/* "$Qt5"
    else
        mv "$Qt5"/$Qt5_version/mingw73_64/* "$Qt5"
    fi

elif [ $1 = "macOS" ]; then

    bash $install_qt --directory "$Qt5" --version $Qt5_version --host mac_x64 \
                     --toolchain clang_64 qtbase qtdeclarative qtxmlpatterns qtsvg

    mv "$Qt5"/$Qt5_version/clang_64/* "$Qt5"

elif [ $1 = "android32" ]; then

    bash $install_qt --directory "$Qt5" --version $Qt5_version --host linux_x64 --target android \
                     --toolchain android_armv7 qtbase qtdeclarative qtxmlpatterns qtsvg

    mv "$Qt5"/$Qt5_version/android_armv7/* "$Qt5"

elif [ $1 = "android64" ]; then

    bash $install_qt --directory "$Qt5" --version $Qt5_version --host linux_x64 --target android \
                     --toolchain android_arm64_v8a qtbase qtdeclarative qtxmlpatterns qtsvg

    mv "$Qt5"/$Qt5_version/android_arm64_v8a/* "$Qt5"
fi

rm -rf "$Qt5"/$Qt5_version

#--------------------------------------------------------------------------------------------------
# MinGW
#--------------------------------------------------------------------------------------------------

if [ $os = "windows" ]; then

    echo ""
    echo "DOWNLOADING MinGW"
    echo $MinGW_url

    curl -L -o MinGW.7z $MinGW_url

    test -d "$MinGW" && rm -rf "$MinGW"

    7z x MinGW.7z -o"$MinGW"

    rm MinGW.7z

    if [ $1 = "win32" ]; then

        path="$MinGW/Tools/mingw$(MinGW_versionB)_32"
    else
        path="$MinGW/Tools/mingw$(MinGW_versionB)_64"
    fi

    ls -la "$MinGW"

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

    test -d "$SSL" && rm -rf "$SSL"

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

    test -d "$VLC" && rm -rf "$VLC"

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

    test -d "$VLC" && rm -rf "$VLC"

    if [[ "$OSTYPE" == "darwin"* ]]; then

        hdiutil attach VLC.dmg

        mkdir -p "$VLC"

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

echo ""
echo "DOWNLOADING artifact"
echo $libtorrent_url

if [ $os = "windows" ]; then
    #----------------------------------------------------------------------------------------------
    # FIXME Azure: It seems that the language is not set by default.

    echo "LOCALE BEFORE"
    locale

    export LANG=en_US.UTF-8

    echo "LOCALE AFTER"
    locale

    #----------------------------------------------------------------------------------------------
fi

curl -L -o artifacts.json $libtorrent_url

test -d "$libtorrent" && rm -rf "$libtorrent"
test -d "$Boost"      && rm -rf "$Boost"

artifacts=$(cat artifacts.json)

rm artifacts.json

libtorrent_url=$(artifact libtorrent-$1)

echo ""
echo "DOWNLOADING libtorrent"
echo $libtorrent_url

curl -L -o libtorrent.zip $libtorrent_url

unzip -q libtorrent.zip

rm libtorrent.zip

unzip -q -o libtorrent-$1/deploy.zip -d "$external"

rm -rf libtorrent-$1

#--------------------------------------------------------------------------------------------------
# NDK
#--------------------------------------------------------------------------------------------------

if [ $os = "android" ]; then

    echo ""
    echo "DOWNLOADING NDK"
    echo $NDK_url

    curl -L -o NDK.zip $NDK_url

    test -d "$NDK" && rm -rf "$NDK"

    mkdir -p "$NDK"

    unzip -q NDK.zip -d "$NDK"

    rm NDK.zip

    path="$NDK/android-ndk-r$NDK_version"

    mv "$path"/* "$NDK"

    rm -rf "$path"
fi
