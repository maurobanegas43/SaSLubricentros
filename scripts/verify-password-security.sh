#!/bin/bash
# Verification script to check password security compliance

set -e

echo "=========================================="
echo "Password Security Verification"
echo "=========================================="
echo ""

ERRORS=0
WARNINGS=0

# Check 1: Verify no password logging in Go files
echo "1. Checking Go files for password logging..."
if grep -r "log\..*[Pp]assword\|logger\..*[Pp]assword\|fmt\.Print.*[Pp]assword" backend/ --include="*.go" --exclude="*_test.go" 2>/dev/null; then
    echo "   ❌ FAIL: Password logging detected in Go files"
    ERRORS=$((ERRORS + 1))
else
    echo "   ✅ PASS: No password logging in Go files"
fi
echo ""

# Check 2: Verify no password logging in Dart files
echo "2. Checking Dart files for password logging..."
if grep -r "print.*[Pp]assword\|debugPrint.*[Pp]assword" mobile/lib/ --include="*.dart" 2>/dev/null; then
    echo "   ❌ FAIL: Password logging detected in Dart files"
    ERRORS=$((ERRORS + 1))
else
    echo "   ✅ PASS: No password logging in Dart files"
fi
echo ""

# Check 3: Verify database schema uses password_hash
echo "3. Checking database schema..."
if grep -q "password_hash" backend/migrations/001_initial_schema.sql; then
    echo "   ✅ PASS: Database uses password_hash column"
else
    echo "   ❌ FAIL: Database schema missing password_hash column"
    ERRORS=$((ERRORS + 1))
fi

if grep "password VARCHAR" backend/migrations/001_initial_schema.sql | grep -v "password_hash" 2>/dev/null; then
    echo "   ❌ FAIL: Database has plaintext password column"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# Check 4: Verify logging middleware exists
echo "4. Checking logging middleware..."
if [ -f "backend/internal/middleware/logging.go" ]; then
    echo "   ✅ PASS: Logging middleware exists"
    if grep -q "redactSensitiveFields" backend/internal/middleware/logging.go; then
        echo "   ✅ PASS: Middleware includes redaction logic"
    else
        echo "   ⚠️  WARNING: Middleware may not include redaction"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    echo "   ❌ FAIL: Logging middleware not found"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# Check 5: Verify secure logger exists
echo "5. Checking mobile secure logger..."
if [ -f "mobile/lib/utils/secure_logger.dart" ]; then
    echo "   ✅ PASS: SecureLogger exists"
    if grep -q "_redactSensitiveFields" mobile/lib/utils/secure_logger.dart; then
        echo "   ✅ PASS: SecureLogger includes redaction logic"
    else
        echo "   ⚠️  WARNING: SecureLogger may not include redaction"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    echo "   ❌ FAIL: SecureLogger not found"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# Check 6: Verify git hooks are installed
echo "6. Checking git hooks..."
if [ -f ".git/hooks/pre-commit" ]; then
    echo "   ✅ PASS: Pre-commit hook installed"
else
    echo "   ⚠️  WARNING: Pre-commit hook not installed"
    echo "   Run: ./setup-git-hooks.sh"
    WARNINGS=$((WARNINGS + 1))
fi
echo ""

# Check 7: Run backend security tests
echo "7. Running backend security tests..."
cd backend
if go test ./internal/middleware/... -run "TestPassword" -v > /dev/null 2>&1; then
    echo "   ✅ PASS: Backend security tests passed"
else
    echo "   ❌ FAIL: Backend security tests failed"
    ERRORS=$((ERRORS + 1))
fi
cd ..
echo ""

# Check 8: Run mobile security tests
echo "8. Running mobile security tests..."
cd mobile
if flutter test test/utils/secure_logger_test.dart > /dev/null 2>&1; then
    echo "   ✅ PASS: Mobile security tests passed"
else
    echo "   ❌ FAIL: Mobile security tests failed"
    ERRORS=$((ERRORS + 1))
fi
cd ..
echo ""

# Summary
echo "=========================================="
echo "Summary"
echo "=========================================="
echo "Errors: $ERRORS"
echo "Warnings: $WARNINGS"
echo ""

if [ $ERRORS -gt 0 ]; then
    echo "❌ VERIFICATION FAILED"
    echo "Fix the errors above before proceeding."
    exit 1
elif [ $WARNINGS -gt 0 ]; then
    echo "⚠️  VERIFICATION PASSED WITH WARNINGS"
    echo "Address the warnings above for complete security."
    exit 0
else
    echo "✅ VERIFICATION PASSED"
    echo "All password security measures are in place."
    exit 0
fi
