#!/bin/bash
set -e

#--------------------------------------------------------------------------------------------------
# Settings
#--------------------------------------------------------------------------------------------------

artifact="6919"

source="http://omega.gg/get/Sky/3rdparty"

#--------------------------------------------------------------------------------------------------

Qt5_version="5.15.2"
Qt5_modules="qtbase qtdeclarative qtxmlpatterns qtimageformats qtsvg qtmultimedia"

Qt6_version="6.6.0"
Qt6_modules="qtbase qtdeclarative qtimageformats qtsvg qtmultimedia qt5compat qtshadertools"

SSL_versionA="1.0.2u"
SSL_versionB="1.1.1s"
SSL_versionC="1.1"

VLC_version="3.0.18"

#--------------------------------------------------------------------------------------------------

libtorrent_artifact="6917"

Sky_artifact="6646"

#--------------------------------------------------------------------------------------------------
# Windows

MinGW_versionA="11.2.0"
MinGW_versionB="1120"
MinGW_versionC="810"

BuildTools_version="17"

jom_versionA="1.1.3"
jom_versionB="1_1_3"

#--------------------------------------------------------------------------------------------------
# iOS

VLC_version_iOS="3.3.18b12"

#--------------------------------------------------------------------------------------------------
# Linux

lib32="/usr/lib/i386-linux-gnu"

#--------------------------------------------------------------------------------------------------
# Android

JDK_version="11.0.2"

SDK_version="33"

NDK_versionA="25"
NDK_versionB="25.1.8937393"

VLC_android="3.5.1"

#--------------------------------------------------------------------------------------------------
# environment

compiler_win="mingw"

qt="qt5"

#--------------------------------------------------------------------------------------------------
# Functions
#--------------------------------------------------------------------------------------------------

installQt()
{
    echo "bash $install_qt --directory Qt --version $Qt_version --host linux_x64 --target $1 --toolchain $2 $3"

    bash $install_qt --directory Qt --version $Qt_version --host linux_x64 --target $1 \
                     --toolchain $2 $3

    path="Qt/$Qt_version/$2"
}

mkdirQt()
{
    if [ $os != "mobile" -o $qt = "qt5" ]; then

        mkdir -p "$QtX"/$1

    elif [ $platform = "iOS" ]; then

        mkdir -p "$QtX"/ios/$1

    else # android

        mkdir -p "$QtX"/android_armv7/$1
        mkdir -p "$QtX"/android_arm64_v8a/$1
        mkdir -p "$QtX"/android_x86/$1
        mkdir -p "$QtX"/android_x86_64/$1
    fi
}

mkdirQtAll()
{
    mkdirQt $1 $2

    if [ $os != "mobile" -o $qt = "qt5" ]; then

        return
    fi

    if [ $platform = "iOS" ]; then

        mkdir -p "$QtX"/macos/$1

    else # android

        mkdir -p "$QtX"/gcc_64/$1
    fi
}


moveQt()
{
    if [ $os != "mobile" -o $qt = "qt5" ]; then

        mv "$Qt"/$1 "$QtX"/$2

    elif [ $platform = "iOS" ]; then

        mv "$Qt"/ios/$1 "$QtX"/ios/$2

    else # android

        mv "$Qt"/android_armv7/$1     "$QtX"/android_armv7/$2
        mv "$Qt"/android_arm64_v8a/$1 "$QtX"/android_arm64_v8a/$2
        mv "$Qt"/android_x86/$1       "$QtX"/android_x86/$2
        mv "$Qt"/android_x86_64/$1    "$QtX"/android_x86_64/$2
    fi
}

moveQtAll()
{
    moveQt $1 $2

    if [ $os != "mobile" -o $qt = "qt5" ]; then

        return
    fi

    if [ $platform = "iOS" ]; then

        mv "$Qt"/macos/$1 "$QtX"/macos/$2

    else # android

        mv "$Qt"/gcc_64/$1 "$QtX"/gcc_64/$2
    fi
}

