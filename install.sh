#!/bin/sh
set -e

#--------------------------------------------------------------------------------------------------
# Settings
#--------------------------------------------------------------------------------------------------

Qt4_version="4.8.7"
Qt5_version="5.15.2"

SSL_version="1.1.1s"

VLC_version="3.0.18"

VLC_versionA="5.6.0"
VLC_versionB="5"

libvlccore_versionA="9.0.0"
libvlccore_versionB="9"

#libtorrent_version="2.0.9"

#Boost_version="1.78.0"

#--------------------------------------------------------------------------------------------------
# Linux

base32="/lib/i386-linux-gnu"
base64="/lib/x86_64-linux-gnu"

bin="/usr/bin"

lib32="/usr/lib/i386-linux-gnu"
lib64="/usr/lib/x86_64-linux-gnu"

share="/usr/share"

include32="/usr/include/i386-linux-gnu"
include64="/usr/include/x86_64-linux-gnu"

#--------------------------------------------------------------------------------------------------
# environment

qt="qt5"

#--------------------------------------------------------------------------------------------------
# Functions
#--------------------------------------------------------------------------------------------------

getOs()
{
    if [ "$(cat /etc/os-release | grep 18)" != "" ]; then

        echo "ubuntu18"
    else
        echo "ubuntu20"
    fi
}

#--------------------------------------------------------------------------------------------------
# Syntax
#--------------------------------------------------------------------------------------------------

