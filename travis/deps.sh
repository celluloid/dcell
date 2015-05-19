#!/bin/sh

wd=$PWD

sudo apt-get install zookeeperd

deb=$wd/travis/deb

sudo dpkg -i $deb/libsodium13_1.0.1-1_amd64.deb
sudo dpkg -i $deb/libsodium-dev_1.0.1-1_amd64.deb
sudo dpkg -i $deb/libzmq3_4.0.5+dfsg-3_amd64.deb
sudo dpkg -i $deb/libzmq3-dev_4.0.5+dfsg-3_amd64.deb
