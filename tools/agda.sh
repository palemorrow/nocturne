#!/bin/sh
set -eu

version=2.8.0
archive=.deps/agda-$version.tar.xz
checksum=824081b8dcbe431289a50ac6bd83e451f390c51c3884ac7a8c4a5c0df2632faf
mkdir -p .deps/bin
if ! test -x .deps/bin/agda || ! test "$(.deps/bin/agda --numeric-version)" = "$version"; then
  curl --fail --location --silent --show-error \
    "https://github.com/agda/agda/releases/download/v$version/Agda-v$version-linux.tar.xz" \
    --output "$archive"
  echo "$checksum  $archive" | sha256sum --check -
  tar -xJf "$archive" -C .deps/bin
  rm "$archive"
fi
.deps/bin/agda --setup
