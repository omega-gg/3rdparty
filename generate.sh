#!/bin/sh
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

if [ $# != 1 ] || [ $1 != "win32" -a $1 != "win64" -a $1 != "macOS" -a $1 != "linux"     -a \
                                                                       $1 != "android32" -a \
                                                                       $1 != "android64" ]; then

    echo "Usage: generate <win32 | win64 | macOS | linux | android32 | android64>"

    exit 1
fi

#--------------------------------------------------------------------------------------------------
# Install
#--------------------------------------------------------------------------------------------------

if [ $1 = "macOS" ]; then

    brew install p7zip

elif [ $1 = "linux" ]; then

    sh install.sh $1

    exit 0
fi

#--------------------------------------------------------------------------------------------------
# Configuration
#--------------------------------------------------------------------------------------------------

if [ $1 = "win32" -o $1 = "win64" ]; then

    os="windows"

elif [ $1 = "android32" -o $1 = "android64" ]; then

    os="android"
else
    os=""
fi

source="$source/$1"

external="$1"

install_qt="dist/install-qt.sh"

Qt5="$external/Qt/$Qt5_version"

VLC="$external/VLC/$VLC_version"

#--------------------------------------------------------------------------------------------------

if [ $os = "windows" ]; then

    VLC_url="http://download.videolan.org/pub/videolan/vlc/$VLC_version/$1/vlc-$VLC_version-$1.7z"

elif [ $1 = "macOS" ]; then

    VLC_url="http://download.videolan.org/pub/videolan/vlc/$VLC_version/macosx/vlc-$VLC_version.dmg"

elif [ $os = "android" ]; then

    NDK_url="https://dl.google.com/android/repository/android-ndk-r$NDK_version-linux-x86_64.zip"
fi

#--------------------------------------------------------------------------------------------------
# 3rdparty
#--------------------------------------------------------------------------------------------------

if [ $os = "windows" ] || [ $1 = "macOS" ]; then

    echo "DOWNLOADING 3rdparty"
    echo "$source"

    curl -L -o 3rdparty.zip --retry 3 "$source"

    unzip -o -q 3rdparty.zip -d ..

    rm 3rdparty.zip
fi

#--------------------------------------------------------------------------------------------------
# Qt5
#--------------------------------------------------------------------------------------------------

echo ""
echo "DOWNLOADING Qt5"

test -d "$Qt5" && rm -rf "$Qt5"/*

if [ $os = "windows" ]; then

    sh $install_qt --directory "$Qt5" --version $Qt5_version \
                   --toolchain $1_mingw73 qtbase qtdeclarative qtxmlpatterns qtsvg qtwinextras

    if [ $1 = "win32" ]; then

        mv "$Qt5"/$Qt5_version/mingw73_32/* "$Qt5"
    else
        mv "$Qt5"/$Qt5_version/mingw73_64/* "$Qt5"
    fi

elif [ $1 = "macOS" ]; then

    sh $install_qt --directory "$Qt5" --version $Qt5_version \
                   --toolchain clang_64 qtbase qtdeclarative qtxmlpatterns qtsvg

    mv "$Qt5"/$Qt5_version/clang_64/* "$Qt5"

elif [ $1 = "android32" ]; then

    sh $install_qt --directory "$Qt5" --version $Qt5_version \
                   --host linux_x64 --target android \
                   --toolchain android_armv7 qtbase qtdeclarative qtxmlpatterns qtsvg

    mv "$Qt5"/$Qt5_version/android_armv7/* "$Qt5"

elif [ $1 = "android64" ]; then

    sh $install_qt --directory "$Qt5" --version $Qt5_version \
                   --host linux_x64 --target android \
                   --toolchain android_arm64_v8a qtbase qtdeclarative qtxmlpatterns qtsvg

    mv "$Qt5"/$Qt5_version/android_arm64_v8a/* "$Qt5"
fi

rm -rf "$Qt5"/$Qt5_version

#--------------------------------------------------------------------------------------------------
# VLC
#--------------------------------------------------------------------------------------------------

echo ""
echo "DOWNLOADING VLC"
echo $VLC_url

if [ $os = "windows" ]; then

    curl -L -o VLC.7z $VLC_url

    test -d "$VLC" && rm -rf "$VLC"/*

    7z x VLC.7z -o"$VLC"

    rm VLC.7z

    path="$VLC/vlc-$VLC_version"

    mv "$path"/* "$VLC"

    rm -rf "$path"

elif [ $1 = "macOS" ]; then

    curl -L -o VLC.dmg $VLC_url

    test -d "$VLC" && rm -rf "$VLC"/*

    #----------------------------------------------------------------------------------------------
    # NOTE macOS: We get a header error when extracting the archive with 7z.

    set +e

    7z x VLC.dmg -o"$VLC"

    set -e

    #----------------------------------------------------------------------------------------------

    rm VLC.dmg

    path="$VLC/VLC media player"

    mv "$path"/VLC.app/Contents/MacOS/* "$VLC"

    rm -rf "$path"
fi

#--------------------------------------------------------------------------------------------------
# NDK
#--------------------------------------------------------------------------------------------------

if [ $os = "android" ]; then

    echo ""
    echo "DOWNLOADING NDK"

    curl -L -o NDK.zip $NDK_url

    test -d "$NDK" && rm -rf "$NDK"/*

    unzip -q NDK.zip -d "$NDK"

    rm NDK.zip

    path="$NDK/android-ndk-r$NDK_version"

    mv "$path"/* "$NDK"

    rm -rf "$path"
fi
