#!/bin/sh
set -e

#--------------------------------------------------------------------------------------------------
# Settings
#--------------------------------------------------------------------------------------------------

Qt4_version="4.8.7"
Qt5_version="5.12.3"

VLC_version="3.0.6"

libtorrent_version="1.2.2"

Boost_version="1.71.0"

#--------------------------------------------------------------------------------------------------
# Linux

lib32="/usr/lib/i386-linux-gnu"
lib64="/usr/lib/x86_64-linux-gnu"

Qt5_version_linux="5.9.5"

#--------------------------------------------------------------------------------------------------
# Ubuntu

QtWebkit_version_ubuntu="4.10.2"

VLC_version_ubuntu="5.6.0"

libvlccore_version_ubuntu="9.0.0"

libtorrent_version_ubuntu="9.0.0"

Boost_version_ubuntu="1.65.1"

#--------------------------------------------------------------------------------------------------

X11_ubuntu="libx11-dev libxi-dev libxinerama-dev libxrandr-dev libxcursor-dev libfontconfig-dev "\
"libaudio2"

Qt4_ubuntu="qt4-default libqtwebkit-dev openssl"

Qt5_ubuntu="qt5-default qtbase5-private-dev qtdeclarative5-private-dev libqt5xmlpatterns5-dev "\
"libqt5svg5-dev libqt5x11extras5-dev qml-module-qtquick-controls"

VLC_ubuntu="libvlc-dev vlc"

libtorrent_ubuntu="libtorrent-rasterbar-dev"

Boost_ubuntu="libboost-all-dev"

tools_ubuntu="git"

#--------------------------------------------------------------------------------------------------
# Syntax
#--------------------------------------------------------------------------------------------------

