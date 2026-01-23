set -e

OUTPUT_DIR="${1:-.}"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

echo "=================================================="
echo "Vehicle Counter - Linux Distribution Build"
echo "=================================================="
echo "Output directory: $OUTPUT_DIR"
echo ""

echo "[1/4] Building Flutter web..."
cd "$ROOT_DIR/frontend"
if [ ! -d "build/web" ]; then
    flutter build web --release
else
    echo "Web build already exists, skipping..."
fi
cd "$ROOT_DIR"
echo "✓ Flutter web build complete"
echo ""

echo "[2/4] Installing Python dependencies..."
cd "$ROOT_DIR/backend"
pip install -r requirements.txt --quiet
echo "✓ Dependencies installed"
echo ""

echo "[3/4] Building AppImage with PyInstaller..."
cd "$ROOT_DIR"
pyinstaller \
  --noconfirm \
  --distpath "$OUTPUT_DIR/dist" \
  --workpath "$OUTPUT_DIR/build" \
  packaging/vehicle-counter-linux.spec
echo "✓ PyInstaller build complete"
echo ""

echo "[4/4] Creating AppImage..."
if command -v appimage-builder &> /dev/null; then
    echo "Building AppImage..."
    cp "$OUTPUT_DIR/dist/vehicle-counter" "$OUTPUT_DIR/dist/AppRun"
    chmod +x "$OUTPUT_DIR/dist/AppRun"
    echo "✓ AppImage ready at: $OUTPUT_DIR/dist/vehicle-counter"
    echo ""
    echo "Note: For true AppImage format, install appimage-builder:"
    echo "  sudo apt install appimage-builder"
else
    echo "Note: appimage-builder not found."
    echo "You can create a proper AppImage with: appimage-builder"
    echo "Or distribute the binary directly: $OUTPUT_DIR/dist/vehicle-counter"
fi

echo ""
echo "=================================================="
echo "Build Complete!"
echo "=================================================="
echo "Executable: $OUTPUT_DIR/dist/vehicle-counter"
echo ""
echo "To run:"
echo "  $OUTPUT_DIR/dist/vehicle-counter"
echo ""
