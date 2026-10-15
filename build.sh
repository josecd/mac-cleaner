#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "🔨 Compilando MacCleaner..."
swift build -c release

echo "📦 Empaquetando MacCleaner.app..."
mkdir -p MacCleaner.app/Contents/MacOS
cp .build/release/MacCleaner MacCleaner.app/Contents/MacOS/
chmod +x MacCleaner.app/Contents/MacOS/MacCleaner

echo "✨ Listo! MacCleaner.app se encuentra en $SCRIPT_DIR/MacCleaner.app"
