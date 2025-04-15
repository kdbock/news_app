#!/bin/bash

# Fix for BoringSSL module map issue
echo "Fixing BoringSSL module map issues..."

PODS_ROOT="$PODS_ROOT"
if [ -z "$PODS_ROOT" ]; then
  PODS_ROOT="$SRCROOT/Pods"
fi

# Create directory structure if it doesn't exist
mkdir -p "$PODS_ROOT/Target Support Files/BoringSSLRPC"

# Create the missing module map
cat > "$PODS_ROOT/Target Support Files/BoringSSLRPC/BoringSSLRPC.modulemap" << 'MODULEMAP'
framework module openssl_grpc {
  umbrella header "openssl_grpc.h"
  export *
  module * { export * }
}
MODULEMAP

echo "BoringSSL module map fix completed"
