#!/bin/sh
set -e

echo "--- status ---"
cd status
git pull

echo "--- 3rdparty ---"
cd ../3rdparty
git pull

echo "--- Sky ---"
cd ../Sky
git pull

echo "--- HelloConsole ---"
cd ../HelloConsole
git pull

echo "--- HelloSky ---"
cd ../HelloSky
git pull

echo "--- MotionBox ---"
cd ../MotionBox
git pull

echo "--- backend ---"
cd ../backend
git pull

echo "--- Qt ---"
cd ../Qt
git pull

echo "--- VLC ---"
cd ../VLC
git pull

echo "--- libtorrent ---"
cd ../libtorrent
git pull

echo "--- omega ---"
cd ../omega
git pull

echo "--- launcher ---"
cd ../launcher
git pull

echo "--- docker ---"
cd ../docker
git pull

echo "--- VBML ---"
cd ../VBML
git pull

echo "--- devlogs ---"
cd ../bunjee/devlogs
git pull

echo "--- QuickWindow ---"
cd ../QuickWindow
git pull

cd ../..
