#!/bin/bash
# Quick installer - scarica e installa tutti gli script essenziali
# Uso: curl -sSL your-domain.com/quick_install.sh | bash

echo "🚀 Installazione script di sistema..."

# Array di script con i loro URL completi
declare -A scripts=(
    ["qemu"]="https://raw.githubusercontent.com/your-repo/scripts/main/installQemuGuestAgent.sh"
    ["dns"]="https://raw.githubusercontent.com/your-repo/scripts/main/setDNSNetplan.sh"
    ["zoxide"]="https://raw.githubusercontent.com/your-repo/scripts/main/installZoxide.sh"
    ["starship"]="https://raw.githubusercontent.com/your-repo/scripts/main/installStarship.sh"
    ["lazyvim"]="https://raw.githubusercontent.com/your-repo/scripts/main/installLazyVim.sh"
)

# Se hai i file su Supabase con auth, sostituisci con:
# Base URL per Supabase (commentato per ora)
# BASE_URL="https://supabase.melillo.eu/storage/v1/object/init-scripts"
# TOKEN="your_token_here"

mkdir -p ~/scripts && cd ~/scripts

for name in "${!scripts[@]}"; do
    echo "📥 Scaricando $name..."
    filename=$(basename "${scripts[$name]}")
    
    # Per GitHub raw (o qualsiasi URL pubblico)
    if curl -fSL "${scripts[$name]}" -o "$filename"; then
        chmod +x "$filename"
        echo "✅ $filename installato"
    else
        echo "❌ Errore scaricando $filename"
    fi
done

echo ""
echo "🎉 Installazione completata!"
echo "📁 Script disponibili in: ~/scripts/"
echo ""
echo "Per eseguire uno script:"
echo "  cd ~/scripts"
echo "  ./nome_script.sh"