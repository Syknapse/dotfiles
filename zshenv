# We use this file for non interactive shells
echo '.zshenv loaded'

# Check if a command already exists
function exists() {
  command -v $1 >/dev/null 2>&1
}