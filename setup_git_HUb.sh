#!/bin/bash
# Complete Git + GitHub SSH setup script

echo "🚀 Starting Git and GitHub setup..."

# Step 1: Install Git if missing
if ! command -v git &> /dev/null; then
    echo "Git not found. Installing..."
    if [[ "$(uname)" == "Darwin" ]]; then
        brew install git
    elif [[ -f /etc/debian_version ]]; then
        sudo apt update && sudo apt install -y git
    elif [[ -f /etc/redhat-release ]]; then
        sudo dnf install -y git
    else
        echo "⚠️ Please install Git manually for your OS."
        exit 1
    fi
else
    echo "✅ Git is already installed."
fi

# Step 2: Configure Git username and email
read -p "Enter your Git username: " GIT_NAME
read -p "Enter your Git email: " GIT_EMAIL
git config --global user.name "$GIT_NAME"
git config --global user.email "$GIT_EMAIL"
echo "✅ Git username and email set."

# Step 3: Generate SSH key if it doesn't exist
SSH_KEY="$HOME/.ssh/id_ed25519"
if [ ! -f "$SSH_KEY" ]; then
    echo "🔑 Generating new SSH key..."
    ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f "$SSH_KEY" -N ""
else
    echo "ℹ️ SSH key already exists at $SSH_KEY"
fi

# Step 4: Start SSH agent and add key
eval "$(ssh-agent -s)"
ssh-add "$SSH_KEY"
echo "✅ SSH key added to agent."

# Step 5: Configure SSH for GitHub
CONFIG_FILE="$HOME/.ssh/config"
if ! grep -q "Host github.com" "$CONFIG_FILE" 2>/dev/null; then
    echo "🛠️ Writing SSH config for GitHub..."
    cat >> "$CONFIG_FILE" <<EOF

Host github.com
  HostName github.com
  User git
  IdentityFile $SSH_KEY
EOF
else
    echo "ℹ️ SSH config for GitHub already exists."
fi

# Step 6: Show public key
echo ""
echo "📋 Copy this key to GitHub → Settings → SSH Keys → New SSH key:"
echo ""
cat "${SSH_KEY}.pub"
echo ""

# Step 7: Optionally update existing repo to SSH
read -p "Do you want to update your current repo's remote to SSH? (y/n): " UPDATE_REMOTE
if [[ "$UPDATE_REMOTE" == "y" ]]; then
    read -p "Enter the repo path (or leave blank for current directory): " REPO_DIR
    REPO_DIR=${REPO_DIR:-$(pwd)}
    cd "$REPO_DIR" || exit
    CURRENT_URL=$(git remote get-url origin 2>/dev/null)
    if [[ $CURRENT_URL == https://* ]]; then
        SSH_URL=$(echo $CURRENT_URL | sed 's#https://github.com/#git@github.com:#')
        git remote set-url origin "$SSH_URL"
        echo "✅ Remote URL updated to SSH: $SSH_URL"
    else
        echo "ℹ️ Remote already using SSH or no remote found."
    fi
fi

# Step 8: Test SSH connection
echo "🚀 Testing SSH connection to GitHub..."
ssh -T git@github.com

echo ""
echo "🎉 Git and GitHub SSH setup complete!"
echo "You can now clone repos using SSH:"
echo "  git clone git@github.com:username/repo.git"
