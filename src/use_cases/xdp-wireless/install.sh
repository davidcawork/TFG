#!/bin/bash

git submodule update --init
sudo apt install clang llvm libelf-dev gcc-multilib
sudo apt install linux-tools-$(uname -r)
sudo apt install linux-headers-$(uname -r)
sudo apt install linux-tools-common linux-tools-generic

