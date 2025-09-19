#!/bin/bash

PORT=$1
sudo kill -9 $(sudo lsof -t -i:$PORT)
