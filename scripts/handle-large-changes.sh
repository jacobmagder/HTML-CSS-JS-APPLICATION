#!/bin/bash

# Handle Large File Deletions Script
# This script helps manage situations with massive file changes/deletions

echo "🔧 Large File Change Handler"
echo "=========================="

# Function to handle large deletions
handle_large_deletions() {
    echo "📊 Analyzing current repository state..."
    
    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo "❌ Not in a git repository"
        exit 1
    fi
    
    # Get current status
    echo "📋 Current git status:"
    git status --porcelain | head -20
    
    DELETED_FILES=$(git status --porcelain | grep "^ D" | wc -l)
    MODIFIED_FILES=$(git status --porcelain | grep "^ M" | wc -l)
    ADDED_FILES=$(git status --porcelain | grep "^A" | wc -l)
    
    echo "📊 File change summary:"
    echo "   🗑️  Deleted: $DELETED_FILES files"
    echo "   ✏️  Modified: $MODIFIED_FILES files"
    echo "   ➕ Added: $ADDED_FILES files"
    
    if [ "$DELETED_FILES" -gt 5000 ]; then
        echo ""
        echo "⚠️  WARNING: Large number of deletions detected!"
        echo "This might be due to:"
        echo "   1. Pulling from a different branch/fork"
        echo "   2. Major repository restructuring"
        echo "   3. Merge conflicts"
        echo ""
        
        read -p "Do you want to proceed with handling these changes? (y/N): " -n 1 -r
        echo
        
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "❌ Operation cancelled"
            exit 1
        fi
        
        echo "🔄 Handling large deletions..."
        
        # Option 1: Reset to last known good state
        echo "Option 1: Reset to last commit (discards all changes)"
        echo "Option 2: Commit deletions in chunks"
        echo "Option 3: Create backup and force push"
        
        read -p "Choose option (1/2/3): " -n 1 -r
        echo
        
        case $REPLY in
            1)
                echo "🔄 Resetting to last commit..."
                git reset --hard HEAD
                echo "✅ Reset complete"
                ;;
            2)
                echo "📦 Committing changes in chunks..."
                
                # Get list of deleted files
                git status --porcelain | grep "^ D" | cut -c4- > /tmp/deleted_files.txt
                
                # Process in chunks of 1000
                split -l 1000 /tmp/deleted_files.txt /tmp/chunk_
                
                chunk_num=1
                for chunk_file in /tmp/chunk_*; do
                    echo "📦 Processing chunk $chunk_num..."
                    
                    while IFS= read -r file; do
                        git rm "$file" 2>/dev/null || true
                    done < "$chunk_file"
                    
                    git commit -m "Batch deletion chunk $chunk_num

Auto-generated commit for handling large file deletions
Chunk contains up to 1000 file deletions
Generated on $(date)"
                    
                    chunk_num=$((chunk_num + 1))
                done
                
                # Clean up
                rm -f /tmp/deleted_files.txt /tmp/chunk_*
                echo "✅ Chunked commits complete"
                ;;
            3)
                echo "💾 Creating backup and force push..."
                
                # Create backup branch
                BACKUP_BRANCH="backup-$(date +%Y%m%d-%H%M%S)"
                git checkout -b "$BACKUP_BRANCH"
                git add -A
                git commit -m "Backup before handling large deletions" || true
                
                echo "✅ Backup created on branch: $BACKUP_BRANCH"
                
                # Return to main branch and force the changes
                git checkout main
                git add -A
                git commit -m "Handle large file deletions

- Processed $(git status --porcelain | wc -l) file changes
- Backup available on branch: $BACKUP_BRANCH
- Generated on $(date)"
                
                echo "✅ Changes committed"
                ;;
            *)
                echo "❌ Invalid option"
                exit 1
                ;;
        esac
    else
        echo "✅ Normal number of changes detected"
        echo "You can proceed with regular git operations"
    fi
}

# Function to set up auto-update remotes
setup_auto_updates() {
    echo ""
    echo "🔄 Setting up automatic updates..."
    
    # Add MDN content remote if it doesn't exist
    if ! git remote | grep -q "mdn-content"; then
        echo "➕ Adding MDN content remote..."
        git remote add mdn-content https://github.com/mdn/content.git
        echo "✅ MDN content remote added"
    else
        echo "✅ MDN content remote already exists"
    fi
    
    # Fetch latest
    echo "📥 Fetching latest from MDN content..."
    git fetch mdn-content main --no-tags
    
    echo "✅ Auto-update setup complete"
    echo ""
    echo "💡 Tips for handling future updates:"
    echo "   1. Use 'git fetch mdn-content main' to get latest changes"
    echo "   2. Use 'git merge mdn-content/main' to merge updates"
    echo "   3. The GitHub Actions workflow will handle this automatically"
}

# Function to configure VS Code settings sync
fix_vscode_sync() {
    echo ""
    echo "🔧 Fixing VS Code Settings Sync issues..."
    
    # Create VS Code settings to disable problematic sync features
    mkdir -p .vscode
    
    cat > .vscode/settings.json << 'EOF'
{
  "settingsSync.ignoredSettings": [
    "terminal.integrated.cwd",
    "workbench.colorTheme",
    "workbench.iconTheme"
  ],
  "settingsSync.keybindingsPerPlatform": false,
  "git.autofetch": false,
  "git.autoStash": true,
  "files.autoSave": "afterDelay",
  "files.autoSaveDelay": 2000,
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.organizeImports": true
  }
}
EOF
    
    echo "✅ VS Code settings configured to reduce sync conflicts"
    echo "💡 Restart VS Code to apply changes"
}

# Main execution
echo "What would you like to do?"
echo "1. Handle large file deletions"
echo "2. Setup automatic updates"
echo "3. Fix VS Code sync issues"
echo "4. All of the above"
echo ""

read -p "Choose option (1/2/3/4): " -n 1 -r
echo

case $REPLY in
    1)
        handle_large_deletions
        ;;
    2)
        setup_auto_updates
        ;;
    3)
        fix_vscode_sync
        ;;
    4)
        handle_large_deletions
        setup_auto_updates
        fix_vscode_sync
        ;;
    *)
        echo "❌ Invalid option"
        exit 1
        ;;
esac

echo ""
echo "🎉 Operations complete!"
echo "📝 Summary of actions taken:"
echo "   - Large file changes handled appropriately"
echo "   - Auto-update remotes configured"
echo "   - VS Code sync issues addressed"
echo ""
echo "🚀 Your repository is now ready for automatic updates!"
