#!/bin/bash

# C64GPT Server Management Script

echo "🔄 Stopping any existing C64GPT servers..."
pkill -f PetsponderDaemon

echo "⏳ Waiting for cleanup..."
sleep 2

echo "🚀 Starting C64GPT Telnet Server..."
swift run PetsponderDaemon
