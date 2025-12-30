#!/bin/bash

# ==============================================
# Mentorly Security Audit Script
# Run this regularly to check for security issues
# ==============================================

echo "🔍 Starting Mentorly Security Audit..."
echo "========================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
WARNINGS=0
ERRORS=0
PASSED=0

# ==============================================
# 1. Check for exposed secrets
# ==============================================
echo "📁 Checking for exposed secrets..."

if [ -f ".env" ]; then
    if git ls-files --error-unmatch .env > /dev/null 2>&1; then
        echo -e "${RED}❌ ERROR: .env file is tracked by git!${NC}"
        ((ERRORS++))
    else
        echo -e "${GREEN}✅ .env is not tracked by git${NC}"
        ((PASSED++))
    fi
else
    echo -e "${YELLOW}⚠️  WARNING: .env file not found${NC}"
    ((WARNINGS++))
fi

# Check for hardcoded secrets in code
echo "Checking for hardcoded secrets in Dart files..."
if grep -r "password.*=.*['\"].*['\"]" lib/ --include="*.dart" | grep -v "password.*=.*TextEditingController" > /dev/null; then
    echo -e "${YELLOW}⚠️  WARNING: Possible hardcoded passwords found in Dart files${NC}"
    ((WARNINGS++))
else
    echo -e "${GREEN}✅ No hardcoded passwords found in Dart files${NC}"
    ((PASSED++))
fi

# ==============================================
# 2. Check Flutter dependencies
# ==============================================
echo ""
echo "📦 Checking Flutter dependencies..."

flutter pub outdated > /tmp/flutter_outdated.txt 2>&1
if grep -q "newer versions available" /tmp/flutter_outdated.txt; then
    echo -e "${YELLOW}⚠️  WARNING: Some packages have updates available${NC}"
    echo "Run: flutter pub upgrade --major-versions"
    ((WARNINGS++))
else
    echo -e "${GREEN}✅ All packages are up to date${NC}"
    ((PASSED++))
fi

# ==============================================
# 3. Check for insecure storage usage
# ==============================================
echo ""
echo "💾 Checking for insecure storage patterns..."

if grep -r "SharedPreferences.*setString.*token\|SharedPreferences.*setString.*password" lib/ --include="*.dart" | grep -v "// SECURE:" > /dev/null; then
    echo -e "${RED}❌ ERROR: Insecure storage of sensitive data detected!${NC}"
    echo "Use flutter_secure_storage instead of SharedPreferences for tokens/passwords"
    ((ERRORS++))
else
    echo -e "${GREEN}✅ No insecure storage patterns detected${NC}"
    ((PASSED++))
fi

# ==============================================
# 4. Check for HTTP usage
# ==============================================
echo ""
echo "🔒 Checking for insecure HTTP connections..."

if grep -r "http://" lib/ --include="*.dart" | grep -v "localhost\|10.0.2.2\|127.0.0.1" | grep -v "//" > /dev/null; then
    echo -e "${RED}❌ ERROR: Insecure HTTP URLs found!${NC}"
    echo "All production URLs should use HTTPS"
    ((ERRORS++))
else
    echo -e "${GREEN}✅ No insecure HTTP URLs in production code${NC}"
    ((PASSED++))
fi

# ==============================================
# 5. Check for SQL injection vulnerabilities
# ==============================================
echo ""
echo "💉 Checking for SQL injection patterns..."

if grep -r "\$.*SELECT\|\$.*INSERT\|\$.*UPDATE\|\$.*DELETE" PHPMailer/ --include="*.php" 2>/dev/null | grep -v "prepare\|PDO" > /dev/null; then
    echo -e "${RED}❌ ERROR: Possible SQL injection vulnerability found!${NC}"
    echo "Use prepared statements for all database queries"
    ((ERRORS++))
else
    echo -e "${GREEN}✅ No SQL injection patterns detected${NC}"
    ((PASSED++))
