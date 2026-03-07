#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

APP_NAME="${APP_NAME:-TextEditor}"
BUNDLE_ID="${BUNDLE_ID:-com.brandon.texteditor}"
VERSION="${VERSION:-1.0}"
BUILD_NUMBER="${BUILD_NUMBER:-1}"
MINIMUM_SYSTEM_VERSION="${MINIMUM_SYSTEM_VERSION:-12.0}"
OUTPUT_DIR="${OUTPUT_DIR:-dist}"
RELEASE_DIR=".build/release"
APP_BUNDLE="${OUTPUT_DIR}/${APP_NAME}.app"
STAGE_DIR="${OUTPUT_DIR}/dmg"
DMG_PATH="${OUTPUT_DIR}/${APP_NAME}.dmg"
ICON_NAME="${ICON_NAME:-AppIcon}"
ICON_SOURCE="${ICON_SOURCE:-Sources/TextEditor/Resources/app_icon.png}"
ICON_PATH="${APP_BUNDLE}/Contents/Resources/${ICON_NAME}.icns"
ICON_INSET_PERCENT="${ICON_INSET_PERCENT:-0}"
ICONSET_DIR=""

cleanup() {
  if [[ -n "${ICONSET_DIR}" && -d "${ICONSET_DIR}" ]]; then
    rm -rf "${ICONSET_DIR}"
  fi
}

trap cleanup EXIT

create_icns_icon() {
  local source_png="$1"

  if [[ ! -f "$source_png" ]]; then
    echo "error: expected icon source at $source_png" >&2
    exit 1
  fi

  if ! command -v iconutil >/dev/null 2>&1; then
    echo "error: iconutil is required to build a macOS app icon" >&2
    exit 1
  fi

  ICONSET_DIR="$(mktemp -d "${TMPDIR:-/tmp}/${APP_NAME}.iconset.XXXXXX")"
  local iconset_path="${ICONSET_DIR}/${ICON_NAME}.iconset"
  local normalized_png="${ICONSET_DIR}/${ICON_NAME}.png"
  mkdir -p "$iconset_path"

  cat > "${ICONSET_DIR}/normalize_icon.swift" <<'SWIFT'
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let args = CommandLine.arguments
guard args.count == 5 else {
    fputs("usage: normalize_icon.swift <source> <output> <canvasSize> <insetPercent>\n", stderr)
    exit(1)
}

let sourceURL = URL(fileURLWithPath: args[1])
let outputURL = URL(fileURLWithPath: args[2])
guard let canvasSize = Int(args[3]), canvasSize > 0 else {
    fputs("error: canvasSize must be a positive integer\n", stderr)
    exit(1)
}
guard let insetPercent = Double(args[4]), insetPercent >= 0.0, insetPercent < 0.5 else {
    fputs("error: insetPercent must be >= 0 and < 0.5\n", stderr)
    exit(1)
}

guard let source = CGImageSourceCreateWithURL(sourceURL as CFURL, nil),
      let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
    fputs("error: unable to read icon source image\n", stderr)
    exit(1)
}

let width = image.width
let height = image.height
let bytesPerPixel = 4
let bitsPerComponent = 8
let bytesPerRow = width * bytesPerPixel
let colorSpace = CGColorSpaceCreateDeviceRGB()
let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
var data = [UInt8](repeating: 0, count: width * height * bytesPerPixel)

guard let scanContext = CGContext(
    data: &data,
    width: width,
    height: height,
    bitsPerComponent: bitsPerComponent,
    bytesPerRow: bytesPerRow,
    space: colorSpace,
    bitmapInfo: bitmapInfo
) else {
    fputs("error: unable to create scan context\n", stderr)
    exit(1)
}

scanContext.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
guard let renderedImage = scanContext.makeImage() else {
    fputs("error: unable to render icon image\n", stderr)
    exit(1)
}

var minX = width
var minY = height
var maxX = -1
var maxY = -1

for y in 0..<height {
    for x in 0..<width {
        let offset = y * bytesPerRow + x * bytesPerPixel
        let alpha = data[offset + 3]
        if alpha > 0 {
            minX = min(minX, x)
            minY = min(minY, y)
            maxX = max(maxX, x)
            maxY = max(maxY, y)
        }
    }
}

let cropRect: CGRect
if maxX >= 0, maxY >= 0 {
    cropRect = CGRect(
        x: minX,
        y: minY,
        width: maxX - minX + 1,
        height: maxY - minY + 1
    )
} else {
    cropRect = CGRect(x: 0, y: 0, width: width, height: height)
}

