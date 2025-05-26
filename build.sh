#!/bin/bash

# Exit on error
set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}Starting build process...${NC}"

# Create build directories if they don't exist
mkdir -p build/web

# Backup custom files if they exist
if [ -f "build/web/index.html" ]; then
    echo -e "${BLUE}Backing up custom index.html...${NC}"
    cp build/web/index.html /tmp/index.html
fi

if [ -f "build/web/server.py" ]; then
    echo -e "${BLUE}Backing up server.py...${NC}"
    cp build/web/server.py /tmp/server.py
fi

# Clean build directory contents (but keep the directory)
echo -e "${BLUE}Cleaning build directory...${NC}"
rm -rf build/web/*
mkdir -p build/web

# Restore custom files if they existed
if [ -f "/tmp/index.html" ]; then
    echo -e "${BLUE}Restoring custom index.html...${NC}"
    mv /tmp/index.html build/web/index.html
fi

if [ -f "/tmp/server.py" ]; then
    echo -e "${BLUE}Restoring server.py...${NC}"
    mv /tmp/server.py build/web/server.py
fi

# Remove old game.love if it exists
if [ -f "build/game.love" ]; then
    echo -e "${BLUE}Removing old game.love...${NC}"
    rm build/game.love
fi

# Create game.love
echo -e "${BLUE}Creating game.love...${NC}"
cd /home/shawkwaive/src/repos/love/TimeIsHoney
zip -9 -r build/game.love . -x "*.git*" "*.DS_Store" "build/*" "build.sh" "README.md" "*.love"

# Build web version
echo -e "${BLUE}Building web version...${NC}"
cd /home/shawkwaive/src/repos/love/TimeIsHoney
love.js -c -t "Time Is Honey" -m 94371840 build/game.love build/web

# Create itch.io zip
echo -e "${BLUE}Creating itch.io package...${NC}"
cd /home/shawkwaive/src/repos/love/TimeIsHoney/build/web
rm -f ../time-is-honey-web.zip
zip -9 -r ../time-is-honey-web.zip game.data game.js index.html love.js love.wasm theme/ server.py

echo -e "${GREEN}Build complete!${NC}"
echo -e "${GREEN}Game.love: build/game.love${NC}"
echo -e "${GREEN}Web build: build/web/${NC}"
echo -e "${GREEN}itch.io package: build/time-is-honey-web.zip${NC}" 