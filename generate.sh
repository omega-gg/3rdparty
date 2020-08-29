#!/bin/bash
set -e

#--------------------------------------------------------------------------------------------------
# Settings
#--------------------------------------------------------------------------------------------------

artifact="2233"

source="http://omega.gg/get/Sky/3rdparty"

#--------------------------------------------------------------------------------------------------

Qt5_version="5.14.2"
Qt5_modules="qtbase qtdeclarative qtxmlpatterns qtsvg"

SSL_versionA="1.0.2u"
SSL_versionB="1.1.1d"

VLC_version="3.0.11"

#--------------------------------------------------------------------------------------------------

libtorrent_artifact="2125"

#--------------------------------------------------------------------------------------------------
# Windows

MinGW_versionA="7.3.0"
MinGW_versionB="730"

jom_versionA="1.1.3"
jom_versionB="1_1_3"

#--------------------------------------------------------------------------------------------------
# Android

JDK_versionA="8u261"
JDK_versionB="1.8.0_261"

SDK_version="29"

NDK_versionA="21"
NDK_versionB="21.1.6352462"

VLC_version_android="3.2.12"

#--------------------------------------------------------------------------------------------------
# environment

compiler_win="mingw"

#--------------------------------------------------------------------------------------------------
# Functions
#--------------------------------------------------------------------------------------------------

