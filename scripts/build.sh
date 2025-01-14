#!/usr/bin/env bash

set -xe

cmake --build obj/macOS --config Release --clean-first
cmake --build obj/iOS --config Release --clean-first
