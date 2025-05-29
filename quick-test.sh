#!/bin/bash
# ZSH Ultra Performance Config - Quick Test
# Simplified test script without interactive components

set -euo pipefail

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🧪 ZSH Ultra Performance Config - Quick Test${NC}"
echo "=============================================="

# Test 1: File structure
echo -n "Checking file structure... "
if [[ -f ".zshrc" && -d "config" && -f "install.sh" && -f "uninstall.sh" && -f "README.md" ]]; then
    echo -e "${GREEN}✅ OK${NC}"
else
    echo -e "${RED}❌ FAILED${NC}"
    exit 1
fi

# Test 2: Module files
echo -n "Checking module files... "
module_count=$(ls config/*.zsh 2>/dev/null | wc -l)
if [[ $module_count -eq 12 ]]; then
    echo -e "${GREEN}✅ OK (12 modules)${NC}"
else
    echo -e "${RED}❌ FAILED ($module_count modules found, expected 12)${NC}"
    exit 1
fi

# Test 3: ZSH syntax
echo -n "Checking ZSH syntax... "
syntax_errors=0

# Check main file
if ! zsh -n .zshrc 2>/dev/null; then
    syntax_errors=$((syntax_errors + 1))
fi

# Check modules
for file in config/*.zsh; do
    if ! zsh -n "$file" 2>/dev/null; then
        syntax_errors=$((syntax_errors + 1))
    fi
done

if [[ $syntax_errors -eq 0 ]]; then
    echo -e "${GREEN}✅ OK${NC}"
else
    echo -e "${RED}❌ FAILED ($syntax_errors syntax errors)${NC}"
    exit 1
fi

# Test 4: Script syntax
echo -n "Checking script syntax... "
if bash -n install.sh 2>/dev/null && bash -n uninstall.sh 2>/dev/null; then
    echo -e "${GREEN}✅ OK${NC}"
else
    echo -e "${RED}❌ FAILED${NC}"
    exit 1
fi

# Test 5: File sizes
echo -n "Checking file sizes... "
oversized_files=0
for file in config/*.zsh; do
    lines=$(wc -l < "$file")
    if [[ $lines -gt 200 ]]; then
        oversized_files=$((oversized_files + 1))
    fi
done

if [[ $oversized_files -eq 0 ]]; then
    echo -e "${GREEN}✅ OK${NC}"
else
    echo -e "${RED}❌ FAILED ($oversized_files files exceed 200 lines)${NC}"
    exit 1
fi

# Test 6: Executable permissions
echo -n "Checking permissions... "
if [[ -x "install.sh" && -x "uninstall.sh" && -x "test.sh" ]]; then
    echo -e "${GREEN}✅ OK${NC}"
else
    echo -e "${RED}❌ FAILED (some scripts not executable)${NC}"
    exit 1
fi

echo
echo -e "${GREEN}🎉 All quick tests passed!${NC}"
echo
echo "Configuration summary:"
echo "- Main config: .zshrc"
echo "- Modules: 12 files in config/"
echo "- Scripts: install.sh, uninstall.sh, test.sh"
echo "- Documentation: README.md"
echo "- Build system: Makefile"
echo
echo "To install: ./install.sh"
echo "To test further: make test"
