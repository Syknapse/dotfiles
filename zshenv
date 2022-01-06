# We use this file for non interactive shells
echo '.zshenv loaded'

# Check if a command already exists
function exists() {
  # command -v is like which, $1 is the first argument passed
  # redirect the successful output to the black hole to dicard it
  # do the same with error poutput
  # we don't need those because the result depends on exit codes
  command -v $1 >/dev/null 2>&1
}