#!/usr/bin/env bash

set -e

pip3 install -r requirements.txt

echo Starting up API mock
./test/mocks/api.py > api.log 2>&1 &
sleep 1

exec "$@"
