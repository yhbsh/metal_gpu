#!/usr/bin/env bash

set -xe

cmake -S macOS/ -B obj/macOS -G Ninja
cmake -S iOS/ -B obj/iOS -G Ninja
