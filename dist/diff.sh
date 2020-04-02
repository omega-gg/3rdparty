#!/bin/sh
set -e

echo "--- status ---"
cd status
git diff

echo "--- 3rdparty ---"
cd ../3rdparty
git diff

echo "--- Sky ---"
cd ../Sky
git diff

echo "--- HelloConsole ---"
cd ../HelloConsole
git diff

echo "--- HelloSky ---"
cd ../HelloSky
git diff

echo "--- MotionBox ---"
cd ../MotionBox
git diff

echo "--- backend ---"
cd ../backend
git diff

echo "--- Qt ---"
cd ../Qt
git diff

echo "--- VLC ---"
cd ../VLC
git diff

echo "--- libtorrent ---"
cd ../libtorrent
git diff

echo "--- omega ---"
cd ../omega
git diff

echo "--- launcher ---"
cd ../launcher
git diff

echo "--- docker ---"
cd ../docker
git diff

echo "--- VBML ---"
cd ../VBML
git diff

echo "--- devlogs ---"
cd ../bunjee/devlogs
git diff

echo "--- QuickWindow ---"
cd ../QuickWindow
git diff

cd ../..
