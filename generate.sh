#!/bin/bash
set -e

#--------------------------------------------------------------------------------------------------
# Settings
#--------------------------------------------------------------------------------------------------

source="http://omega.gg/get/Sky/3rdparty"

#--------------------------------------------------------------------------------------------------

Qt5_version="5.12.3"

VLC_version="3.0.6"

#--------------------------------------------------------------------------------------------------
# Android

NDK_version="21"

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
# NOTE: OSTYPE is not defined in Docker instances.

if [ "$OSTYPE" = "" ]; then

    export OSTYPE=linux-gnu
fi

#--------------------------------------------------------------------------------------------------

if [ $1 = "win32" -o $1 = "win64" ]; then

    os="windows"

elif [ $1 = "android32" -o $1 = "android64" ]; then

    os="android"
else
    os="other"
fi

source="$source/$1"

external="$1"

install_qt="dist/install-qt.sh"

Qt5="$external/Qt/$Qt5_version"

VLC="$external/VLC/$VLC_version"

NDK="$external/NDK/$NDK_version"

#--------------------------------------------------------------------------------------------------

if [ $os = "windows" ]; then

    VLC_url="http://download.videolan.org/pub/videolan/vlc/$VLC_version/$1/vlc-$VLC_version-$1.7z"

elif [ $1 = "macOS" ]; then

    VLC_url="http://download.videolan.org/pub/videolan/vlc/$VLC_version/macosx/vlc-$VLC_version.dmg"

elif [ $os = "android" ]; then

    NDK_url="https://dl.google.com/android/repository/android-ndk-r$NDK_version-linux-x86_64.zip"
fi

#--------------------------------------------------------------------------------------------------
# Clean
#--------------------------------------------------------------------------------------------------

if [ "$2" = "clean" ]; then

    rm -rf $1
    mkdir  $1
    touch  $1/.gitignore

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

if [ "$OSTYPE" = "darwin"* ]; then

    brew install p7zip

    echo ""

elif [ "$OSTYPE" = "linux"* ]; then

    sudo apt-get install -y p7zip-full

    echo ""
fi

#--------------------------------------------------------------------------------------------------
# 3rdparty
#--------------------------------------------------------------------------------------------------

if [ $os = "windows" ] || [ $1 = "macOS" ]; then

    echo "DOWNLOADING 3rdparty"
    echo "$source"
    echo ""

    curl --retry 3 -L -o 3rdparty.zip "$source"

    unzip -o -q 3rdparty.zip -d "$PWD/.."

    rm 3rdparty.zip

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
# VLC
#--------------------------------------------------------------------------------------------------

if [ $os = "windows" ]; then

    echo ""
    echo "DOWNLOADING VLC"
    echo $VLC_url

    curl -L -o VLC.7z $VLC_url

    test -d "$VLC" && rm -rf "$VLC"/*

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

    test -d "$VLC" && rm -rf "$VLC"/*

    if [ "$OSTYPE" = "darwin"* ]; then

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
# NDK
#--------------------------------------------------------------------------------------------------

if [ $os = "android" ]; then

    echo ""
    echo "DOWNLOADING NDK"

    curl -L -o NDK.zip $NDK_url

    test -d "$NDK" && rm -rf "$NDK"/*

    mkdir -p "$NDK"

    unzip -q NDK.zip -d "$NDK"

    rm NDK.zip

    path="$NDK/android-ndk-r$NDK_version"

    mv "$path"/* "$NDK"

    rm -rf "$path"
fi
