# ZSH Ultra Performance Config - Makefile
# High-performance modular ZSH configuration

.DEFAULT_GOAL := help
.PHONY: help install uninstall test backup restore clean

SHELL_DIR := $(PWD)
BACKUP_DIR := ~/.config/zsh-ultra-backup
INSTALL_SCRIPT := ./install.sh
UNINSTALL_SCRIPT := ./uninstall.sh

help: ## Show this help message
	@echo "ZSH Ultra Performance Config"
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

install: ## Install the ZSH configuration
	@echo "🚀 Installing ZSH Ultra Performance Config..."
	@$(INSTALL_SCRIPT)

uninstall: ## Uninstall the ZSH configuration
	@echo "🗑️  Uninstalling ZSH Ultra Performance Config..."
	@$(UNINSTALL_SCRIPT)

test: ## Run the complete test suite
	@echo "🧪 Running complete test suite..."
	@./test-runner.sh all

test-unit: ## Run unit tests only
	@echo "🔬 Running unit tests..."
	@./test-runner.sh unit

test-integration: ## Run integration tests only
	@echo "🔗 Running integration tests..."
	@./test-runner.sh integration

test-performance: ## Run performance benchmarks
	@echo "⚡ Running performance tests..."
	@./test-runner.sh performance

test-install: ## Run installation script tests
	@echo "📦 Running installation tests..."
	@./test-runner.sh install

test-compatibility: ## Run compatibility tests only
	@echo "🔄 Running compatibility tests..."
	@./test-runner.sh compatibility

test-syntax: ## Test configuration syntax only
	@echo "📝 Testing ZSH configuration syntax..."
	@zsh -n .zshrc && echo "✅ Main config syntax OK"
	@for file in config/*.zsh; do \
		echo "Testing $$file..."; \
		zsh -n "$$file" || exit 1; \
	done
	@echo "✅ All modules syntax OK"

test-nodejs: ## Run Node.js specific tests
	@echo "📦 Running Node.js/npm tests..."
	@./test-runner.sh unit
	@bats tests/unit/test_nodejs.bats tests/integration/test_nodejs_full.bats tests/performance/test_nodejs_perf.bats -t

test-report: ## Run tests and generate detailed report
	@echo "📊 Running tests with report generation..."
	@./test-runner.sh all --report

backup: ## Create a backup of current ZSH config
	@echo "💾 Creating backup..."
	@mkdir -p $(BACKUP_DIR)
	@[ -f ~/.zshrc ] && cp ~/.zshrc $(BACKUP_DIR)/zshrc.backup.$$(date +%Y%m%d_%H%M%S) || echo "No existing .zshrc found"
	@echo "✅ Backup created in $(BACKUP_DIR)"

restore: ## Restore from backup (interactive)
	@echo "🔄 Available backups:"
	@ls -la $(BACKUP_DIR)/ 2>/dev/null || echo "No backups found"
	@echo "To restore, manually copy the desired backup to ~/.zshrc"

clean: ## Clean temporary files
	@echo "🧹 Cleaning temporary files..."
	@find . -name "*.tmp" -delete
	@find . -name ".DS_Store" -delete
	@echo "✅ Cleanup complete"

lint: ## Check code style and potential issues
	@echo "🔍 Linting ZSH files..."
	@command -v shellcheck >/dev/null 2>&1 && \
		find . -name "*.zsh" -exec shellcheck -s bash {} \; || \
		echo "⚠️  shellcheck not found, install it for better linting"

deps: ## Install system dependencies
	@echo "📦 Installing system dependencies..."
	@sudo apt update
	@sudo apt install -y zsh git curl wget build-essential

dev-setup: deps ## Complete development setup
	@echo "🛠️  Setting up development environment..."
	@$(MAKE) backup
	@$(MAKE) install
	@$(MAKE) test

benchmark: ## Benchmark ZSH startup time
	@echo "⏱️  Benchmarking ZSH startup time..."
	@for i in {1..5}; do \
		time zsh -i -c exit 2>&1 | grep real; \
	done

info: ## Show configuration information
	@echo "ℹ️  ZSH Ultra Performance Config Information"
	@echo "Configuration directory: $(SHELL_DIR)"
	@echo "Modules:"
	@ls -1 config/*.zsh | sed 's/^/  - /'
	@echo "Install script: $(INSTALL_SCRIPT)"
	@echo "Backup directory: $(BACKUP_DIR)"

# Release management
release-patch: ## Create a patch release (x.x.X)
	@echo "🚀 Creating patch release..."
	@./release patch

release-minor: ## Create a minor release (x.X.x)
	@echo "🚀 Creating minor release..."
	@./release minor

release-major: ## Create a major release (X.x.x)
	@echo "🚀 Creating major release..."
	@./release major

release-dry: ## Dry run release (shows what would be done)
	@echo "🧪 Dry run release..."
	@./release patch --dry-run

check-updates: ## Check for available updates
	@echo "🔍 Checking for updates..."
	@./scripts/update.sh --check

update: ## Update to latest version
	@echo "⬆️  Updating to latest version..."
	@./scripts/update.sh --auto
