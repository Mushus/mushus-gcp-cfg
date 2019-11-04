#!/bin/bash

SCRIPT_DIR=$(cd $(dirname $0); pwd)

git -C ${SCRIPT_DIR} fetch origin master
git reset --hard origin/master