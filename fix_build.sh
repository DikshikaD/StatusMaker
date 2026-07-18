#!/bin/bash

echo "🧹 Cleaning Flutter build cache..."
flutter clean

echo "📦 Getting dependencies..."
flutter pub get

echo "🔨 Running pub get for Android..."
cd android
./gradlew clean
cd ..

echo "✅ Build cache cleaned! Try running: flutter run"
