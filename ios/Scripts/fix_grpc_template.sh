#!/bin/bash

# Try gRPC-C++ first
CPP_PATH=$(find Pods -name "basic_seq.h" -path "*/gRPC-C++/*" | head -n 1)
CORE_PATH=$(find Pods -name "basic_seq.h" -path "*/gRPC-Core/*" | head -n 1)

PATCHED=0

for FILE in "$CPP_PATH" "$CORE_PATH"; do
  if [ -n "$FILE" ] && grep -q 'Traits::template CallSeqFactory' "$FILE"; then
    echo "Patching $FILE..."
    cp "$FILE" "${FILE}.bak"
    sed -i '' 's/Traits::template CallSeqFactory/Traits::CallSeqFactory/g' "$FILE"
    echo "✅ Patch applied to $FILE"
    PATCHED=1
  fi
done

if [ $PATCHED -eq 0 ]; then
  echo "❌ No patchable files found or already patched."
fi