fi

# ==============================================
# 6. Check for debug mode in production files
# ==============================================
echo ""
echo "🐛 Checking for debug flags..."

if grep -r "kDebugMode.*=.*true\|APP_DEBUG.*=.*true" lib/ --include="*.dart" > /dev/null; then
    echo -e "${YELLOW}⚠️  WARNING: Debug mode flags found${NC}"
    echo "Ensure debug mode is disabled in production builds"
    ((WARNINGS++))
else
    echo -e "${GREEN}✅ No debug mode issues found${NC}"
    ((PASSED++))
fi

# ==============================================
# 7. Check file permissions
# ==============================================
echo ""
echo "🔐 Checking file permissions..."

if [ -f ".env" ]; then
    PERMS=$(stat -f "%A" .env 2>/dev/null || stat -c "%a" .env 2>/dev/null)
    if [ "$PERMS" != "600" ] && [ "$PERMS" != "400" ]; then
        echo -e "${YELLOW}⚠️  WARNING: .env file has loose permissions ($PERMS)${NC}"
        echo "Run: chmod 600 .env"
        ((WARNINGS++))
    else
        echo -e "${GREEN}✅ .env file has secure permissions${NC}"
        ((PASSED++))
    fi
fi

# ==============================================
# 8. Check for certificate pinning configuration
# ==============================================
echo ""
echo "📜 Checking certificate pinning..."

if grep -r "_productionFingerprints.*=.*\[\]" lib/security/ --include="*.dart" > /dev/null; then
    echo -e "${YELLOW}⚠️  WARNING: Certificate pinning not configured${NC}"
    echo "Add production certificate fingerprints to certificate_pinning.dart"
    ((WARNINGS++))
else
    echo -e "${GREEN}✅ Certificate pinning configuration found${NC}"
    ((PASSED++))
fi

# ==============================================
# 9. Check Android security configuration
# ==============================================
echo ""
echo "🤖 Checking Android security..."

if [ -f "android/app/src/main/AndroidManifest.xml" ]; then
    if grep -q "android:usesCleartextTraffic=\"true\"" android/app/src/main/AndroidManifest.xml; then
        echo -e "${RED}❌ ERROR: Cleartext traffic is enabled in Android!${NC}"
        echo "This allows unencrypted HTTP connections"
        ((ERRORS++))
    else
        echo -e "${GREEN}✅ Cleartext traffic is disabled${NC}"
        ((PASSED++))
    fi
fi

# ==============================================
# 10. Check for logging of sensitive data
# ==============================================
echo ""
echo "📝 Checking for sensitive data in logs..."

if grep -r "print.*password\|print.*token\|debugPrint.*password\|debugPrint.*token" lib/ --include="*.dart" | grep -v "// SAFE:" > /dev/null; then
    echo -e "${YELLOW}⚠️  WARNING: Possible logging of sensitive data${NC}"
    echo "Never log passwords, tokens, or PII"
    ((WARNINGS++))
else
    echo -e "${GREEN}✅ No sensitive data logging detected${NC}"
    ((PASSED++))
fi

# ==============================================
# Summary
# ==============================================
echo ""
echo "========================================"
echo "📊 Security Audit Summary"
echo "========================================"
echo -e "${GREEN}✅ Passed: $PASSED${NC}"
echo -e "${YELLOW}⚠️  Warnings: $WARNINGS${NC}"
echo -e "${RED}❌ Errors: $ERRORS${NC}"
echo ""

if [ $ERRORS -gt 0 ]; then
    echo -e "${RED}🔴 Security audit FAILED! Please fix the errors above.${NC}"
    exit 1
elif [ $WARNINGS -gt 0 ]; then
    echo -e "${YELLOW}🟡 Security audit completed with warnings.${NC}"
    exit 0
else
    echo -e "${GREEN}🟢 Security audit PASSED! No issues found.${NC}"
    exit 0
fi
