#!/bin/bash

# Install pre-commit hook to protect critical environment files
HOOK=.git/hooks/pre-commit
cat > $HOOK << 'EOF'
#!/bin/bash
protected=(
  ".devcontainer/devcontainer.json"
  ".devcontainer/setup.sh"
  ".gitignore"
)
for file in "${protected[@]}"; do
  if git diff --cached --name-only --diff-filter=D | grep -q "^$file$"; then
    echo ""
    echo "❌ Cannot delete '$file' — this file is required for your coding environment."
    echo "   Restore it and try again. If something is broken, ask your teacher for help."
    echo ""
    exit 1
  fi
done
EOF
chmod +x $HOOK

# Personalise the README with this repo's Codespace URL
REMOTE_URL=$(git remote get-url origin 2>/dev/null)
if [ -n "$REMOTE_URL" ]; then
  REPO_PATH=$(echo "$REMOTE_URL" | sed 's|https://github.com/||;s|git@github.com:||;s|\.git$||')
  sed -i "s|CODESPACE_URL_PLACEHOLDER|https://codespaces.new/${REPO_PATH}?quickstart=1|g" README.md
  git add README.md
  git diff --cached --quiet || git commit -m "chore: add Codespace link to README"
  git push 2>/dev/null || true
fi
