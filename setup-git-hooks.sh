#!/bin/bash
# Setup script to install git hooks for password security

set -e

echo "Installing git hooks for password security..."

# Create .git/hooks directory if it doesn't exist
mkdir -p .git/hooks

# Copy pre-commit hook
cp .githooks/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit

echo "✓ Git hooks installed successfully"
echo ""
echo "The pre-commit hook will now check for:"
echo "  - Password logging in Go files"
echo "  - Password logging in Dart files"
echo "  - Hardcoded secrets"
echo ""
echo "To bypass the hook (not recommended), use: git commit --no-verify"