if [ $# != 1 -a $# != 2 ] \
   || \
   [ $1 != "linux" ] || [ $# = 2 -a "$2" != "build" -a "$2" != "uninstall" ]; then

    echo "Usage: install <linux> [build | uninstall]"

    exit 1
fi

#--------------------------------------------------------------------------------------------------
# Configuration
#--------------------------------------------------------------------------------------------------

host=$(getOs)

external="$1"

if [ -d "${lib32}" ]; then

    platform="linux32"

    base="$base32"

    lib="$lib32"

    include="$include32"
else
    platform="linux64"

    base="$base64"

    lib="$lib64"

    include="$include64"
fi

#----------------------------------------------------------------------------------------------

libs="$external/lib"

Qt4="$external/Qt/$Qt4_version"

Qt4_name="qt-everywhere-opensource-src-$Qt4_version"

Qt4_archive="$Qt4_name.tar.gz"

#Qt4_sources="http://download.qt.io/archive/qt/4.8/$Qt4_version/$Qt4_archive"
#Qt4_sources="http://ftp1.nluug.nl/languages/qt/archive/qt/4.8/$Qt4_version/$Qt4_archive"
Qt4_sources="http://master.qt.io/archive/qt/4.8/$Qt4_version/$Qt4_archive"
#Qt4_sources="https://ftp.osuosl.org/pub/blfs/conglomeration/qt4/$Qt4_archive"

Qt5="$external/Qt/$Qt5_version"

SSL="$external/OpenSSL/$SSL_version"

VLC="$external/VLC/$VLC_version"

#libtorrent="$external/libtorrent/$libtorrent_version"

#Boost="$external/Boost/$Boost_version"

#--------------------------------------------------------------------------------------------------

if [ $host = "ubuntu18" ]; then

    Qt5_version="5.9.5"

    QtWebkit_version="4.10.2"

    #Boost_version="1.65.1"
else
    Qt5_version="5.12.8"

    QtWebkit_version="4.10.4"

    #Boost_version="1.78.0"
fi

libvlccore_version="$libvlccore_versionA"

#libtorrent_version="9.0.0"

#--------------------------------------------------------------------------------------------------

# NOTE: libpulse-dev and libgstreamer(s) are needed for libQt5Multimedia.
X11_linux="libx11-dev libxi-dev libxinerama-dev libxrandr-dev libxcursor-dev libfontconfig-dev "\
"libaudio2 libpulse-dev libgstreamer1.0-0 libgstreamer-plugins-base1.0-0"

if [ $qt != "qt4" ]; then

    X11_linux="$X11_linux libgl1-mesa-dev"
fi

Qt4_linux="qt4-default libqtwebkit-dev openssl"

Qt5_linux="qt5-default qtbase5-private-dev qtdeclarative5-private-dev qtmultimedia5-dev "\
"libqt5xmlpatterns5-dev libqt5svg5-dev libqt5x11extras5-dev libqt5multimedia5-plugins "\
"qml-module-qtquick2 qml-module-qtmultimedia"

if [ $platform = "linux32" ]; then

    VLC_linux="libvlc-dev vlc"

    # NOTE: patchelf does not exist on linux32.
    tools_linux="git"
else
    VLC_linux="vlc"

    tools_linux="git patchelf"
fi

#libtorrent_linux="libtorrent-rasterbar-dev"

#Boost_linux="libboost-all-dev"

#--------------------------------------------------------------------------------------------------
# Install
#--------------------------------------------------------------------------------------------------

sudo apt-get update

sudo apt-get install -y build-essential

if [ $host = "ubuntu20" ]; then

    # NOTE: Docker requires tzdata and keyboard-configuration.
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y tzdata keyboard-configuration locales

    # NOTE: Docker has no local set by default.
    sudo locale-gen en_US.UTF-8
fi

if [ "$2" = "uninstall" ]; then

    echo "UNINSTALLING X11"

    sudo apt-get remove -y $X11_linux

    if [ $qt = "qt4" ]; then

        echo ""
        echo "UNINSTALLING Qt4"

        sudo apt-get remove -y $Qt4_linux
    fi

    if [ $platform = "linux32" -a $qt = "qt5" ]; then

        echo ""
        echo "UNINSTALLING Qt5"

        sudo apt-get remove -y $Qt5_linux
    fi

    echo ""
    echo "UNINSTALLING VLC"

    if [ $platform = "linux32" ]; then

        sudo apt-get remove -y $VLC_linux
    fi

    #echo ""
    #echo "UNINSTALLING libtorrent"

    #sudo apt-get remove -y $libtorrent_linux

    #echo ""
    #echo "UNINSTALLING Boost"

    #sudo apt-get remove -y $Boost_linux

    echo ""
    echo "UNINSTALLING TOOLS"

    sudo apt-get remove -y $tools_linux

    exit 0
fi

echo "INSTALLING X11"

sudo apt-get install -y $X11_linux

if [ $qt = "qt4" ]; then

    echo ""
    echo "INSTALLING Qt4"

    # NOTE: Qt4 has been removed from Ubuntu 20.04 main repository.
    if [ $host = "ubuntu20" ]; then

        # NOTE: This is required for add-apt-repository.
        sudo apt-get install -y software-properties-common

        sudo add-apt-repository -y ppa:rock-core/qt4
    fi

    sudo apt-get install -y $Qt4_linux
fi

if [ $platform = "linux32" -a $qt = "qt5" ]; then

    echo ""
    echo "INSTALLING Qt5"

    sudo apt-get install -y $Qt5_linux
fi

echo ""
echo "INSTALLING VLC"

if [ $platform = "linux32" ]; then

    sudo apt-get install -y $VLC_linux
fi

#echo ""
#echo "INSTALLING libtorrent"

#sudo apt-get install -y $libtorrent_linux

#echo ""
#echo "INSTALLING Boost"

#sudo apt-get install -y $Boost_linux

echo ""
echo "INSTALLING TOOLS"

sudo apt-get install -y $tools_linux

#--------------------------------------------------------------------------------------------------
# Deploy
#--------------------------------------------------------------------------------------------------

if [ "$2" != "build" ]; then

    exit 0
fi

echo ""
echo "DEPLOYING lib(s)"

mkdir -p "$libs"

#sudo cp "$base"/libz.so.1 "$libs"

#if [ $host = "ubuntu18" ]; then
#
#    sudo cp "$lib"/libdouble-conversion.so.1 "$libs"
#else
#    sudo cp "$lib"/libdouble-conversion.so.3 "$libs"

    # NOTE: Required for Ubuntu 20.04.
    #sudo cp "$lib"/libpcre2-16.so.0 "$libs"
#fi

#sudo cp "$lib"/libpng16.so.16       "$libs"
#sudo cp "$lib"/libharfbuzz.so.0     "$libs"
#sudo cp "$lib"/libxcb-xinerama.so.0 "$libs"

if [ $qt = "qt4" ]; then

    echo ""
    echo "DEPLOYING Qt4"

    if [ ! -d "${Qt4}" ]; then

        mkdir -p "$Qt4"

        cd "$Qt4"

        curl -L -o "$Qt4_archive" "$Qt4_sources"

        tar -xf "$Qt4_archive"

        mv "$Qt4_name"/* .

        rm -rf "$Qt4_name"

        rm "$Qt4_archive"

        cd -
    fi

    mkdir -p "$Qt4"/plugins/imageformats

    sudo cp "$share"/qt4/bin/qmake "$Qt4"/bin
    sudo cp "$share"/qt4/bin/moc   "$Qt4"/bin/moc
    sudo cp "$share"/qt4/bin/rcc   "$Qt4"/bin/rcc

    sudo cp "$lib"/libQtCore.so.$Qt4_version        "$Qt4"/lib/libQtCore.so.4
    sudo cp "$lib"/libQtGui.so.$Qt4_version         "$Qt4"/lib/libQtGui.so.4
    sudo cp "$lib"/libQtDeclarative.so.$Qt4_version "$Qt4"/lib/libQtDeclarative.so.4
    sudo cp "$lib"/libQtNetwork.so.$Qt4_version     "$Qt4"/lib/libQtNetwork.so.4
    sudo cp "$lib"/libQtOpenGL.so.$Qt4_version      "$Qt4"/lib/libQtOpenGL.so.4
    sudo cp "$lib"/libQtScript.so.$Qt4_version      "$Qt4"/lib/libQtScript.so.4
    sudo cp "$lib"/libQtSql.so.$Qt4_version         "$Qt4"/lib/libQtSql.so.4
    sudo cp "$lib"/libQtSvg.so.$Qt4_version         "$Qt4"/lib/libQtSvg.so.4
    sudo cp "$lib"/libQtXml.so.$Qt4_version         "$Qt4"/lib/libQtXml.so.4
    sudo cp "$lib"/libQtXmlPatterns.so.$Qt4_version "$Qt4"/lib/libQtXmlPatterns.so.4

    sudo cp "$lib"/libQtWebKit.so.$QtWebkit_version "$Qt4"/lib/libQtWebKit.so.4

    sudo cp "$lib"/qt4/plugins/imageformats/libqsvg.so  "$Qt4"/plugins/imageformats
    sudo cp "$lib"/qt4/plugins/imageformats/libqjpeg.so "$Qt4"/plugins/imageformats
fi

if [ $platform = "linux32" -a $qt = "qt5" ]; then

    echo ""
    echo "DEPLOYING Qt5"

    mkdir -p "$Qt5"/bin
    mkdir -p "$Qt5"/lib
    mkdir -p "$Qt5"/include

    mkdir -p "$Qt5"/plugins/platforms
    mkdir -p "$Qt5"/plugins/imageformats
    mkdir -p "$Qt5"/plugins/mediaservice
    mkdir -p "$Qt5"/plugins/xcbglintegrations

    mkdir -p "$Qt5"/qml/QtQuick.2
    mkdir -p "$Qt5"/qml/QtMultimedia

    sudo cp -r "$include"/qt5/* "$Qt5"/include

    sudo cp "$bin"/qmake       "$Qt5"/bin
    sudo cp "$bin"/moc         "$Qt5"/bin
    sudo cp "$bin"/rcc         "$Qt5"/bin
    sudo cp "$bin"/qmlcachegen "$Qt5"/bin

    if [ $host = "ubuntu18" ]; then

        sudo cp "$lib"/libicudata.so.60 "$Qt5"/lib
        sudo cp "$lib"/libicui18n.so.60 "$Qt5"/lib
        sudo cp "$lib"/libicuuc.so.60   "$Qt5"/lib
    else
        sudo cp "$lib"/libicudata.so.66 "$Qt5"/lib
        sudo cp "$lib"/libicui18n.so.66 "$Qt5"/lib
        sudo cp "$lib"/libicuuc.so.66   "$Qt5"/lib
    fi

    sudo cp "$lib"/libQt5Core.so.$Qt5_version            "$Qt5"/lib/libQt5Core.so.5
    sudo cp "$lib"/libQt5Gui.so.$Qt5_version             "$Qt5"/lib/libQt5Gui.so.5
    sudo cp "$lib"/libQt5Network.so.$Qt5_version         "$Qt5"/lib/libQt5Network.so.5
    sudo cp "$lib"/libQt5OpenGL.so.$Qt5_version          "$Qt5"/lib/libQt5OpenGL.so.5
    sudo cp "$lib"/libQt5Qml.so.$Qt5_version             "$Qt5"/lib/libQt5Qml.so.5
    sudo cp "$lib"/libQt5Quick.so.$Qt5_version           "$Qt5"/lib/libQt5Quick.so.5
    sudo cp "$lib"/libQt5Svg.so.$Qt5_version             "$Qt5"/lib/libQt5Svg.so.5
    sudo cp "$lib"/libQt5Widgets.so.$Qt5_version         "$Qt5"/lib/libQt5Widgets.so.5
    sudo cp "$lib"/libQt5Xml.so.$Qt5_version             "$Qt5"/lib/libQt5Xml.so.5
    sudo cp "$lib"/libQt5XmlPatterns.so.$Qt5_version     "$Qt5"/lib/libQt5XmlPatterns.so.5
    sudo cp "$lib"/libQt5Multimedia.so.$Qt5_version      "$Qt5"/lib/libQt5Multimedia.so.5
    sudo cp "$lib"/libQt5MultimediaQuick.so.$Qt5_version "$Qt5"/lib/libQt5MultimediaQuick.so.5
    sudo cp "$lib"/libQt5XcbQpa.so.$Qt5_version          "$Qt5"/lib/libQt5XcbQpa.so.5
    sudo cp "$lib"/libQt5DBus.so.$Qt5_version            "$Qt5"/lib/libQt5DBus.so.5

    if [ -f "$lib"/libQt5QmlModels.so.$Qt5_version ]; then

        sudo cp "$lib"/libQt5QmlModels.so.$Qt5_version       "$Qt5"/lib/libQt5QmlModels.so.5
        sudo cp "$lib"/libQt5QmlWorkerScript.so.$Qt5_version "$Qt5"/lib/libQt5QmlWorkerScript.so.5
    fi

    sudo cp "$lib"/qt5/plugins/platforms/libqxcb.so "$Qt5"/plugins/platforms

    sudo cp "$lib"/qt5/plugins/imageformats/libqsvg.so  "$Qt5"/plugins/imageformats
    sudo cp "$lib"/qt5/plugins/imageformats/libqjpeg.so "$Qt5"/plugins/imageformats

    sudo cp "$lib"/qt5/plugins/mediaservice/libgstcamerabin.so "$Qt5"/plugins/mediaservice

    sudo cp "$lib"/qt5/plugins/xcbglintegrations/libqxcb-egl-integration.so \
            "$Qt5"/plugins/xcbglintegrations

    sudo cp "$lib"/qt5/plugins/xcbglintegrations/libqxcb-glx-integration.so \
            "$Qt5"/plugins/xcbglintegrations

    sudo cp "$lib"/qt5/qml/QtQuick.2/libqtquick2plugin.so "$Qt5"/qml/QtQuick.2
    sudo cp "$lib"/qt5/qml/QtQuick.2/qmldir               "$Qt5"/qml/QtQuick.2

    sudo cp "$lib"/qt5/qml/QtMultimedia/lib*multimedia*.so "$Qt5"/qml/QtMultimedia
    sudo cp "$lib"/qt5/qml/QtMultimedia/qmldir             "$Qt5"/qml/QtMultimedia
fi

echo ""
echo "DEPLOYING SSL"

mkdir -p "$SSL"

sudo cp "$lib"/libssl.so.1.1    "$SSL"
sudo cp "$lib"/libcrypto.so.1.1 "$SSL"

if [ $platform = "linux32" ]; then

    echo ""
    echo "DEPLOYING VLC"

    mkdir -p "$VLC"

    path="$lib"

    sudo cp "$path"/libvlc.so.$VLC_versionA            "$VLC"/libvlc.so.$VLC_versionB
    sudo cp "$path"/libvlccore.so.$libvlccore_versionA "$VLC"/libvlccore.so.$libvlccore_versionB

    sudo cp -r "$path"/vlc "$VLC"
fi

#echo ""
#echo "DEPLOYING libtorrent"

#mkdir -p "$libtorrent"

#sudo cp "$lib"/libtorrent-rasterbar.so.$libtorrent_version "$libtorrent"/libtorrent-rasterbar.so.9

#echo ""
#echo "DEPLOYING Boost"

#mkdir -p "$Boost"

#sudo cp "$lib"/libboost_system.so.$Boost_version "$Boost"
#sudo cp "$lib"/libboost_random.so.$Boost_version "$Boost"
#sudo cp "$lib"/libboost_chrono.so.$Boost_version "$Boost"
