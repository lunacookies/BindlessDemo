#!/bin/sh

set -e

clang-format -i ./*.m ./*.metal

buildDirectory="build"

rm -rf "$buildDirectory"
mkdir -p "$buildDirectory/BindlessDemo.app/Contents"
mkdir -p "$buildDirectory/BindlessDemo.app/Contents/Resources"
mkdir -p "$buildDirectory/BindlessDemo.app/Contents/MacOS"

cp "Info.plist" "$buildDirectory/BindlessDemo.app/Contents/Info.plist"

clang -fobjc-arc -fmodules -o "$buildDirectory/BindlessDemo.app/Contents/MacOS/BindlessDemo" ./*.m
xcrun metal -o "$buildDirectory/BindlessDemo.app/Contents/Resources/default.metallib" ./*.metal
