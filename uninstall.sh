#!/bin/bash
# nt-deploy uninstaller (macOS / Linux)

set -e

YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${YELLOW}🗑️  Disinstallo nt-deploy...${NC}"

# Rimuovi cartella
rm -rf "$HOME/.nt-tools"
echo -e "${GREEN}✓${NC} Cartella ~/.nt-tools rimossa"

# Rimuovi alias dai vari shell rc
for rc in "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.profile"; do
  if [ -f "$rc" ] && grep -q ">>> nt-deploy >>>" "$rc"; then
    # Rimuove il blocco tra i marker
    sed -i.bak '/# >>> nt-deploy >>>/,/# <<< nt-deploy <<</d' "$rc"
    echo -e "${GREEN}✓${NC} Alias rimossi da $rc (backup: $rc.bak)"
  fi
done

echo ""
echo -e "${GREEN}✅ Disinstallazione completata${NC}"
echo "Riapri il terminale per applicare i cambiamenti"
