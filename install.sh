#!/bin/zsh
# Installs the `spoofmac` command. Works from a clone (./install.sh) or piped:
#   curl -fsSL https://raw.githubusercontent.com/aliemrevezir/spoofmac/main/install.sh | zsh
set -eu

PREFIX="${PREFIX:-$HOME/.local}"
RAW="https://raw.githubusercontent.com/aliemrevezir/spoofmac/main/bin/spoofmac"

src="${0:A:h}/bin/spoofmac"
if [[ ! -f "$src" ]]; then
  tmp=$(mktemp -d)
  curl -fsSL "$RAW" -o "$tmp/spoofmac"
  src="$tmp/spoofmac"
fi

mkdir -p "$PREFIX/bin"
install -m 755 "$src" "$PREFIX/bin/spoofmac"
echo "✓ spoofmac → $PREFIX/bin/spoofmac"

case ":$PATH:" in
  *":$PREFIX/bin:"*) ;;
  *) echo "! $PREFIX/bin is not on your PATH. Add this to ~/.zshrc:"
     echo "    export PATH=\"$PREFIX/bin:\$PATH\"" ;;
esac

if ! command -v spoofdpi >/dev/null 2>&1 && [[ ! -x /opt/homebrew/bin/spoofdpi && ! -x /usr/local/bin/spoofdpi ]]; then
  echo "! SpoofDPI is not installed yet: brew install spoofdpi"
fi

echo "Next: spoofmac install"
