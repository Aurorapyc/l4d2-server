#!/bin/bash

SERVER_DIR="/home/server-file"
cd "$SERVER_DIR"

echo "=========================================="
echo "Launch Left 4 Dead 2 Dedicated Server"
echo "Path: $SERVER_DIR"
echo "Time: $(date)"
echo "=========================================="

./srcds_run \
    -game left4dead2 \
    -insecure \
    +hostport 27015 \
    -condebug \
    +map c1m2_streets \
    +exec server.cfg \
    -nomaster \
    -tickrate 100 \
    +maxplayers 9
