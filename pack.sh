#!/bin/bash
set -euo pipefail

ver="$1"

cd data
rm -rf clover.schema-$ver.zip
rm -rf clover.schema-build-$ver.zip
zip -5 clover.schema-$ver.zip *.yaml opencc/*
zip -5 clover.schema-build-$ver.zip *.yaml opencc/* build/*
cp clover.schema-build-$ver.zip ../build
