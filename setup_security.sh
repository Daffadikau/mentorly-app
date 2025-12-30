#!/bin/bash

echo "🔐 Mentorly Security Setup"
echo "=========================="
echo ""

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed. Please install Flutter first."
    exit 1
fi

echo "✅ Flutter found"
echo ""

# Install Flutter dependencies
echo "📦 Installing Flutter dependencies..."
flutter pub get

if [ $? -eq 0 ]; then
    echo "✅ Flutter dependencies installed"
else
    echo "❌ Failed to install Flutter dependencies"
    exit 1
fi

echo ""

# Create .env file if it doesn't exist
if [ ! -f ".env" ]; then
    echo "⚙️  Creating .env file from template..."
    cp .env.example .env
    
    # Generate secrets
    JWT_SECRET=$(openssl rand -base64 32)
    ENCRYPTION_KEY=$(openssl rand -base64 32)
    
    # Update .env with generated secrets (macOS compatible)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s|JWT_SECRET=.*|JWT_SECRET=$JWT_SECRET|" .env
        sed -i '' "s|ENCRYPTION_KEY=.*|ENCRYPTION_KEY=$ENCRYPTION_KEY|" .env
    else
        sed -i "s|JWT_SECRET=.*|JWT_SECRET=$JWT_SECRET|" .env
        sed -i "s|ENCRYPTION_KEY=.*|ENCRYPTION_KEY=$ENCRYPTION_KEY|" .env
    fi
    
    echo "✅ .env file created with generated secrets"
    echo "⚠️  Please review and update other values in .env"
else
    echo "ℹ️  .env file already exists, skipping..."
fi

echo ""

# Run security audit
echo "🔍 Running security audit..."
./security_audit.sh

echo ""
echo "=========================="
echo "✅ Security setup complete!"
echo "=========================="
echo ""
echo "📖 Next steps:"
echo "1. Review and update .env file with your configuration"
echo "2. Read SECURITY_GUIDE.md for implementation details"
echo "3. Update your code to use SecureSessionManager and SecureApiClient"
echo "4. Configure certificate pinning before production deployment"
echo "5. Set up PHP SecurityMiddleware in your backend"
echo ""
echo "📚 Documentation:"
echo "- SECURITY_GUIDE.md - Complete implementation guide"
echo "- SECURITY_IMPLEMENTATION.md - Quick reference"
echo "- lib/security/auth_example.dart - Code examples"
echo ""
echo "🚀 Ready to run: flutter run"
