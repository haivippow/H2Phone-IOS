#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || fail "Missing $1. See docs/build-install.md"; }

[[ "$(uname -s)" == Linux ]] || fail 'Run this script inside WSL2 Ubuntu or Linux.'
if grep -qi microsoft /proc/version 2>/dev/null; then
    grep -qi 'WSL2' /proc/sys/kernel/osrelease 2>/dev/null || fail 'WSL2 is required; this appears to be WSL1.'
fi

for tool in bash make git perl python3 dpkg-deb rsync; do need "$tool"; done
export THEOS="${THEOS:-$HOME/theos}"
[[ -f "$THEOS/makefiles/common.mk" ]] || fail "Theos missing at $THEOS. Install from https://theos.dev/docs/installation-linux"
[[ -f "$THEOS/makefiles/aggregate.mk" ]] || fail 'Theos aggregate.mk is missing.'

sdk_found=0
for sdk in "$THEOS"/sdks/iPhoneOS*.sdk; do
    [[ -d "$sdk" ]] || continue
    version="$(basename "$sdk")"
    version="${version#iPhoneOS}"
    version="${version%.sdk}"
    if python3 - "$version" <<'PY'
import sys
try:
    major, minor, *_ = [int(part) for part in sys.argv[1].split('.')]
    assert (major, minor) >= (16, 0)
except (ValueError, AssertionError):
    sys.exit(1)
PY
    then
        [[ -f "$sdk/System/Library/Frameworks/UIKit.framework/Headers/UIKit.h" ]] || continue
        sdk_found=1
        printf 'SDK: %s\n' "$sdk"
    fi
done
(( sdk_found )) || fail 'No iPhoneOS SDK >= 16.0 with UIKit headers in $THEOS/sdks. See docs/build-install.md'

if [[ ! -x "$THEOS/toolchain/linux/iphone/bin/clang" ]] && ! command -v clang >/dev/null 2>&1; then
    fail 'Theos iOS clang toolchain is missing. Re-run the official Theos installer.'
fi
if [[ ! -x "$THEOS/toolchain/linux/iphone/bin/ldid" ]] && ! command -v ldid >/dev/null 2>&1; then
    fail 'ldid signing tool is missing. Re-run the official Theos installer.'
fi

grep -Eq '^export THEOS_PACKAGE_SCHEME = rootless$' Makefile || fail 'Rootless scheme is not configured.'
grep -Eq '^export ARCHS = arm64 arm64e$' Makefile || fail 'Expected arm64 and arm64e app/tweak targets are not configured.'
grep -Eq '^export TARGET = iphone:clang:latest:16\.0$' Makefile || fail 'Expected iOS 16.0 deployment target is not configured.'

mkdir -p packages
marker="$(mktemp "$repo_root/packages/.build-start.XXXXXX")"
build_dir="$(mktemp -d "${TMPDIR:-/tmp}/h2changer-build.XXXXXX")"
trap 'rm -f -- "$marker"; rm -rf -- "$build_dir"' EXIT
rsync -r --exclude='.git/' --exclude='.theos/' --exclude='packages/' "$repo_root/" "$build_dir/"
printf 'Building rootless arm64/arm64e package...\n'
make -C "$build_dir" clean package FINALPACKAGE=1

shopt -s nullglob
for built_deb in "$build_dir"/packages/com.h2changer.ios_*.deb; do
    cp -- "$built_deb" "$repo_root/packages/"
done

deb="$(find "$repo_root/packages" -maxdepth 1 -type f -name 'com.h2changer.ios_*.deb' -newer "$marker" -print | sort | tail -n 1)"
[[ -n "$deb" && -s "$deb" ]] || fail 'Build finished without a new non-empty .deb in packages/.'
[[ "$(dpkg-deb -f "$deb" Package)" == com.h2changer.ios ]] || fail 'Unexpected package ID in .deb.'
[[ "$(dpkg-deb -f "$deb" Architecture)" == iphoneos-arm64 ]] || fail 'Package architecture is not rootless iphoneos-arm64.'
listing="$(dpkg-deb --contents "$deb")"
for expected in 'H2Changer.app/H2Changer' 'DeviceTest.app/DeviceTest' 'H2ChangerHook.dylib' 'H2ChangerHook.plist'; do
    grep -Fq "$expected" <<< "$listing" || fail "Missing $expected in .deb."
done
grep -Fq 'var/jb/' <<< "$listing" || fail 'Package does not contain rootless /var/jb paths.'
printf 'DEB_OK: %s\n' "$deb"
