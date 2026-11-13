#!/bin/bash
# Build MyDock v2.9.11 (fat arm64 + arm64e) trên macOS với Xcode/Apple ld64.
# Chạy trên GitHub Actions (macos runner) hoặc máy Mac có Xcode.
# Apple ld64 tự tạo LC_DYLD_CHAINED_FIXUPS đúng chuẩn cho arm64e,
# thứ mà lld trên Linux không làm được (đó là lý do bản fat build bằng
# lld bị crash khi tiêm vào app hệ thống arm64e như Ghi chú).
set -euo pipefail

SRC="MyDock-v2.9.11-clean-source.m"
OUT="MyDock-v2.9.11-fat-macos.dylib"

echo "=== Xcode / SDK ==="
xcodebuild -version
SDK="$(xcrun --sdk iphoneos --show-sdk-path)"
echo "SDK: $SDK"

echo "=== Build fat dylib (arm64 + arm64e) ==="
xcrun --sdk iphoneos clang \
  -arch arm64 -arch arm64e \
  -isysroot "$SDK" \
  -miphoneos-version-min=16.0 \
  -fobjc-arc -O2 \
  -dynamiclib \
  -install_name "@rpath/MyDock.dylib" \
  -Xlinker -rpath -Xlinker /var/jb/Library/Frameworks \
  -Xlinker -rpath -Xlinker /var/jb/usr/lib \
  -Xlinker -rpath -Xlinker "@loader_path/.jbroot/Library/Frameworks" \
  -Xlinker -rpath -Xlinker "@loader_path/.jbroot/usr/lib" \
  -F "$PWD" \
  -framework CydiaSubstrate \
  -framework Foundation -framework UIKit \
  -framework CoreFoundation -framework CoreGraphics \
  -framework NaturalLanguage \
  "$SRC" -o "$OUT"

echo "=== Verify ==="
ls -la "$OUT"
lipo -info "$OUT"
echo "--- arm64e slice load commands (phai co LC_DYLD_CHAINED_FIXUPS) ---"
lipo -extract arm64e "$OUT" -output /tmp/mydock-arm64e-check.dylib
otool -l /tmp/mydock-arm64e-check.dylib | grep -E "LC_DYLD_CHAINED_FIXUPS|LC_DYLD_INFO" || echo "KHONG TIM THAY LC_DYLD_* (loi)"
echo "--- arm64 slice load commands ---"
lipo -extract arm64 "$OUT" -output /tmp/mydock-arm64-check.dylib
otool -l /tmp/mydock-arm64-check.dylib | grep -E "LC_DYLD_CHAINED_FIXUPS|LC_DYLD_INFO" || echo "KHONG TIM THAY LC_DYLD_* (loi)"
echo "=== OK: $OUT ==="
