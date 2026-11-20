#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE="$ROOT/.local-dependencies/whisper.cpp"
REVISION=2eeeba56e9edd762b4b38467bab96c2517163158
BUILD="$SOURCE/build-robey-macos"
OUTPUT="$SOURCE/build-apple/whisper.xcframework"
CMAKE="${ROBEY_VOICE_CMAKE:-$ROOT/.local-dependencies/tools/bin/cmake}"
ARCH="${ROBEY_VOICE_ARCH:-arm64}"
METAL="${ROBEY_VOICE_WHISPER_METAL:-ON}"
if [[ ! -d "$SOURCE/.git" ]]; then
    mkdir -p "$ROOT/.local-dependencies"
    git clone --no-checkout https://github.com/ggerganov/whisper.cpp.git "$SOURCE"
    git -C "$SOURCE" checkout --detach "$REVISION"
fi
[[ "$(git -C "$SOURCE" rev-parse HEAD)" == "$REVISION" ]] || { echo "whisper.cpp differs from pinned $REVISION; refusing silent update" >&2; exit 1; }
[[ -z "$(git -C "$SOURCE" status --porcelain --untracked-files=no)" ]] || { echo "Pinned native source has modifications" >&2; exit 1; }
if [[ -d "$OUTPUT" ]]; then
    [[ "$(cat "$OUTPUT/robey-build.txt")" == "$REVISION $ARCH metal=$METAL" ]] || { echo "Preserved native build does not match requested options" >&2; exit 1; }
    echo "Using preserved whisper.cpp $REVISION ($ARCH, Metal $METAL)"
    exit 0
fi
[[ -x "$CMAKE" ]] || CMAKE="$(command -v cmake || true)"
[[ -x "$CMAKE" ]] || { echo "CMake >=3.28 required: set ROBEY_VOICE_CMAKE or install in .local-dependencies/tools" >&2; exit 1; }
"$CMAKE" -S "$SOURCE" -B "$BUILD" -G 'Unix Makefiles' \
    -DCMAKE_BUILD_TYPE=Release -DCMAKE_OSX_ARCHITECTURES="$ARCH" -DCMAKE_OSX_DEPLOYMENT_TARGET=15.0 \
    -DBUILD_SHARED_LIBS=OFF -DWHISPER_BUILD_TESTS=OFF -DWHISPER_BUILD_EXAMPLES=ON -DWHISPER_BUILD_SERVER=OFF \
    -DWHISPER_COREML=ON -DWHISPER_COREML_ALLOW_FALLBACK=ON -DGGML_NATIVE=OFF -DGGML_OPENMP=OFF \
    -DGGML_METAL="$METAL" -DGGML_METAL_EMBED_LIBRARY=ON -DGGML_BLAS=ON
"$CMAKE" --build "$BUILD" --config Release --parallel "${ROBEY_VOICE_BUILD_JOBS:-4}"
FRAMEWORK="$BUILD/framework/whisper.framework"
mkdir -p "$FRAMEWORK/Versions/A/Headers" "$FRAMEWORK/Versions/A/Modules" "$FRAMEWORK/Versions/A/Resources"
ln -sfn A "$FRAMEWORK/Versions/Current"
for part in Headers Modules Resources whisper; do ln -sfn "Versions/Current/$part" "$FRAMEWORK/$part"; done
cp "$SOURCE/include/whisper.h" "$SOURCE"/ggml/include/*.h "$FRAMEWORK/Versions/A/Headers/"
cat > "$FRAMEWORK/Versions/A/Modules/module.modulemap" <<'EOF'
framework module whisper {
    umbrella header "whisper.h"
    link "c++"
    link framework "Accelerate"
    link framework "Metal"
    link framework "Foundation"
    link framework "CoreML"
    export *
}
EOF
cat > "$FRAMEWORK/Versions/A/Resources/Info.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>whisper</string>
<key>CFBundleIdentifier</key><string>org.ggml.whisper</string>
<key>CFBundleName</key><string>whisper</string>
<key>CFBundlePackageType</key><string>FMWK</string>
<key>CFBundleVersion</key><string>1.8.3</string>
<key>CFBundleShortVersionString</key><string>1.8.3</string>
<key>MinimumOSVersion</key><string>15.0</string>
</dict></plist>
EOF
LIBRARIES=()
while IFS= read -r library; do LIBRARIES+=("$library"); done < <(find "$BUILD/src" "$BUILD/ggml/src" -name '*.a' -type f | sort)
[[ "${#LIBRARIES[@]}" -gt 0 ]] || { echo "No native libraries built" >&2; exit 1; }
xcrun libtool -static -o "$BUILD/combined.a" "${LIBRARIES[@]}"
xcrun clang++ -dynamiclib -arch "$ARCH" -mmacosx-version-min=15.0 \
    -Wl,-force_load,"$BUILD/combined.a" -framework Foundation -framework Metal -framework Accelerate -framework CoreML \
    -install_name '@rpath/whisper.framework/Versions/Current/whisper' -o "$FRAMEWORK/Versions/A/whisper"
mkdir -p "$(dirname "$OUTPUT")"
xcodebuild -create-xcframework -framework "$FRAMEWORK" -output "$OUTPUT"
printf '%s\n' "$REVISION $ARCH metal=$METAL" > "$OUTPUT/robey-build.txt"
lipo -archs "$FRAMEWORK/Versions/A/whisper"