moveMobile()
{
    if [ $os != "mobile" -o $qt = "qt5" ]; then

        mv "$Qt"/$1 "$QtX"/$2

    elif [ $platform = "iOS" ]; then

        mv "$Qt"/ios/$1 "$QtX"/ios/$2

    else # android

        mv "$Qt"/android_armv7/$1     "$QtX"/android_armv7/$2
        mv "$Qt"/android_arm64_v8a/$1 "$QtX"/android_arm64_v8a/$2
        mv "$Qt"/android_x86/$1       "$QtX"/android_x86/$2
        mv "$Qt"/android_x86_64/$1    "$QtX"/android_x86_64/$2
    fi
}

#--------------------------------------------------------------------------------------------------

copySsl()
{
    output="$2"/$1

    mkdir "$output"

    # FIXME Qt 6.5+
    cp android_openssl/ssl_1.1/$1/*.so "$output"
}

extractVlc()
{
    output="$VLC/$1"

    mkdir "$output"

    cp VLC/jni/$1/libvlc.so "$output"

    # NOTE android/VLC: We need a specific libc++_shared library.
    cp VLC/jni/$1/libc++_shared.so "$output"
}

linkNdk()
{
    cd "$1"

    ln -s "30" "31"

    cd -
}

apply()
{
    if [ $host = "macOS" ]; then

        sed -i "" $1 $2
    else
        sed -i $1 $2
    fi
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
   [ $1 != "win32" -a $1 != "win64" -a $1 != "macOS" -a $1 != "iOS" -a $1 != "linux" -a \
     $1 != "android" ] \
   || \
   [ $# = 2 -a "$2" != "build" -a "$2" != "clean" ]; then

    echo "Usage: generate <win32 | win64 | macOS | iOS | linux | android> [build | clean]"

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
    if [ $1 = "iOS" -o $1 = "android" ]; then

        os="mobile"
    else
        os="default"
    fi

    if [ $1 = "linux" ]; then

        if [ -d "${lib32}" ]; then

            platform="linux32"
        else
            platform="linux64"
        fi
    else
        platform="$1"
    fi

    compiler="default"

    name="$platform"
fi

#--------------------------------------------------------------------------------------------------
# NOTE: We use ggrep on macOS because it supports Perl regexp.

if [ $host = "macOS" ]; then

    set +e

    # NOTE: This generates an error when grep is already installed.
    brew install grep

    set -e

    grep="ggrep"
else
    grep="grep"
fi

#--------------------------------------------------------------------------------------------------

source="$source/$1"

external="$PWD/$1"

install_qt="dist/install-qt.sh"

if [ $qt = "qt5" ]; then

    Qt_version="$Qt5_version"
    Qt_modules="$Qt5_modules"
else
    Qt_version="$Qt6_version"
    Qt_modules="$Qt6_modules"
fi

QtX="$external/Qt/$Qt_version"

MinGW="$external/MinGW/$MinGW_versionA"

jom="$external/jom/$jom_versionA"

SSL="$external/OpenSSL"

VLC="$external/VLC/$VLC_version"

JDK="$external/JDK/$JDK_version"

SDK="$external/SDK/$SDK_version"
NDK="$external/NDK"

Sky="$external/Sky"

#--------------------------------------------------------------------------------------------------

thirdparty_url="https://dev.azure.com/bunjee/3rdparty/_apis/build/builds/$artifact/artifacts"

libtorrent_url="https://dev.azure.com/bunjee/libtorrent/_apis/build/builds/$libtorrent_artifact/artifacts"

if [ $os = "windows" ]; then

    if [ $platform = "win32" ]; then

        MinGW_url="https://github.com/niXman/mingw-builds-binaries/releases/download/11.2.0-rt_v9-rev1/i686-11.2.0-release-posix-dwarf-rt_v9-rev1.7z"

        SSL_urlA="https://indy.fulgan.com/SSL/openssl-$SSL_versionA-i386-win32.zip"
    else
        MinGW_url="http://ftp1.nluug.nl/languages/qt/online/qtsdkrepository/windows_x86/desktop/tools_mingw90/qt.tools.win64_mingw900/9.0.0-1-202203221220mingw-w64-x86_64-11.2.0-release-posix-seh-rt_v9-rev3.7z"

        SSL_urlA="https://indy.fulgan.com/SSL/openssl-$SSL_versionA-x64_86-win64.zip"
    fi

    SSL_urlB="https://download.firedaemon.com/FireDaemon-OpenSSL/openssl-${SSL_versionB}.zip"

    MSVC_url="https://aka.ms/vs/$BuildTools_version/release/vs_buildtools.exe"

    jom_url="http://ftp1.nluug.nl/languages/qt/official_releases/jom/jom_$jom_versionB.zip"

    VLC_url="https://download.videolan.org/pub/videolan/vlc/$VLC_version/$platform/vlc-$VLC_version-$platform.7z"

elif [ $1 = "macOS" ]; then

    VLC_url="https://download.videolan.org/pub/videolan/vlc/$VLC_version/macosx/vlc-$VLC_version-intel64.dmg"

elif [ $1 = "iOS" ]; then

    VLC_url="http://download.videolan.org/pub/cocoapods/prod/MobileVLCKit-$VLC_version_iOS-9748e1a4-426513d8.tar.xz"

elif [ $1 = "linux" ]; then

    linuxdeployqt_url="https://github.com/probonopd/linuxdeployqt/releases/download/continuous/linuxdeployqt-continuous-x86_64.AppImage"

elif [ $1 = "android" ]; then

    JDK_url="https://download.java.net/java/GA/jdk11/9/GPL/openjdk-${JDK_version}_linux-x64_bin.tar.gz"

    SDK_url="https://dl.google.com/android/repository/commandlinetools-linux-6200805_latest.zip"

    SSL_urlB="https://github.com/KDAB/android_openssl"

    VLC_url_android="https://repo1.maven.org/maven2/org/videolan/android/libvlc-all/$VLC_android/libvlc-all-$VLC_android.aar"
fi

# FIXME: We need the Windows archive for the include folder.
if [ $1 = "linux" -o $1 = "android" ]; then

    VLC_url="https://download.videolan.org/pub/videolan/vlc/$VLC_version/win64/vlc-$VLC_version-win64.7z"
fi

Sky_url="https://dev.azure.com/bunjee/Sky/_apis/build/builds/$Sky_artifact/artifacts"

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

    if [ "$2" = "build" ]; then

        sh install.sh $1 build
    else
        sh install.sh $1
    fi

elif [ $1 = "android" -a $host = "linux" ]; then

    sh install.sh linux
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

    name="$name-$qt"

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

# NOTE: p7zip-full does not exists for Ubuntu 20.04 on i386.
elif [ $host = "linux" -a $platform != "linux32" ]; then

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
# Qt
#--------------------------------------------------------------------------------------------------

if [ $qt != "qt4" ]; then

    echo "DOWNLOADING Qt"

    if [ $os = "windows" ]; then

        if [ $compiler = "msvc" ]; then

            if [ $1 = "win32" ]; then

                toolchain="$platform"_msvc2019
            else
                toolchain="$platform"_msvc2019_64
            fi
        elif [ $qt = "qt5" ]; then

            toolchain="$platform"_mingw81
        else
            toolchain="$platform"_mingw
        fi

        if [ $qt = "qt5" ]; then

            Qt_modules="$Qt_modules qtwinextras"
        fi

        echo "bash $install_qt --directory Qt --version $Qt_version --host windows_x86 --toolchain $toolchain $Qt_modules"

        bash $install_qt --directory Qt --version $Qt_version --host windows_x86 \
                         --toolchain $toolchain $Qt_modules

        if [ $compiler = "mingw" ]; then

            if [ $qt = "qt5" ]; then

                if [ $1 = "win32" ]; then

                    Qt="Qt/$Qt_version/mingw81_32"
                else
                    Qt="Qt/$Qt_version/mingw81_64"
                fi
            elif [ $1 = "win32" ]; then

                Qt="Qt/$Qt_version/mingw_32"
            else
                Qt="Qt/$Qt_version/mingw_64"
            fi
        else
            if [ $1 = "win32" ]; then

                Qt="Qt/$Qt_version/msvc2019"
            else
                Qt="Qt/$Qt_version/msvc2019_64"
            fi
        fi

    elif [ $1 = "macOS" ]; then

        # NOTE: This is useful for macdeployqt.
        Qt_modules="$Qt_modules qttools"

        echo "bash $install_qt --directory Qt --version $Qt_version --host mac_x64 --toolchain clang_64 $Qt_modules"

        bash $install_qt --directory Qt --version $Qt_version --host mac_x64 \
                         --toolchain clang_64 $Qt_modules

        if [ $qt = "qt5" ]; then

            Qt="Qt/$Qt_version/clang_64"
        else
            Qt="Qt/$Qt_version/macos"
        fi

    elif [ $1 = "iOS" ]; then

        if [ $qt = "qt5" ]; then

            Qt="Qt/$Qt_version/ios"
        else
            echo "bash $install_qt --directory Qt --version $Qt_version --host mac_x64 --toolchain clang_64 $Qt_modules"

            # NOTE Qt6: We need the desktop toolchain to build iOS.
            bash $install_qt --directory Qt --version $Qt_version --host mac_x64 \
                             --toolchain clang_64 $Qt_modules

            Qt="Qt/$Qt_version"
        fi

        echo "bash $install_qt --directory Qt --version $Qt_version --host mac_x64 --target ios --toolchain ios $Qt_modules"

        bash $install_qt --directory Qt --version $Qt_version --host mac_x64 \
                         --target ios --toolchain ios $Qt_modules

    elif [ $platform = "linux64" ]; then

        if [ $qt = "qt5" ]; then

            Qt_modules="$Qt_modules qtx11extras icu"
        else
            Qt_modules="$Qt_modules icu"
        fi

        echo "bash $install_qt --directory Qt --version $Qt_version --host linux_x64 --toolchain gcc_64 $Qt_modules"

        bash $install_qt --directory Qt --version $Qt_version --host linux_x64 \
                         --toolchain gcc_64 $Qt_modules

        Qt="Qt/$Qt_version/gcc_64"

    elif [ $1 = "android" ]; then

        # NOTE android: This is required for install-qt.sh.
        export QT_VERSION="$Qt_version"

        if [ $qt = "qt5" ]; then

            echo "bash $install_qt --directory Qt --version $Qt_version --host linux_x64 --target android --toolchain any $Qt_modules androidextras"

            bash $install_qt --directory Qt --version $Qt_version --host linux_x64 \
                             --target android --toolchain any $Qt_modules androidextras

            Qt="Qt/$Qt_version/android"
        else
            Qt="Qt/$Qt_version"

            # NOTE Qt6: We need the desktop toolchain to build android.
            installQt desktop gcc_64 "$Qt_modules icu"

            installQt android android_armv7     "$Qt_modules"
            installQt android android_arm64_v8a "$Qt_modules"
            installQt android android_x86       "$Qt_modules"
            installQt android android_x86_64    "$Qt_modules"
        fi
    fi
fi

#--------------------------------------------------------------------------------------------------

if [ $qt != "qt4" -a $platform != "linux32" ]; then

    echo ""
    echo "COPYING Qt"

    mkdirQtAll "bin"

    mkdirQt "plugins/platforms"
    mkdirQt "plugins/imageformats"
    mkdirQt "qml"

    moveQtAll "bin/qmake*" "bin"

    moveQtAll "bin/*qt.conf" "bin"

    # NOTE: We need the lib folder for the qmake binary.
    moveQtAll "lib" "."

    moveQt "include" "."

    if [ $qt = "qt5" ]; then

        mkdirQt "plugins/mediaservice"

        mv "$Qt"/qml/QtQuick.2    "$QtX"/qml
        mv "$Qt"/qml/QtMultimedia "$QtX"/qml
    else
        mkdirQt "plugins/tls"

        moveQt "qml/QtQml"        "qml"
        moveQt "qml/QtQuick"      "qml"
        moveQt "qml/QtMultimedia" "qml"
    fi

    moveQtAll "mkspecs" "."

    if [ $os = "windows" ]; then

        mv "$Qt"/bin/moc*         "$QtX"/bin
        mv "$Qt"/bin/rcc*         "$QtX"/bin
        mv "$Qt"/bin/qmlcachegen* "$QtX"/bin

        if [ $qt = "qt5" ]; then

            mv "$Qt"/bin/lib*.dll "$QtX"/bin

            mv "$Qt"/plugins/mediaservice/*.dll "$QtX"/plugins/mediaservice

            rm -f "$QtX"/plugins/mediaservice/*d.*
        else
            mv "$Qt"/bin/qsb* "$QtX"/bin

            mv "$Qt"/plugins/tls/*.dll "$QtX"/plugins/tls

            # NOTE: Making sure to keep the 'backend.dll' files.
            rm -f "$QtX"/plugins/tls/*backendd.*
        fi

        mv "$Qt"/bin/Qt*.dll "$QtX"/bin

        mv "$Qt"/plugins/platforms/q*.dll    "$QtX"/plugins/platforms
        mv "$Qt"/plugins/imageformats/q*.dll "$QtX"/plugins/imageformats

        #------------------------------------------------------------------------------------------

        rm -f "$QtX"/bin/*d.*

        rm -f "$QtX"/plugins/platforms/*d.*
        rm -f "$QtX"/plugins/imageformats/*d.*

        rm -f "$QtX"/lib/*d.*

    elif [ $1 = "macOS" ]; then

        mv "$Qt"/bin/macdeployqt "$QtX"/bin

        if [ $qt = "qt5" ]; then

            mv "$Qt"/bin/moc*         "$QtX"/bin
            mv "$Qt"/bin/rcc*         "$QtX"/bin
            mv "$Qt"/bin/qmlcachegen* "$QtX"/bin

            # NOTE: This is required for macdeployqt.
            mv "$Qt"/bin/qmlimportscanner "$QtX"/bin

            mv "$Qt"/plugins/mediaservice/lib*.dylib "$QtX"/plugins/mediaservice

            rm -f "$QtX"/plugins/mediaservice/*debug*
        else
            mkdir "$QtX"/libexec

            mv "$Qt"/bin/qsb* "$QtX"/bin

            mv "$Qt"/libexec/moc*         "$QtX"/libexec
            mv "$Qt"/libexec/rcc*         "$QtX"/libexec
            mv "$Qt"/libexec/qmlcachegen* "$QtX"/libexec

            # NOTE: This is required for macdeployqt.
            mv "$Qt"/libexec/qmlimportscanner "$QtX"/libexec

            mv "$Qt"/plugins/tls/lib*.dylib "$QtX"/plugins/tls

            rm -f "$QtX"/plugins/tls/*debug*
        fi

        mv "$Qt"/plugins/platforms/libq*.dylib    "$QtX"/plugins/platforms
        mv "$Qt"/plugins/imageformats/libq*.dylib "$QtX"/plugins/imageformats

        #------------------------------------------------------------------------------------------

        rm -f "$QtX"/plugins/platforms/*debug*
        rm -f "$QtX"/plugins/imageformats/*debug*

        find "$QtX"/lib -name "*_debug*" -delete

    elif [ $1 = "iOS" ]; then

        mkdirQt "plugins/platforms/darwin"
        mkdirQt "plugins/iconengines"
        mkdirQt "plugins/qmltooling"

        if [ $qt = "qt5" ]; then

            mkdirQt "plugins/bearer"
            mkdirQt "plugins/audio"
            mkdirQt "plugins/playlistformats"

            mv "$Qt"/bin/moc*             "$QtX"/bin
            mv "$Qt"/bin/rcc*             "$QtX"/bin
            mv "$Qt"/bin/qmlcachegen*     "$QtX"/bin
            mv "$Qt"/bin/qmlimportscanner "$QtX"/bin

            # NOTE iOS: We need .a and .prl files.
            moveMobile plugins/mediaservice/lib*.*     plugins/mediaservice
            moveMobile plugins/bearer/libq*.*          plugins/bearer
            moveMobile plugins/audio/libq*.*           plugins/audio
            moveMobile plugins/playlistformats/libq*.* plugins/playlistformats

            rm -f "$QtX"/plugins/mediaservice/*debug*
            rm -f "$QtX"/plugins/bearer/*debug*
            rm -f "$QtX"/plugins/audio/*debug*
            rm -f "$QtX"/plugins/playlistformats/*debug*
        else
            mkdirQt "plugins/networkinformation"
            mkdirQt "plugins/tls"

            QtBase="$QtX/macos"

            bin="macos/bin"

            libexec="macos/libexec"

            mkdir -p "$QtBase/libexec"

            mv "$Qt/$bin"/qsb* "$QtBase/bin"

            mv "$Qt/$libexec"/moc*             "$QtBase/libexec"
            mv "$Qt/$libexec"/rcc*             "$QtBase/libexec"
            mv "$Qt/$libexec"/qmlcachegen*     "$QtBase/libexec"
            mv "$Qt/$libexec"/qmlimportscanner "$QtBase/libexec"

            # NOTE iOS: We need .a and .prl files.
            moveMobile plugins/networkinformation/libq*.* plugins/networkinformation
            moveMobile plugins/tls/libq*.*                plugins/tls
        fi

        # NOTE iOS: We need .a and .prl files.
        moveMobile plugins/platforms/libq*.*        plugins/platforms
        moveMobile plugins/platforms/darwin/libq*.* plugins/platforms/darwin
        moveMobile plugins/imageformats/libq*.*     plugins/imageformats
        moveMobile plugins/iconengines/libq*.*      plugins/iconengines
        moveMobile plugins/qmltooling/libq*.*       plugins/qmltooling

        #------------------------------------------------------------------------------------------

        if [ $qt = "qt6" ]; then

            find "$QtX"/macOS/lib -name "*_debug*" -delete

            QtX="$QtX/ios"

            #--------------------------------------------------------------------------------------
            # NOTE Qt6: We update target_qt otherwise mkspecs are not found.

            expression='s!HostPrefix=../../!HostPrefix=../..//macos/g!'

            apply expression "$QtX"/bin/target_qt.conf
        fi

        rm -f "$QtX"/plugins/platforms/*debug*
        rm -f "$QtX"/plugins/platforms/darwin/*debug*
        rm -f "$QtX"/plugins/imageformats/*debug*
        rm -f "$QtX"/plugins/iconengines/*debug*
        # NOTE: We want to keep the 'debug' files for qmltooling

        rm "$QtX"/lib/*debug*

    elif [ $platform = "linux64" ]; then

        mkdir -p "$QtX"/plugins/iconengines
        mkdir -p "$QtX"/plugins/xcbglintegrations

        if [ $qt = "qt5" ]; then

            mv "$Qt"/bin/moc*         "$QtX"/bin
            mv "$Qt"/bin/rcc*         "$QtX"/bin
            mv "$Qt"/bin/qmlcachegen* "$QtX"/bin

            mv "$Qt"/plugins/mediaservice/lib*.so "$QtX"/plugins/mediaservice
        else
            mkdir -p "$QtX"/libexec

            mv "$Qt"/bin/qsb* "$QtX"/bin

            mv "$Qt"/libexec/moc*         "$QtX"/libexec
            mv "$Qt"/libexec/rcc*         "$QtX"/libexec
            mv "$Qt"/libexec/qmlcachegen* "$QtX"/libexec

            mv "$Qt"/plugins/tls/lib*.so "$QtX"/plugins/tls
        fi

        mv "$Qt"/plugins/platforms/libq*.so         "$QtX"/plugins/platforms
        mv "$Qt"/plugins/imageformats/libq*.so      "$QtX"/plugins/imageformats
        mv "$Qt"/plugins/iconengines/libq*.so       "$QtX"/plugins/iconengines
        mv "$Qt"/plugins/xcbglintegrations/libq*.so "$QtX"/plugins/xcbglintegrations

        #------------------------------------------------------------------------------------------
        # NOTE: linuxdeployqt is useful to package applications.

        echo ""
        echo "DOWNLOADING linuxdeployqt"
        echo $linuxdeployqt_url

        linuxdeployqt="$QtX"/bin/linuxdeployqt

        curl -L -o "$linuxdeployqt" $linuxdeployqt_url

        chmod +x "$linuxdeployqt"

    elif [ $1 = "android" ]; then

        moveMobile "jar" "."
        moveMobile "src" "."

        if [ $qt = "qt5" ]; then

            mkdir -p "$QtX"/plugins/bearer
            # NOTE: This is required by the multimedia module for VideoOutput.
            mkdir -p "$QtX"/plugins/video/videonode

            mv "$Qt"/bin/moc*             "$QtX"/bin
            mv "$Qt"/bin/rcc*             "$QtX"/bin
            mv "$Qt"/bin/qmlcachegen*     "$QtX"/bin
            mv "$Qt"/bin/qmlimportscanner "$QtX"/bin

            mv "$Qt"/bin/androiddeployqt "$QtX"/bin

            mv "$Qt"/plugins/mediaservice/lib*.so    "$QtX"/plugins/mediaservice
            mv "$Qt"/plugins/bearer/lib*.so          "$QtX"/plugins/bearer
            mv "$Qt"/plugins/video/videonode/lib*.so "$QtX"/plugins/video/videonode
        else
            QtBase="$QtX/gcc_64"

            bin="gcc_64/bin"

            libexec="gcc_64/libexec"

            mkdir -p "$QtBase/libexec"

            mv "$Qt/$bin"/qsb* "$QtBase/bin"

            mv "$Qt/$libexec"/moc*             "$QtBase/libexec"
            mv "$Qt/$libexec"/rcc*             "$QtBase/libexec"
            mv "$Qt/$libexec"/qmlcachegen*     "$QtBase/libexec"
            mv "$Qt/$libexec"/qmlimportscanner "$QtBase/libexec"

            mv "$Qt/$bin"/androiddeployqt "$QtBase/bin"

            moveMobile "plugins/tls/lib*.so" "plugins/tls"

            #--------------------------------------------------------------------------------------
            # NOTE Qt6: We update target_qt otherwise mkspecs are not found.

            expression='s!HostPrefix=../../!HostPrefix=../..//gcc_64/g!'

            apply $expression "$QtX"/android_armv7/target_qt.conf
            apply $expression "$QtX"/android_arm64_v8a/target_qt.conf
            apply $expression "$QtX"/android_x86/target_qt.conf
            apply $expression "$QtX"/android_x86_64/target_qt.conf
        fi

        moveMobile "plugins/platforms/lib*.so"    "plugins/platforms"
        moveMobile "plugins/imageformats/lib*.so" "plugins/imageformats"
    fi

    rm -rf Qt
fi

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

        path="$MinGW"/mingw32
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

    if [ $platform = "win32" ]; then

        ssl="ssl/openssl-$SSL_versionC/x86/bin"
    else
        ssl="ssl/openssl-$SSL_versionC/x64/bin"
    fi

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

    copySsl armeabi-v7a "$path"
    copySsl arm64-v8a   "$path"
    copySsl x86         "$path"
    copySsl x86_64      "$path"

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

elif [ $1 = "iOS" ]; then

    echo ""
    echo "DOWNLOADING VLC"
    echo $VLC_url

    curl -L -o VLC.tar.xz $VLC_url

    mkdir -p "$VLC"

    tar -xf VLC.tar.xz -C "$VLC"

    rm VLC.tar.xz

    path="$VLC/MobileVLCKit-binary"

    mv "$path"/MobileVLCKit.xcframework/* "$VLC"

    rm -rf "$path"

    # NOTE: Copying the headers in the root folder.
    cp -r "$VLC"/ios-arm64_armv7_armv7s/MobileVLCKit.framework/Headers "$VLC"/include

elif [ $platform = "linux64" ]; then

    sh snap.sh linux vlc

    rm -rf "$VLC"/snap

elif [ $1 = "android" ]; then

    echo ""
    echo "DOWNLOADING VLC"
    echo $VLC_url_android

    curl --retry 3 -L -o VLC.zip $VLC_url_android

    mkdir -p "$VLC"

    unzip -q VLC.zip -d"VLC"

    rm VLC.zip

    extractVlc armeabi-v7a
    extractVlc arm64-v8a
    extractVlc x86
    extractVlc x86_64

    rm -rf VLC
fi

if [ $platform = "linux64" -o $1 = "android" ]; then

    echo ""
    echo "DOWNLOADING VLC sources"
    echo $VLC_url

    curl -L -o VLC.7z $VLC_url

    7z x VLC.7z -o"$VLC" > /dev/null

    rm VLC.7z

    path="$VLC/vlc-$VLC_version"

    mv "$path"/sdk/include "$VLC"

    rm -rf "$path"
fi

#--------------------------------------------------------------------------------------------------
# libtorrent
#--------------------------------------------------------------------------------------------------

if [ $1 != "iOS" ]; then

    # NOTE/qt4: We have a specific libtorrent-linux32 build for ubuntu:18.04.
    if [ $qt = "qt4" -a $platform = "linux32" ]; then

        artifact=libtorrent-$name-$qt
    else
        artifact=libtorrent-$name
    fi

    echo ""
    echo "ARTIFACT $artifact"
    echo $libtorrent_url

    libtorrent_url=$(getSource $libtorrent_url $artifact)

    echo ""
    echo "DOWNLOADING libtorrent"
    echo $libtorrent_url

    curl --retry 3 -L -o libtorrent.zip $libtorrent_url

    unzip -q libtorrent.zip

    rm libtorrent.zip

    unzip -q $artifact/libtorrent.zip -d "$external"

    rm -rf $artifact
fi

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

    path="$JDK/jdk-$JDK_version"

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

    #----------------------------------------------------------------------------------------------
    # NOTE NDK 22: We add SDK 31 support to avoid random crashes with libtorrent on the NDK 23.
    #              https://github.com/arvidn/libtorrent/issues/7181
    # UPDATE: This is fixed by copying the specific libc++_shared provided with libVLC. Providing
    #         another one seems to cause random crashes.

    #path="$NDK_versionA/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib"

    #linkNdk "$path/arm-linux-androideabi"
    #linkNdk "$path/aarch64-linux-android"
    #linkNdk "$path/i686-linux-android"
    #linkNdk "$path/x86_64-linux-android"

    #----------------------------------------------------------------------------------------------

    cd -
fi

#--------------------------------------------------------------------------------------------------
# Sky
#--------------------------------------------------------------------------------------------------

if [ $os = "mobile" ]; then

    if [ $1 = "iOS" ]; then

        artifact="Sky-macOS-$qt"
    else
        artifact="Sky-linux64-$qt"
    fi

    echo ""
    echo "ARTIFACT $artifact"
    echo $Sky_url

    Sky_url=$(getSource $Sky_url $artifact)

    echo ""
    echo "DOWNLOADING Sky"
    echo $Sky_url

    curl --retry 3 -L -o Sky.zip $Sky_url

    mkdir -p "$Sky"

    unzip -q Sky.zip -d "$Sky"

    rm Sky.zip

    path="$Sky/$artifact"

    unzip -q "$path"/Sky.zip -d "$Sky"

    rm -rf "$path"
fi
