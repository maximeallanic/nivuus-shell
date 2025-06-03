#!/bin/bash

# =============================================================================
# BACKUP MODULE
# =============================================================================

backup_existing_config() {
    print_step "Backing up existing configuration..."
    
    mkdir -p "$BACKUP_DIR"
    
    # Backup existing .zshrc
    if [[ -f ~/.zshrc ]]; then
        cp ~/.zshrc "$BACKUP_DIR/zshrc.backup"
        print_success "Backed up ~/.zshrc"
    fi
    
    # Backup existing zsh directory
    if [[ -d ~/.zsh ]]; then
        cp -r ~/.zsh "$BACKUP_DIR/zsh.backup"
        print_success "Backed up ~/.zsh directory"
    fi
    
    # Backup existing config
    if [[ -d "$INSTALL_DIR" ]]; then
        cp -r "$INSTALL_DIR" "$BACKUP_DIR/zsh-config.backup"
        print_success "Backed up existing configuration"
    fi
    
    print_success "Backup completed in $BACKUP_DIR"
}

restore_backup() {
    print_step "Restoring from backup..."
    
    if [[ ! -d "$BACKUP_DIR" ]]; then
        print_error "No backup directory found at $BACKUP_DIR"
        return 1
    fi
    
    # Restore .zshrc
    if [[ -f "$BACKUP_DIR/zshrc.backup" ]]; then
        cp "$BACKUP_DIR/zshrc.backup" ~/.zshrc
        print_success "Restored ~/.zshrc"
    fi
    
    # Restore zsh directory
    if [[ -d "$BACKUP_DIR/zsh.backup" ]]; then
        rm -rf ~/.zsh
        cp -r "$BACKUP_DIR/zsh.backup" ~/.zsh
        print_success "Restored ~/.zsh directory"
    fi
    
    print_success "Restore completed"
}

cleanup_backup() {
    if [[ -d "$BACKUP_DIR" ]]; then
        read -p "$(echo -e "${YELLOW}Remove backup directory? (y/N): ${NC}")" -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$BACKUP_DIR"
            print_success "Backup directory removed"
        fi
    fi
}
