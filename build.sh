#!/usr/bin/env bash

set -xe


cmake -S macOS/ -B obj.macOS -G Ninja
cmake --build obj.macOS --config Release --clean-first

cmake -S iOS/ -B obj.iOS -G Ninja
cmake --build obj.iOS --config Release --clean-first
