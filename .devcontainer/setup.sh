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

# Write the interactive first-run setup script
WORKDIR=$(pwd)
cat > .devcontainer/first-run.sh << FIRSTRUN
#!/bin/bash
if ! grep -q "YOUR_NAME_HERE" "${WORKDIR}/student.md" 2>/dev/null; then
  exit 0
fi
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  👋  Welcome to D0017D — Initial Programming in Java"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  Please enter your details below. This only happens once."
echo ""
read -rp "  Your full name: " student_name
read -rp "  Your LTU username (e.g. abc12def): " ltu_username
sed -i "s|YOUR_NAME_HERE|\${student_name}|" "${WORKDIR}/student.md"
sed -i "s|YOUR_LTU_USERNAME_HERE|\${ltu_username}|" "${WORKDIR}/student.md"
cd "${WORKDIR}" && git add student.md && git commit -m "chore: add student info" && git push 2>/dev/null || true
echo ""
echo "  ✅ Details saved! Open Hello.java and click ▶ Run to get started."
echo ""
FIRSTRUN
chmod +x .devcontainer/first-run.sh

# Run the setup prompt on every new terminal (exits immediately once details are filled in)
echo "bash ${WORKDIR}/.devcontainer/first-run.sh" >> ~/.bashrc
