#!/bin/bash

# Script to help set up hosts file entry for Memo system

echo "🔧 Memo System - Hosts File Setup Helper"
echo ""

# Get the current machine's OS
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="Linux"
    HOSTS_FILE="/etc/hosts"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macOS"
    HOSTS_FILE="/etc/hosts"
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    OS="Windows"
    HOSTS_FILE="/c/Windows/System32/drivers/etc/hosts"
else
    OS="Unknown"
fi

echo "Detected OS: $OS"
echo ""

# Get Ubuntu server IP
read -p "Enter your Ubuntu server IP address: " SERVER_IP

# Validate IP format (basic check)
if [[ ! $SERVER_IP =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    echo "❌ Invalid IP address format"
    exit 1
fi

echo ""
echo "📝 Adding entry to hosts file..."

# Check if entry already exists
if grep -q "memo" "$HOSTS_FILE" 2>/dev/null; then
    echo "⚠️  'memo' entry already exists in hosts file"
    echo "Current entry:"
    grep "memo" "$HOSTS_FILE"
    echo ""
    read -p "Do you want to replace it? (y/n): " REPLACE
    if [[ $REPLACE == "y" || $REPLACE == "Y" ]]; then
        # Remove existing entry
        if [[ "$OS" == "macOS" || "$OS" == "Linux" ]]; then
            sudo sed -i.bak '/memo/d' "$HOSTS_FILE"
        fi
    else
        echo "Keeping existing entry"
        exit 0
    fi
fi

# Add new entry
echo "Adding: $SERVER_IP memo"

if [[ "$OS" == "Windows" ]]; then
    echo ""
    echo "For Windows, please manually add this line to:"
    echo "C:\\Windows\\System32\\drivers\\etc\\hosts"
    echo ""
    echo "$SERVER_IP memo"
    echo ""
    echo "You'll need to run your text editor as Administrator"
elif [[ "$OS" == "macOS" || "$OS" == "Linux" ]]; then
    echo "$SERVER_IP memo" | sudo tee -a "$HOSTS_FILE" > /dev/null
    echo "✅ Entry added successfully!"
else
    echo "❌ Unsupported OS. Please manually add this line to your hosts file:"
    echo "$SERVER_IP memo"
fi

echo ""
echo "🧪 Testing connection..."
if ping -c 1 memo > /dev/null 2>&1; then
    echo "✅ 'memo' hostname is resolving correctly"
else
    echo "❌ 'memo' hostname is not resolving. Please check:"
    echo "   1. Hosts file entry was added correctly"
    echo "   2. Ubuntu server is running and accessible"
    echo "   3. No firewall blocking the connection"
fi

echo ""
echo "🎉 Setup complete! You should now be able to access:"
echo "   - Memo System: http://memo:3001"
echo "   - API: http://memo:8080"