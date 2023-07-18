#!/usr/bin/env bash

tart delete ventura-temp
tart clone ventura-ci-vanilla-base ventura-temp
tart run ventura-temp --net-softnet &
sleep 10
tart ip ventura-temp
sleep 500
tart stop ventura-temp
tart delete ventura-temp
