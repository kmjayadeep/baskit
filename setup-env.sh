#!/bin/bash
# Baskit Development Environment Setup
# Run this before each development session
#
# Usage: source ~/projects/baskit/setup-env.sh

export JAVA_HOME="/home/hermes/dev/jdk"
export ANDROID_HOME="/home/hermes/dev/android-sdk"
export PATH="/home/hermes/dev/bin:$JAVA_HOME/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$ANDROID_HOME/build-tools/36.0.0:$HOME/dev/cmake/bin:$HOME/dev/clang/bin:$HOME/flutter/bin:$HOME/flutter/bin/cache/dart-sdk/bin:$HOME/.hermes/tools/node-26.7.0-linux-x64/bin:$PATH"

echo "✅ Baskit development environment loaded"
echo "   Flutter: $(flutter --version 2>&1 | head -1)"
echo "   Java: $(java -version 2>&1 | head -1)"
echo "   Android SDK: $(ls $ANDROID_HOME/platforms/ 2>/dev/null | head -1)"
echo "   Clang: $(clang++ --version 2>&1 | head -1)"
echo "   CMake: $(cmake --version 2>&1 | head -1)"
