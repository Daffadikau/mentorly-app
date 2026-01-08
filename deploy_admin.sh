#!/bin/bash

# 🚀 Deploy Admin Dashboard Script
# This script deploys ONLY admin dashboard to Firebase Hosting (no Flutter app)

set -e  # Exit on error

echo "🎯 Starting admin dashboard deployment..."
echo ""

# Step 1: Copy admin files
echo "📋 Step 1: Copying admin files to admin_web..."
mkdir -p admin_web
cp web/admin.html admin_web/
cp web/admin_register.html admin_web/

if [ -f "admin_web/admin.html" ] && [ -f "admin_web/admin_register.html" ]; then
    echo "✅ Admin files copied successfully!"
    echo "   - admin.html"
    echo "   - admin_register.html"
else
    echo "❌ Failed to copy admin files!"
    exit 1
fi

echo ""

# Step 2: Deploy database rules (optional)
read -p "🔒 Deploy database rules? (y/n): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🔒 Step 2: Deploying database rules..."
    firebase deploy --only database
    if [ $? -eq 0 ]; then
        echo "✅ Database rules deployed!"
    else
        echo "⚠️  Database rules deployment failed (continuing anyway)..."
    fi
fi

echo ""

# Step 3: Deploy hosting
echo "🌐 Step 3: Deploying admin dashboard to Firebase Hosting..."
firebase deploy --only hosting

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 =================================="
    echo "🎉 DEPLOYMENT SUCCESSFUL!"
    echo "🎉 =================================="
    echo ""
    echo "📍 Your admin dashboard is now live at:"
    echo ""
    echo "   🔗 Dashboard:     https://mentorly-66d07.web.app/admin.html"
    echo "   🔗 Registration:  https://mentorly-66d07.web.app/admin_register.html"
    echo ""
    echo "💡 Next steps:"
    echo "   1. Open admin_register.html to create admin account"
    echo "   2. Login to dashboard using username/password"
    echo ""
else
    echo ""
    echo "❌ Deployment failed!"
    exit 1
fi
