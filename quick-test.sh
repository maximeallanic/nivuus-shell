#!/bin/bash
# Quick Shell Test
# ================

echo "🧪 Testing shell configuration..."

# Test 1: ZSH startup without errors
echo "1️⃣  Testing ZSH startup..."
zsh_output=$(zsh -i -c 'echo "ZSH_OK"' 2>&1)
if echo "$zsh_output" | grep -q "ZSH_OK" && ! echo "$zsh_output" | grep -q "error\|Error\|invalid\|parse error"; then
    echo "   ✅ ZSH starts cleanly"
else
    echo "   ❌ ZSH has startup errors:"
    echo "$zsh_output" | grep -E "error|Error|invalid|parse"
fi

# Test 2: Function availability
echo "2️⃣  Testing functions..."
if command -v smart_grep &>/dev/null; then
    echo "   ✅ smart_grep function available"
else
    echo "   ❌ smart_grep function missing"
fi

# Test 3: No cache corruption
echo "3️⃣  Testing cache integrity..."
if [ -f "$HOME/.antigen/init.zsh.zwc" ] && [ -r "$HOME/.antigen/init.zsh.zwc" ]; then
    echo "   ✅ Antigen cache is readable"
elif [ ! -f "$HOME/.antigen/init.zsh.zwc" ]; then
    echo "   ⚠️  Antigen cache not yet created (normal on first run)"
else
    echo "   ❌ Antigen cache is corrupted"
fi

# Test 4: Maintenance functions
echo "4️⃣  Testing maintenance..."
if command -v smart_maintenance &>/dev/null; then
    echo "   ✅ Maintenance functions available"
else
    echo "   ❌ Maintenance functions missing"
fi

echo ""
echo "🎯 Run './fix-zsh-cache.sh' if you see cache issues"
echo "🔧 Use 'envcheck' to validate .env files manually"
