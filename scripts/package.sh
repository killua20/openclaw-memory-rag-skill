#!/bin/bash
# Package Memory RAG System as a installable archive

set -e

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_DIR="${1:-$SKILL_DIR}"
SKILL_NAME="memory-rag-system"
VERSION="$(date +%Y%m%d)"

echo "📦 Packaging Memory RAG System..."
echo "   Source: $SKILL_DIR"
echo "   Output: $OUTPUT_DIR/${SKILL_NAME}-${VERSION}.tar.gz"
echo ""

# Create temp directory
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Copy files
cp -r "$SKILL_DIR"/* "$TEMP_DIR/"

# Create tarball
cd "$(dirname "$TEMP_DIR")"
tar -czf "$OUTPUT_DIR/${SKILL_NAME}-${VERSION}.tar.gz" -C "$TEMP_DIR" .

echo "✅ Packaged: $OUTPUT_DIR/${SKILL_NAME}-${VERSION}.tar.gz"
echo ""
echo "To install:"
echo "  tar -xzf ${SKILL_NAME}-${VERSION}.tar.gz -C ~/.openclaw/skills/"
echo "  # Or use: bash scripts/setup.sh"