copySsl()
{
    mkdir "$2"

    cp android_openssl/latest/$1/*.so "$2"
}

extractVlc()
{
    curl --retry 3 -L -o VLC.apk $VLC_url_android/VLC-Android-$VLC_version_android-$1.apk

    7z x VLC.apk -o"temp" > /dev/null

    rm VLC.apk

    path="$VLC/$1"

    mkdir "$path"

    cp temp/lib/$1/libvlc.so "$path"

    rm -rf temp
}

#--------------------------------------------------------------------------------------------------

getOs()
{
    case `uname` in
    MINGW*)  os="windows";;
    Darwin*) os="macOS";;
    Linux*)  os="linux";;
    *)       os="other";;
    esac

    type=`uname -m`

    if [ $type = "x86_64" ]; then

        if [ $os = "windows" ]; then

            echo win64
        else
            echo $os
        fi

    elif [ $os = "windows" ]; then

        echo win32
    else
        echo $os
    fi
}

getSource()
{
    curl -L -o artifacts.json $1

    artifacts=$(cat artifacts.json)

    rm artifacts.json

    echo $artifacts | $grep -Po '"id":.*?[^\\]}}'         | \
                      $grep "$2\""                        | \
                      $grep -Po '"downloadUrl":.*?[^\\]"' | \
                      $grep -o '"[^"]*"$'                 | tr -d '"'
}

#--------------------------------------------------------------------------------------------------
# Syntax
#--------------------------------------------------------------------------------------------------

if [ $# != 1 -a $# != 2 ] \
   || \
   [ $1 != "win32" -a $1 != "win64" -a $1 != "macOS" -a $1 != "linux" -a $1 != "android" ] \
   || \
   [ $# = 2 -a "$2" != "build" -a "$2" != "clean" ]; then

    echo "Usage: generate <win32 | win64 | macOS | linux | android> [build | clean]"

    exit 1
fi

#--------------------------------------------------------------------------------------------------
# Configuration
#--------------------------------------------------------------------------------------------------

host=$(getOs)

if [ $1 = "win32" -o $1 = "win64" ]; then

    os="windows"

    if [ $1 = "win32" ]; then

        platform="win32"
    else
        platform="win64"
    fi

    compiler="$compiler_win"

    if [ $compiler = "msvc" ]; then

        name="$1-msvc"
    else
        name="$1"
    fi
else
    os="other"

    platform="$1"

    compiler="default"

    name="$1"
fi

#--------------------------------------------------------------------------------------------------
# NOTE: We use ggrep on macOS because it supports Perl regexp.

if [ $host = "macOS" ]; then

    brew install grep

    grep="ggrep"
else
    grep="grep"
fi

#--------------------------------------------------------------------------------------------------

source="$source/$1"

external="$PWD/$1"

install_qt="dist/install-qt.sh"

Qt5="$external/Qt/$Qt5_version"

MinGW="$external/MinGW/$MinGW_versionA"

jom="$external/jom/$jom_versionA"

SSL="$external/OpenSSL"

VLC="$external/VLC/$VLC_version"

JDK="$external/JDK/$JDK_versionA"

SDK="$external/SDK/$SDK_version"
NDK="$external/NDK"

#--------------------------------------------------------------------------------------------------

thirdparty_url="https://dev.azure.com/bunjee/3rdparty/_apis/build/builds/$artifact/artifacts"

libtorrent_url="https://dev.azure.com/bunjee/libtorrent/_apis/build/builds/$libtorrent_artifact/artifacts"

if [ $os = "windows" ]; then

    if [ $platform = "win32" ]; then

        MinGW_url="http://ftp1.nluug.nl/languages/qt/online/qtsdkrepository/windows_x86/desktop/tools_mingw/qt.tools.win32_mingw730/7.3.0-1-201903151311i686-7.3.0-release-posix-dwarf-rt_v5-rev0.7z"

        SSL_urlA="http://wiki.overbyte.eu/arch/openssl-$SSL_versionA-win32.zip"

        SSL_urlB="https://bintray.com/vszakats/generic/download_file?file_path=openssl-$SSL_versionB-win32-mingw.zip"
    else
        MinGW_url="http://ftp1.nluug.nl/languages/qt/online/qtsdkrepository/windows_x86/desktop/tools_mingw/qt.tools.win64_mingw730/7.3.0-1x86_64-7.3.0-release-posix-seh-rt_v5-rev0.7z"

        SSL_urlA="http://wiki.overbyte.eu/arch/openssl-$SSL_versionA-win64.zip"

        SSL_urlB="https://bintray.com/vszakats/generic/download_file?file_path=openssl-$SSL_versionB-win64-mingw.zip"
    fi

    MSVC_url="https://aka.ms/vs/16/release/vs_buildtools.exe"

    jom_url="http://ftp1.nluug.nl/languages/qt/official_releases/jom/jom_$jom_versionB.zip"

    VLC_url="http://download.videolan.org/pub/videolan/vlc/$VLC_version/$platform/vlc-$VLC_version-$platform.7z"

elif [ $1 = "macOS" ]; then

    VLC_url="http://download.videolan.org/pub/videolan/vlc/$VLC_version/macosx/vlc-$VLC_version.dmg"

elif [ $1 = "android" ]; then

    JDK_url="https://oraclemirror.np.gy/jdk8/jdk-$JDK_versionA-linux-x64.tar.gz"

    SDK_url="https://dl.google.com/android/repository/commandlinetools-linux-6200805_latest.zip"

    SSL_urlB="https://github.com/KDAB/android_openssl"

    # FIXME Android: We need the Windows archive for the include folder.
    VLC_url="http://download.videolan.org/pub/videolan/vlc/$VLC_version/win64/vlc-$VLC_version-win64.7z"

    VLC_url_android="https://get.videolan.org/vlc-android/$VLC_version_android"
fi

#--------------------------------------------------------------------------------------------------
# FIXME Azure: grep needs the language to be set to UTF-8.

export LANG=en_US.UTF-8

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
# Install
#--------------------------------------------------------------------------------------------------

if [ $1 = "linux" ]; then

    sh install.sh $1

    exit 0

elif [ $1 = "android" -a $host = "linux" ]; then

    sudo apt-get install -y build-essential

    echo ""
fi

#--------------------------------------------------------------------------------------------------
# MSVC
#--------------------------------------------------------------------------------------------------

if [ $compiler = "msvc" ]; then

    echo "INSTALLING MSVC"
    echo $MSVC_url

    curl -L -o vs_buildtools.exe $MSVC_url

    # NOTE: This prevents the script from exiting when MSVC is already installed.
    set +e

    ./vs_buildtools --quiet --wait --norestart --nocache \
                    --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended

    set -e

    rm vs_buildtools.exe

    echo ""
fi

#--------------------------------------------------------------------------------------------------
# Artifact
#--------------------------------------------------------------------------------------------------

if [ "$2" != "build" -a "$2" != "clean" ]; then

    echo "ARTIFACT 3rdparty-$name"
    echo $thirdparty_url

    thirdparty_url=$(getSource $thirdparty_url 3rdparty-$name)

    echo ""
    echo "DOWNLOADING 3rdparty-$name"
    echo $thirdparty_url

    curl --retry 3 -L -o 3rdparty.zip $thirdparty_url

    echo ""
    echo "EXTRACTING 3rdparty-$name"

    unzip -q 3rdparty.zip

    rm 3rdparty.zip

    unzip -qo 3rdparty-$name/3rdparty.zip

    rm -rf 3rdparty-$name

    exit 0
fi

#--------------------------------------------------------------------------------------------------
# Install
#--------------------------------------------------------------------------------------------------

if [ $host = "win32" -o $host = "win64" ]; then

    if [ ! -d "/c/Program Files/7-Zip" ]; then

        echo "Warning: You need 7zip installed in C:/Program Files/7-Zip"
    else
        PATH="/c/Program Files/7-Zip:$PATH"
    fi

elif [ $host = "macOS" ]; then

    brew install p7zip

    echo ""

elif [ $host = "linux" ]; then

    sudo apt-get install -y p7zip-full

    echo ""
fi

#--------------------------------------------------------------------------------------------------
# 3rdparty
#--------------------------------------------------------------------------------------------------

if [ $platform = "win32" ]; then

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

if [ $os = "windows" ]; then

    if [ $compiler = "msvc" ]; then

        if [ $1 = "win32" ]; then

            toolchain="$platform"_msvc2017
        else
            toolchain="$platform"_msvc2017_64
        fi
    else
        toolchain="$platform"_mingw73
    fi

    bash $install_qt --directory Qt --version $Qt5_version --host windows_x86 \
                     --toolchain $toolchain $Qt5_modules qtwinextras

    if [ $compiler = "mingw" ]; then

        if [ $1 = "win32" ]; then

            Qt="Qt/$Qt5_version/mingw73_32"
        else
            Qt="Qt/$Qt5_version/mingw73_64"
        fi
    else
        if [ $1 = "win32" ]; then

            Qt="Qt/$Qt5_version/msvc2017"
        else
            Qt="Qt/$Qt5_version/msvc2017_64"
        fi
    fi

elif [ $1 = "macOS" ]; then

    bash $install_qt --directory Qt --version $Qt5_version --host mac_x64 \
                     --toolchain clang_64 $Qt5_modules

    Qt="Qt/$Qt5_version/clang_64"

elif [ $1 = "android" ]; then

    bash $install_qt --directory Qt --version $Qt5_version --host linux_x64 --target android \
                     --toolchain any $Qt5_modules androidextras

    Qt="Qt/$Qt5_version/android"
fi

#--------------------------------------------------------------------------------------------------

echo ""
echo "COPYING Qt5"

mkdir -p "$Qt5"/bin
mkdir -p "$Qt5"/plugins/imageformats
mkdir -p "$Qt5"/plugins/platforms
mkdir -p "$Qt5"/qml

mv "$Qt"/bin/qt.conf "$Qt5"/bin

mv "$Qt"/lib "$Qt5"

mv "$Qt"/include "$Qt5"

mv "$Qt"/qml/QtQuick.2 "$Qt5"/qml

mv "$Qt"/mkspecs "$Qt5"

if [ $os = "windows" ]; then

    mv "$Qt"/bin/qmake.exe       "$Qt5"/bin
    mv "$Qt"/bin/moc.exe         "$Qt5"/bin
    mv "$Qt"/bin/rcc.exe         "$Qt5"/bin
    mv "$Qt"/bin/qmlcachegen.exe "$Qt5"/bin

    mv "$Qt"/bin/lib*.dll "$Qt5"/bin

    mv "$Qt"/bin/Qt*.dll "$Qt5"/bin

    mv "$Qt"/plugins/imageformats/q*.dll "$Qt5"/plugins/imageformats
    mv "$Qt"/plugins/platforms/q*.dll    "$Qt5"/plugins/platforms

    #----------------------------------------------------------------------------------------------

    rm -f "$Qt5"/bin/*d.*

    rm -f "$Qt5"/plugins/imageformats/*d.*
    rm -f "$Qt5"/plugins/platforms/*d.*

    rm -f "$Qt5"/lib/*d.*

elif [ $1 = "macOS" ]; then

    mv "$Qt"/bin/qmake       "$Qt5"/bin
    mv "$Qt"/bin/moc         "$Qt5"/bin
    mv "$Qt"/bin/rcc         "$Qt5"/bin
    mv "$Qt"/bin/qmlcachegen "$Qt5"/bin

    mv "$Qt"/plugins/imageformats/libq*.dylib "$Qt5"/plugins/imageformats
    mv "$Qt"/plugins/platforms/libq*.dylib    "$Qt5"/plugins/platforms

    #----------------------------------------------------------------------------------------------

    rm -f "$Qt5"/plugins/imageformats/*debug*
    rm -f "$Qt5"/plugins/platforms/*debug*

    find "$Qt5"/lib -name "*_debug*" -delete

elif [ $1 = "android" ]; then

    mkdir -p "$Qt5"/plugins/bearer

    mv "$Qt"/jar "$Qt5"
    mv "$Qt"/src "$Qt5"

    mv "$Qt"/bin/qmake            "$Qt5"/bin
    mv "$Qt"/bin/moc              "$Qt5"/bin
    mv "$Qt"/bin/rcc              "$Qt5"/bin
    mv "$Qt"/bin/qmlcachegen      "$Qt5"/bin
    mv "$Qt"/bin/qmlimportscanner "$Qt5"/bin
    mv "$Qt"/bin/androiddeployqt  "$Qt5"/bin

    mv "$Qt"/plugins/imageformats/lib*.so "$Qt5"/plugins/imageformats
    mv "$Qt"/plugins/platforms/lib*.so    "$Qt5"/plugins/platforms
    mv "$Qt"/plugins/bearer/lib*.so       "$Qt5"/plugins/bearer
fi

rm -rf Qt

#--------------------------------------------------------------------------------------------------
# MinGW
#--------------------------------------------------------------------------------------------------

if [ $1 = "win32" -o $1 = "win64" ]; then

    echo ""
    echo "DOWNLOADING MinGW"
    echo $MinGW_url

    curl -L -o MinGW.7z $MinGW_url

    mkdir -p "$MinGW"

    7z x MinGW.7z -o"$MinGW" > /dev/null

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
# jom
#--------------------------------------------------------------------------------------------------

if [ $compiler = "msvc" ]; then

    echo ""
    echo "DOWNLOADING jom $jom_versionA"
    echo $jom_url

    curl -L -o jom.zip $jom_url

    mkdir -p "$jom"

    unzip -q jom.zip -d "$jom"

    rm jom.zip
fi

#--------------------------------------------------------------------------------------------------
# SSL
#--------------------------------------------------------------------------------------------------

if [ $os = "windows" ]; then

    echo ""
    echo "DOWNLOADING SSL $SSL_versionA"
    echo $SSL_urlA

    curl -L -o ssl.zip $SSL_urlA

    7z x ssl.zip -ossl > /dev/null

    rm ssl.zip

    path="$SSL/$SSL_versionA"

    mkdir -p "$path"

    mv ssl/libeay32.dll "$path"
    mv ssl/ssleay32.dll "$path"

    rm -rf ssl

    echo ""
    echo "DOWNLOADING SSL $SSL_versionB"
    echo $SSL_urlB

    curl -L -o ssl.zip $SSL_urlB

    7z x ssl.zip -ossl > /dev/null

    rm ssl.zip

    path="$SSL/$SSL_versionB"

    mkdir -p "$path"

    ssl="ssl/openssl-$SSL_versionB-$platform-mingw"

    mv $ssl/libssl*.dll    "$path"
    mv $ssl/libcrypto*.dll "$path"

    rm -rf ssl

elif [ $1 = "android" ]; then

    echo ""
    echo "DOWNLOADING SSL $SSL_versionB"
    echo $SSL_urlB

    git clone $SSL_urlB

    path="$SSL/$SSL_versionB"

    mkdir -p "$path"

    copySsl arm    "$path"/armeabi-v7a
    copySsl arm64  "$path"/arm64-v8a
    copySsl x86    "$path"/x86
    copySsl x86_64 "$path"/x86_64

    rm -rf android_openssl
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

    7z x VLC.7z -o"$VLC" > /dev/null

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

    if [ $host = "macOS" ]; then

        hdiutil attach VLC.dmg

        cp -r "/Volumes/VLC media player/VLC.app/Contents/MacOS/"* "$VLC"

        # TODO: Detach the mounted drive.

        rm VLC.dmg
    else
        #------------------------------------------------------------------------------------------
        # NOTE: We get a header error when extracting the archive with 7z.

        set +e

        7z x VLC.dmg -o"$VLC" > /dev/null

        set -e

        #------------------------------------------------------------------------------------------

        rm VLC.dmg

        path="$VLC/VLC media player"

        mv "$path"/VLC.app/Contents/MacOS/* "$VLC"

        rm -rf "$path"
    fi

elif [ $1 = "android" ]; then

    echo ""
    echo "DOWNLOADING VLC"
    echo $VLC_url

    #----------------------------------------------------------------------------------------------
    # FIXME Android: We need the Windows archive for the include folder.

    curl -L -o VLC.7z $VLC_url

    mkdir -p "$VLC"

    7z x VLC.7z -o"$VLC" > /dev/null

    rm VLC.7z

    path="$VLC/vlc-$VLC_version"

    mv "$path"/sdk/include "$VLC"

    rm -rf "$path"

    #----------------------------------------------------------------------------------------------

    extractVlc armeabi-v7a
    extractVlc arm64-v8a
    extractVlc x86
    extractVlc x86_64

    rm -rf VLC
fi

#--------------------------------------------------------------------------------------------------
# libtorrent
#--------------------------------------------------------------------------------------------------

echo ""
echo "ARTIFACT libtorrent-$name"
echo $libtorrent_url

libtorrent_url=$(getSource $libtorrent_url libtorrent-$name)

echo ""
echo "DOWNLOADING libtorrent"
echo $libtorrent_url

curl --retry 3 -L -o libtorrent.zip $libtorrent_url

unzip -q libtorrent.zip

rm libtorrent.zip

unzip -q libtorrent-$name/libtorrent.zip -d "$external"

rm -rf libtorrent-$name

#--------------------------------------------------------------------------------------------------
# JDK
#--------------------------------------------------------------------------------------------------

if [ $1 = "android" ]; then

    echo ""
    echo "DOWNLOADING JDK"
    echo $JDK_url

    curl -L -o JDK.tar.gz $JDK_url

    mkdir -p "$JDK"

    tar -xf JDK.tar.gz -C "$JDK"

    rm JDK.tar.gz

    path="$JDK/jdk$JDK_versionB"

    mv "$path"/* "$JDK"

    rm -rf "$path"
fi

#--------------------------------------------------------------------------------------------------
# SDK
#--------------------------------------------------------------------------------------------------

if [ $1 = "android" ]; then

    echo ""
    echo "DOWNLOADING SDK"
    echo $SDK_url

    curl -L -o SDK.zip $SDK_url

    mkdir -p "$SDK"

    unzip -q SDK.zip -d "$SDK"

    rm SDK.zip
fi

#--------------------------------------------------------------------------------------------------
# NDK
#--------------------------------------------------------------------------------------------------

if [ $1 = "android" ]; then

    echo ""
    echo "DOWNLOADING NDK from SDK"

    cd "$SDK/tools/bin"

    export JAVA_HOME="$JDK"

    path="$PWD/../.."

    yes | ./sdkmanager --sdk_root="$path" --licenses

    ./sdkmanager --sdk_root="$path" "ndk;$NDK_versionB"

    ./sdkmanager --sdk_root="$path" --update

    cd -

    mkdir -p "$NDK"

    cd "$NDK"

    ln -s "../SDK/$SDK_version/ndk/$NDK_versionB" "$NDK_versionA"

    cd -
fi