guard let trimmedImage = renderedImage.cropping(to: cropRect) else {
    fputs("error: unable to crop icon image\n", stderr)
    exit(1)
}

let canvas = CGFloat(canvasSize)
let inset = canvas * CGFloat(insetPercent)
let available = canvas - (inset * 2)
let destinationRect = CGRect(
    x: inset,
    y: inset,
    width: available,
    height: available
)

guard let outputContext = CGContext(
    data: nil,
    width: canvasSize,
    height: canvasSize,
    bitsPerComponent: bitsPerComponent,
    bytesPerRow: 0,
    space: colorSpace,
    bitmapInfo: bitmapInfo
) else {
    fputs("error: unable to create output context\n", stderr)
    exit(1)
}

outputContext.interpolationQuality = .high
outputContext.clear(CGRect(x: 0, y: 0, width: canvas, height: canvas))
outputContext.draw(trimmedImage, in: destinationRect)

guard let normalizedImage = outputContext.makeImage() else {
    fputs("error: unable to create normalized icon image\n", stderr)
    exit(1)
}

guard let destination = CGImageDestinationCreateWithURL(outputURL as CFURL, UTType.png.identifier as CFString, 1, nil) else {
    fputs("error: unable to create PNG destination\n", stderr)
    exit(1)
}

CGImageDestinationAddImage(destination, normalizedImage, nil)
if !CGImageDestinationFinalize(destination) {
    fputs("error: unable to write normalized icon image\n", stderr)
    exit(1)
}
SWIFT

  swift "${ICONSET_DIR}/normalize_icon.swift" "$source_png" "$normalized_png" "1024" "$ICON_INSET_PERCENT"

  local sizes=(16 32 128 256 512)
  for size in "${sizes[@]}"; do
    sips -z "$size" "$size" "$normalized_png" --out "${iconset_path}/icon_${size}x${size}.png" >/dev/null
    local retina_size=$((size * 2))
    sips -z "$retina_size" "$retina_size" "$normalized_png" --out "${iconset_path}/icon_${size}x${size}@2x.png" >/dev/null
  done

  iconutil -c icns "$iconset_path" -o "$ICON_PATH"
}

echo "Building release binary..."
swift build -c release

if [[ ! -x "${RELEASE_DIR}/${APP_NAME}" ]]; then
  echo "error: expected release binary at ${RELEASE_DIR}/${APP_NAME}" >&2
  exit 1
fi

echo "Preparing app bundle..."
rm -rf "$OUTPUT_DIR"
mkdir -p "${APP_BUNDLE}/Contents/MacOS" "${APP_BUNDLE}/Contents/Resources" "$STAGE_DIR"

cp "${RELEASE_DIR}/${APP_NAME}" "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"
chmod +x "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"

shopt -s nullglob
resource_bundles=("${RELEASE_DIR}"/*.bundle)
shopt -u nullglob

if [[ ${#resource_bundles[@]} -eq 0 ]]; then
  echo "error: no SwiftPM resource bundles were found in ${RELEASE_DIR}" >&2
  exit 1
fi

for bundle in "${resource_bundles[@]}"; do
  cp -R "$bundle" "${APP_BUNDLE}/Contents/Resources/"
done

create_icns_icon "$ICON_SOURCE"

cat > "${APP_BUNDLE}/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>${APP_NAME}</string>
  <key>CFBundleIdentifier</key>
  <string>${BUNDLE_ID}</string>
  <key>CFBundleIconFile</key>
  <string>${ICON_NAME}</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>${APP_NAME}</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>${VERSION}</string>
  <key>CFBundleVersion</key>
  <string>${BUILD_NUMBER}</string>
  <key>LSMinimumSystemVersion</key>
  <string>${MINIMUM_SYSTEM_VERSION}</string>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
PLIST

printf 'APPL????' > "${APP_BUNDLE}/Contents/PkgInfo"

ditto "${APP_BUNDLE}" "${STAGE_DIR}/${APP_NAME}.app"
ln -s /Applications "${STAGE_DIR}/Applications"

echo "Creating DMG..."
hdiutil create \
  -volname "${APP_NAME}" \
  -srcfolder "${STAGE_DIR}" \
  -ov \
  -format UDZO \
  "${DMG_PATH}" >/dev/null

rm -rf "${STAGE_DIR}"

echo "Created ${SCRIPT_DIR}/${DMG_PATH}"
