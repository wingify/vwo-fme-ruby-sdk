#!/bin/bash
set -e

echo "Building VWO FME Ruby SDK..."
export SDK_BRAND="vwo"
gem build vwo-fme-ruby-sdk.gemspec -o vwo-fme-ruby-sdk.gem

echo ""
echo "Building Wingify FME Ruby SDK..."
export SDK_BRAND="wingify"
gem build vwo-fme-ruby-sdk.gemspec -o wingify-fme-ruby-sdk.gem

echo ""
echo "Done! Generated:"
ls -lh *.gem
