#!/bin/bash

# Path to your control file
CONTROL_FILE="build/debian/control"

# Extract values dynamically from the control file
PACKAGE_NAME=$(grep '^Package:' "$CONTROL_FILE" | cut -d' ' -f2)
VERSION=$(grep '^Version:' "$CONTROL_FILE" | cut -d' ' -f2)
ARCH=$(grep '^Architecture:' "$CONTROL_FILE" | cut -d' ' -f2)

# Verify we actually got the data
if [ -z "$PACKAGE_NAME" ] || [ -z "$VERSION" ]; then
    echo "Error: Could not parse Package name or Version from $CONTROL_FILE"
    exit 1
fi

# Stores the debian package tree for the build
STAGING="build/debian/staging"

# Deb package will be placed here after the build
OUTPUT_DIR="build/debian/staging"

# Path to documentation in staging
DOC_DIR="$STAGING/usr/share/doc/$PACKAGE_NAME"

echo "--- Starting Debian Build Process for $PACKAGE_NAME ($VERSION) ---"

# Clean up existing staging area
echo "[1/6] Cleaning staging area..."
rm -rf "$STAGING"
mkdir -p "$STAGING/DEBIAN"
mkdir -p "$STAGING/usr/bin"
mkdir -p "$STAGING/etc/incul/launcher-config/desktop-directories"
mkdir -p "$DOC_DIR"

# Copy control file to staging
echo "[2/6] Copying control files..."
cp build/debian/control "$STAGING/DEBIAN/"

# Copy rules file to staging
echo "[3/6] Copying rules files..."
cp build/debian/rules "$STAGING/DEBIAN/"

# Copy and Compress Changelog
echo "[4/6] Staging changelog..."
cp build/debian/changelog "$DOC_DIR/changelog.Debian"
gzip -n -9 "$DOC_DIR/changelog.Debian"

# Copy Source Files to Staging
echo "[5/6] Staging source files..."

# Executables to /usr/bin
cp incul/* "$STAGING/usr/bin/"
chmod +x "$STAGING/usr/bin/"*

# Configuration and Menu files to /etc
cp config_files/config.yaml "$STAGING/etc/incul/"
cp menu_files/xfce-applications.menu "$STAGING/etc/incul/launcher-config/"
cp menu_files/system-tools.directory "$STAGING/etc/incul/launcher-config/desktop-directories/"

# Build the package
echo "[6/6] Building .deb package..."

# Ensure package files are owned by root
dpkg-deb --build --root-owner-group "$STAGING" "$OUTPUT_DIR/${PACKAGE_NAME}_${VERSION}_${ARCH}.deb"

echo "--- Build Complete: $OUTPUT_DIR/${PACKAGE_NAME}_${VERSION}_${ARCH}.deb ---"