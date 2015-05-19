#!/bin/sh

wd=$PWD

sleep 15

cassandra-cli --batch < $wd/travis/cassandra.bf
