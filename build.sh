#!/usr/bin/env bash

set -xe

cmake -S . -B obj -G Ninja
cmake --build obj
open obj/Main.app
