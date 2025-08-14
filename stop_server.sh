#!/bin/bash

# C64GPT Server Stop Script

echo "🛑 Stopping C64GPT servers..."
pkill -f PetsponderDaemon

echo "⏳ Waiting for cleanup..."
sleep 2

echo "✅ Server stopped"