if [ $# != 1 -a $# != 2 ] || [ $1 != "linux" ] || [ $# = 2 -a "$2" != "deploy" ]; then

    echo "Usage: install <linux> [uninstall]>"

    exit 1
fi

#--------------------------------------------------------------------------------------------------
# Configuration
#--------------------------------------------------------------------------------------------------

external="$1"

if [ -d "${lib64}" ]; then

    lib="$lib64"
else
    lib="$lib32"
fi

Qt5_version="$Qt5_version_linux"

QtWebkit_version="$QtWebkit_version_ubuntu"

VLC_version="$VLC_version_ubuntu"

libvlccore_version="$libvlccore_version_ubuntu"

libtorrent_version="$libtorrent_version_ubuntu"

Boost_version="$Boost_version_ubuntu"

#----------------------------------------------------------------------------------------------

X11_linux="$X11_ubuntu"

Qt4_linux="$Qt4_ubuntu"
Qt5_linux="$Qt5_ubuntu"

VLC_linux="$VLC_ubuntu"

libtorrent_linux="$libtorrent_ubuntu"

Boost_linux="$Boost_ubuntu"

tools_linux="$tools_ubuntu"

#----------------------------------------------------------------------------------------------

Qt4="$external/Qt/$Qt4_version"

Qt4_name="qt-everywhere-opensource-src-$Qt4_version"

Qt4_archive="$Qt4_name.tar.gz"

Qt4_sources="http://download.qt.io/archive/qt/4.8/$Qt4_version/$Qt4_archive"

Qt5="$external/Qt/$Qt5_version"

VLC="$external/VLC/$VLC_version"

libtorrent="$external/libtorrent/$libtorrent_version"

Boost="$external/Boost/$Boost_version"

#--------------------------------------------------------------------------------------------------
# Install
#--------------------------------------------------------------------------------------------------

if [ "$2" = "uninstall" ]; then

    echo "UNINSTALLING X11"

    sudo apt-get remove -y $X11_linux

    echo ""
    echo "UNINSTALLING Qt4"

    sudo apt-get remove -y $Qt4_linux

    echo ""
    echo "UNINSTALLING Qt5"

    sudo apt-get remove -y $Qt5_linux

    echo ""
    echo "UNINSTALLING VLC"

    sudo apt-get remove -y $VLC_linux

    echo ""
    echo "UNINSTALLING libtorrent"

    sudo apt-get remove -y $libtorrent_linux

    echo ""
    echo "UNINSTALLING Boost"

    sudo apt-get remove -y $Boost_linux

    echo ""
    echo "UNINSTALLING TOOLS"

    sudo apt-get remove -y $tools_linux

    exit 0
fi

echo "INSTALLING X11"

sudo apt-get install -y $X11_linux

echo ""
echo "INSTALLING Qt4"

sudo apt-get install -y $Qt4_linux

echo ""
echo "INSTALLING Qt5"

sudo apt-get install -y $Qt5_linux

echo ""
echo "INSTALLING VLC"

sudo apt-get install -y $VLC_linux

echo ""
echo "INSTALLING libtorrent"

sudo apt-get install -y $libtorrent_linux

echo ""
echo "INSTALLING Boost"

sudo apt-get install -y $Boost_linux

echo ""
echo "INSTALLING TOOLS"

sudo apt-get install -y $tools_linux

#--------------------------------------------------------------------------------------------------
# Deploy
#--------------------------------------------------------------------------------------------------

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

echo ""
echo "DEPLOYING Qt5"

mkdir -p "$Qt5"/lib

mkdir -p "$Qt5"/plugins/platforms
mkdir -p "$Qt5"/plugins/imageformats
mkdir -p "$Qt5"/plugins/xcbglintegrations

mkdir -p "$Qt5"/qml/QtQuick.2

sudo cp "$lib"/libQt5Core.so.$Qt5_version        "$Qt5"/lib/libQt5Core.so.5
sudo cp "$lib"/libQt5Gui.so.$Qt5_version         "$Qt5"/lib/libQt5Gui.so.5
sudo cp "$lib"/libQt5Network.so.$Qt5_version     "$Qt5"/lib/libQt5Network.so.5
sudo cp "$lib"/libQt5OpenGL.so.$Qt5_version      "$Qt5"/lib/libQt5OpenGL.so.5
sudo cp "$lib"/libQt5Qml.so.$Qt5_version         "$Qt5"/lib/libQt5Qml.so.5
sudo cp "$lib"/libQt5Quick.so.$Qt5_version       "$Qt5"/lib/libQt5Quick.so.5
sudo cp "$lib"/libQt5Svg.so.$Qt5_version         "$Qt5"/lib/libQt5Svg.so.5
sudo cp "$lib"/libQt5Widgets.so.$Qt5_version     "$Qt5"/lib/libQt5Widgets.so.5
sudo cp "$lib"/libQt5Xml.so.$Qt5_version         "$Qt5"/lib/libQt5Xml.so.5
sudo cp "$lib"/libQt5XmlPatterns.so.$Qt5_version "$Qt5"/lib/libQt5XmlPatterns.so.5
sudo cp "$lib"/libQt5XcbQpa.so.$Qt5_version      "$Qt5"/lib/libQt5XcbQpa.so.5
sudo cp "$lib"/libQt5DBus.so.$Qt5_version        "$Qt5"/lib/libQt5DBus.so.5

sudo cp "$lib"/qt5/plugins/platforms/libqxcb.so "$Qt5"/plugins/platforms

sudo cp "$lib"/qt5/plugins/imageformats/libqsvg.so  "$Qt5"/plugins/imageformats
sudo cp "$lib"/qt5/plugins/imageformats/libqjpeg.so "$Qt5"/plugins/imageformats

sudo cp "$lib"/qt5/plugins/xcbglintegrations/libqxcb-egl-integration.so \
        "$Qt5"/plugins/xcbglintegrations

sudo cp "$lib"/qt5/plugins/xcbglintegrations/libqxcb-glx-integration.so \
        "$Qt5"/plugins/xcbglintegrations

sudo cp "$lib"/qt5/qml/QtQuick.2/libqtquick2plugin.so "$Qt5"/qml/QtQuick.2
sudo cp "$lib"/qt5/qml/QtQuick.2/qmldir               "$Qt5"/qml/QtQuick.2

echo ""
echo "DEPLOYING VLC"

mkdir -p "$VLC"

sudo cp "$lib"/libvlc.so.$VLC_version            "$VLC"/libvlc.so.5
sudo cp "$lib"/libvlccore.so.$libvlccore_version "$VLC"/libvlccore.so.8

sudo cp -r "$lib"/vlc/plugins "$VLC"

echo ""
echo "DEPLOYING libtorrent"

mkdir -p "$libtorrent"

sudo cp "$lib"/libtorrent-rasterbar.so.$libtorrent_version "$libtorrent"/libtorrent-rasterbar.so.9

echo ""
echo "DEPLOYING Boost"

mkdir -p "$Boost"

sudo cp "$lib"/libboost_system.so.$Boost_version "$Boost"
sudo cp "$lib"/libboost_random.so.$Boost_version "$Boost"
sudo cp "$lib"/libboost_chrono.so.$Boost_version "$Boost"
