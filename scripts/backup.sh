#!/bin/bash

# Ensure script is run with bash (not sh)
if [ -z "$BASH_VERSION" ]; then
    exec bash "$0" "$@"
fi

# Configuration
# Get repo root directory (one level up from scripts/)
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUTPUT_DIR="${OUTPUT_DIR:-${REPO_ROOT}/.backup}"
APP_NAME="dnd-maroto"
DATE_SUFFIX=$(date +'%d_%m_%Y')

# Array of files/directories to back up (relative to remote /home/data)
FILES_TO_BACKUP=(
    /home/foundry/data/Backups/worlds/dndzinho-maroto/world.dndzinho-maroto.2025-12-19.1766114664396.json
    /home/foundry/data/Backups/worlds/dndzinho-maroto/world.dndzinho-maroto.2025-11-05.1762333160763.bak
    /home/foundry/data/Backups/worlds/dndzinho-maroto/world.dndzinho-maroto.2025-11-21.1763743676127.json
    /home/foundry/data/Backups/worlds/dndzinho-maroto/world.dndzinho-maroto.2025-11-09.1762685629460.bak
    /home/foundry/data/Backups/worlds/dndzinho-maroto/world.dndzinho-maroto.2025-12-19.1766114664396.bak
    /home/foundry/data/Backups/worlds/dndzinho-maroto/world.dndzinho-maroto.2025-11-05.1762333160763.json
    /home/foundry/data/Backups/worlds/dndzinho-maroto/world.dndzinho-maroto.2025-11-21.1763743676127.bak
    /home/foundry/data/Backups/worlds/dndzinho-maroto/world.dndzinho-maroto.2025-12-19.1766112616184.bak
    /home/foundry/data/Backups/worlds/dndzinho-maroto/world.dndzinho-maroto.2025-11-09.1762685629460.json
    /home/foundry/data/Backups/worlds/dndzinho-maroto/world.dndzinho-maroto.2025-12-19.1766112616184.json
    /home/foundry/data/Backups/snapshots/snapshot.2025-12-19.1766114542407.json
    /home/foundry/data/Backups/modules/5e-spellblock-importer/module.5e-spellblock-importer.2025-12-19.1766114542411.bak
    /home/foundry/data/Backups/modules/5e-spellblock-importer/module.5e-spellblock-importer.2025-12-19.1766114542411.json
    /home/foundry/data/Backups/modules/moulinette-tiles/module.moulinette-tiles.2025-12-19.1766114637362.bak
    /home/foundry/data/Backups/modules/moulinette-tiles/module.moulinette-tiles.2025-12-19.1766114637362.json
    /home/foundry/data/Backups/modules/forien-ammo-swapper/module.forien-ammo-swapper.2025-12-19.1766114617039.json
    /home/foundry/data/Backups/modules/forien-ammo-swapper/module.forien-ammo-swapper.2025-12-19.1766114617039.bak
    /home/foundry/data/Backups/modules/clipboard-image/module.clipboard-image.2025-12-19.1766114607614.json
    /home/foundry/data/Backups/modules/clipboard-image/module.clipboard-image.2025-12-19.1766114607614.bak
    /home/foundry/data/Backups/modules/lib-wrapper/module.lib-wrapper.2025-12-19.1766114621784.json
    /home/foundry/data/Backups/modules/lib-wrapper/module.lib-wrapper.2025-12-19.1766114621784.bak
    /home/foundry/data/Backups/modules/monks-active-tiles/module.monks-active-tiles.2025-12-19.1766114636356.json
    /home/foundry/data/Backups/modules/monks-active-tiles/module.monks-active-tiles.2025-12-19.1766114636356.bak
    /home/foundry/data/Backups/modules/vtta-tokenizer/module.vtta-tokenizer.2025-12-19.1766114653441.bak
    /home/foundry/data/Backups/modules/vtta-tokenizer/module.vtta-tokenizer.2025-12-19.1766114653441.json
    /home/foundry/data/Backups/modules/moulinette-compendiums/module.moulinette-compendiums.2025-12-19.1766114636785.json
    /home/foundry/data/Backups/modules/moulinette-compendiums/module.moulinette-compendiums.2025-12-19.1766114636785.bak
    /home/foundry/data/Backups/modules/baileywiki-maps/module.baileywiki-maps.2025-12-19.1766114547470.json
    /home/foundry/data/Backups/modules/baileywiki-maps/module.baileywiki-maps.2025-12-19.1766114547470.bak
    /home/foundry/data/Backups/modules/token-hud-wildcard/module.token-hud-wildcard.2025-12-19.1766114650009.json
    /home/foundry/data/Backups/modules/token-hud-wildcard/module.token-hud-wildcard.2025-12-19.1766114650009.bak
    /home/foundry/data/Backups/modules/compendium-folders/module.compendium-folders.2025-12-19.1766114608324.bak
    /home/foundry/data/Backups/modules/compendium-folders/module.compendium-folders.2025-12-19.1766114608324.json
    /home/foundry/data/Backups/modules/enhancedcombathud/module.enhancedcombathud.2025-12-19.1766114616529.json
    /home/foundry/data/Backups/modules/enhancedcombathud/module.enhancedcombathud.2025-12-19.1766114616529.bak
    /home/foundry/data/Backups/modules/variant-encumbrance-dnd5e/module.variant-encumbrance-dnd5e.2025-12-19.1766114653339.bak
    /home/foundry/data/Backups/modules/variant-encumbrance-dnd5e/module.variant-encumbrance-dnd5e.2025-12-19.1766114653339.json
    /home/foundry/data/Backups/modules/bmc0/module.bmc0.2025-12-19.1766114582220.json
    /home/foundry/data/Backups/modules/bmc0/module.bmc0.2025-12-19.1766114582220.bak
    /home/foundry/data/Backups/modules/dice-so-nice/module.dice-so-nice.2025-12-19.1766114609417.bak
    /home/foundry/data/Backups/modules/dice-so-nice/module.dice-so-nice.2025-12-19.1766114609417.json
    /home/foundry/data/Backups/modules/moulinette-sounds/module.moulinette-sounds.2025-12-19.1766114637284.json
    /home/foundry/data/Backups/modules/moulinette-sounds/module.moulinette-sounds.2025-12-19.1766114637284.bak
    /home/foundry/data/Backups/modules/dfreds-convenient-effects/module.dfreds-convenient-effects.2025-12-19.1766114609082.bak
    /home/foundry/data/Backups/modules/dfreds-convenient-effects/module.dfreds-convenient-effects.2025-12-19.1766114609082.json
    /home/foundry/data/Backups/modules/dae/module.dae.2025-12-19.1766114608596.json
    /home/foundry/data/Backups/modules/dae/module.dae.2025-12-19.1766114608596.bak
    /home/foundry/data/Backups/modules/dungeon-draw/module.dungeon-draw.2025-12-19.1766114615503.json
    /home/foundry/data/Backups/modules/dungeon-draw/module.dungeon-draw.2025-12-19.1766114615503.bak
    /home/foundry/data/Backups/modules/deathmark/module.deathmark.2025-12-19.1766114608953.bak
    /home/foundry/data/Backups/modules/deathmark/module.deathmark.2025-12-19.1766114608953.json
    /home/foundry/data/Backups/modules/itemcollection/module.itemcollection.2025-12-19.1766114620274.bak
    /home/foundry/data/Backups/modules/itemcollection/module.itemcollection.2025-12-19.1766114620274.json
    /home/foundry/data/Backups/modules/gm-screen/module.gm-screen.2025-12-19.1766114619589.json
    /home/foundry/data/Backups/modules/gm-screen/module.gm-screen.2025-12-19.1766114619589.bak
    /home/foundry/data/Backups/modules/popout/module.popout.2025-12-19.1766114639856.json
    /home/foundry/data/Backups/modules/popout/module.popout.2025-12-19.1766114639856.bak
    /home/foundry/data/Backups/modules/df-settings-clarity/module.df-settings-clarity.2025-12-19.1766114609045.json
    /home/foundry/data/Backups/modules/df-settings-clarity/module.df-settings-clarity.2025-12-19.1766114609045.bak
    /home/foundry/data/Backups/modules/memento-mori/module.memento-mori.2025-12-19.1766114621854.json
    /home/foundry/data/Backups/modules/memento-mori/module.memento-mori.2025-12-19.1766114621854.bak
    /home/foundry/data/Backups/modules/encounter-builder/module.encounter-builder.2025-12-19.1766114616111.json
    /home/foundry/data/Backups/modules/encounter-builder/module.encounter-builder.2025-12-19.1766114616111.bak
    /home/foundry/data/Backups/modules/easy-target/module.easy-target.2025-12-19.1766114616000.json
    /home/foundry/data/Backups/modules/easy-target/module.easy-target.2025-12-19.1766114616000.bak
    /home/foundry/data/Backups/modules/hidden-tables/module.hidden-tables.2025-12-19.1766114620235.json
    /home/foundry/data/Backups/modules/hidden-tables/module.hidden-tables.2025-12-19.1766114620235.bak
    /home/foundry/data/Backups/modules/torch/module.torch.2025-12-19.1766114653281.json
    /home/foundry/data/Backups/modules/torch/module.torch.2025-12-19.1766114653281.bak
    /home/foundry/data/Backups/modules/racoozes-strength-of-thousands-maps/module.racoozes-strength-of-thousands-maps.2025-12-19.1766114639964.bak
    /home/foundry/data/Backups/modules/racoozes-strength-of-thousands-maps/module.racoozes-strength-of-thousands-maps.2025-12-19.1766114639964.json
    /home/foundry/data/Backups/modules/fvtt-party-resources/module.fvtt-party-resources.2025-12-19.1766114617653.json
    /home/foundry/data/Backups/modules/fvtt-party-resources/module.fvtt-party-resources.2025-12-19.1766114617653.bak
    /home/foundry/data/Backups/modules/simbuls-cover-calculator/module.simbuls-cover-calculator.2025-12-19.1766114649683.json
    /home/foundry/data/Backups/modules/simbuls-cover-calculator/module.simbuls-cover-calculator.2025-12-19.1766114649683.bak
    /home/foundry/data/Backups/modules/monks-scene-navigation/module.monks-scene-navigation.2025-12-19.1766114636532.bak
    /home/foundry/data/Backups/modules/monks-scene-navigation/module.monks-scene-navigation.2025-12-19.1766114636532.json
    /home/foundry/data/Backups/modules/combat-enhancements/module.combat-enhancements.2025-12-19.1766114608263.bak
    /home/foundry/data/Backups/modules/combat-enhancements/module.combat-enhancements.2025-12-19.1766114608263.json
    /home/foundry/data/Backups/modules/drag-ruler/module.drag-ruler.2025-12-19.1766114615424.json
    /home/foundry/data/Backups/modules/drag-ruler/module.drag-ruler.2025-12-19.1766114615424.bak
    /home/foundry/data/Backups/modules/better-rolltables/module.better-rolltables.2025-12-19.1766114580846.bak
    /home/foundry/data/Backups/modules/better-rolltables/module.better-rolltables.2025-12-19.1766114580846.json
    /home/foundry/data/Backups/modules/dfreds-effects-panel/module.dfreds-effects-panel.2025-12-19.1766114609270.bak
    /home/foundry/data/Backups/modules/dfreds-effects-panel/module.dfreds-effects-panel.2025-12-19.1766114609270.json
    /home/foundry/data/Backups/modules/dnd-item-compendium-by-gwill/module.dnd-item-compendium-by-gwill.2025-12-19.1766114610635.json
    /home/foundry/data/Backups/modules/dnd-item-compendium-by-gwill/module.dnd-item-compendium-by-gwill.2025-12-19.1766114610635.bak
    /home/foundry/data/Backups/modules/food-and-water-tracker/module.food-and-water-tracker.2025-12-19.1766114617013.bak
    /home/foundry/data/Backups/modules/food-and-water-tracker/module.food-and-water-tracker.2025-12-19.1766114617013.json
    /home/foundry/data/Backups/modules/SupersHomebrewPack/module.SupersHomebrewPack.2025-12-19.1766114542634.json
    /home/foundry/data/Backups/modules/SupersHomebrewPack/module.SupersHomebrewPack.2025-12-19.1766114542634.bak
    /home/foundry/data/Backups/modules/fxmaster/module.fxmaster.2025-12-19.1766114617763.bak
    /home/foundry/data/Backups/modules/fxmaster/module.fxmaster.2025-12-19.1766114617763.json
    /home/foundry/data/Backups/modules/moulinette-imagesearch/module.moulinette-imagesearch.2025-12-19.1766114637115.json
    /home/foundry/data/Backups/modules/moulinette-imagesearch/module.moulinette-imagesearch.2025-12-19.1766114637115.bak
    /home/foundry/data/Backups/modules/times-up/module.times-up.2025-12-19.1766114649797.json
    /home/foundry/data/Backups/modules/times-up/module.times-up.2025-12-19.1766114649797.bak
    /home/foundry/data/Backups/modules/socketlib/module.socketlib.2025-12-19.1766114649777.bak
    /home/foundry/data/Backups/modules/socketlib/module.socketlib.2025-12-19.1766114649777.json
    /home/foundry/data/Backups/modules/furnace/module.furnace.2025-12-19.1766114617647.bak
    /home/foundry/data/Backups/modules/furnace/module.furnace.2025-12-19.1766114617647.json
    /home/foundry/data/Backups/modules/cursor-hider/module.cursor-hider.2025-12-19.1766114608545.json
    /home/foundry/data/Backups/modules/cursor-hider/module.cursor-hider.2025-12-19.1766114608545.bak
    /home/foundry/data/Backups/modules/midi-qol/module.midi-qol.2025-12-19.1766114621940.bak
    /home/foundry/data/Backups/modules/midi-qol/module.midi-qol.2025-12-19.1766114621940.json
    /home/foundry/data/Backups/modules/chat-images/module.chat-images.2025-12-19.1766114607581.bak
    /home/foundry/data/Backups/modules/chat-images/module.chat-images.2025-12-19.1766114607581.json
    /home/foundry/data/Backups/modules/dnd-randomizer/module.dnd-randomizer.2025-12-19.1766114615295.bak
    /home/foundry/data/Backups/modules/dnd-randomizer/module.dnd-randomizer.2025-12-19.1766114615295.json
    /home/foundry/data/Backups/modules/illandril-turn-marker/module.illandril-turn-marker.2025-12-19.1766114620252.bak
    /home/foundry/data/Backups/modules/illandril-turn-marker/module.illandril-turn-marker.2025-12-19.1766114620252.json
    /home/foundry/data/Backups/modules/simbuls-athenaeum/module.simbuls-athenaeum.2025-12-19.1766114649658.json
    /home/foundry/data/Backups/modules/simbuls-athenaeum/module.simbuls-athenaeum.2025-12-19.1766114649658.bak
    /home/foundry/data/Backups/modules/miskasmaps/module.miskasmaps.2025-12-19.1766114622451.json
    /home/foundry/data/Backups/modules/miskasmaps/module.miskasmaps.2025-12-19.1766114622451.bak
    /home/foundry/data/Backups/modules/token-factions/module.token-factions.2025-12-19.1766114649819.bak
    /home/foundry/data/Backups/modules/token-factions/module.token-factions.2025-12-19.1766114649819.json
    /home/foundry/data/Backups/modules/levels/module.levels.2025-12-19.1766114620368.bak
    /home/foundry/data/Backups/modules/levels/module.levels.2025-12-19.1766114620368.json
    /home/foundry/data/Backups/modules/enhancedcombathud-dnd5e/module.enhancedcombathud-dnd5e.2025-12-19.1766114616820.json
    /home/foundry/data/Backups/modules/enhancedcombathud-dnd5e/module.enhancedcombathud-dnd5e.2025-12-19.1766114616820.bak
    /home/foundry/data/Backups/modules/beavers-potions/module.beavers-potions.2025-12-19.1766114580724.bak
    /home/foundry/data/Backups/modules/beavers-potions/module.beavers-potions.2025-12-19.1766114580724.json
    /home/foundry/data/Backups/modules/colorsettings/module.colorsettings.2025-12-19.1766114607635.bak
    /home/foundry/data/Backups/modules/colorsettings/module.colorsettings.2025-12-19.1766114607635.json
    /home/foundry/data/Backups/modules/scene-packer/module.scene-packer.2025-12-19.1766114649261.json
    /home/foundry/data/Backups/modules/scene-packer/module.scene-packer.2025-12-19.1766114649261.bak
    /home/foundry/data/Backups/modules/token-mold/module.token-mold.2025-12-19.1766114650038.bak
    /home/foundry/data/Backups/modules/token-mold/module.token-mold.2025-12-19.1766114650038.json
    /home/foundry/data/Backups/modules/settings-extender/module.settings-extender.2025-12-19.1766114649649.json
    /home/foundry/data/Backups/modules/settings-extender/module.settings-extender.2025-12-19.1766114649649.bak
    /home/foundry/data/Backups/modules/wall-height/module.wall-height.2025-12-19.1766114655483.json
    /home/foundry/data/Backups/modules/wall-height/module.wall-height.2025-12-19.1766114655483.bak
    /home/foundry/data/Backups/modules/5e-statblock-importer/module.5e-statblock-importer.2025-12-19.1766114542549.json
    /home/foundry/data/Backups/modules/5e-statblock-importer/module.5e-statblock-importer.2025-12-19.1766114542549.bak
    /home/foundry/data/Backups/modules/automated-conditions-5e/module.automated-conditions-5e.2025-12-19.1766114547430.json
    /home/foundry/data/Backups/modules/automated-conditions-5e/module.automated-conditions-5e.2025-12-19.1766114547430.bak
    /home/foundry/data/Backups/modules/easyrandomtable/module.easyrandomtable.2025-12-19.1766114616029.json
    /home/foundry/data/Backups/modules/easyrandomtable/module.easyrandomtable.2025-12-19.1766114616029.bak
    /home/foundry/data/Backups/modules/dice-calculator/module.dice-calculator.2025-12-19.1766114609309.json
    /home/foundry/data/Backups/modules/dice-calculator/module.dice-calculator.2025-12-19.1766114609309.bak
    /home/foundry/data/Backups/modules/foundryvtt-show-notes/module.foundryvtt-show-notes.2025-12-19.1766114617638.bak
    /home/foundry/data/Backups/modules/foundryvtt-show-notes/module.foundryvtt-show-notes.2025-12-19.1766114617638.json
    /home/foundry/data/Backups/modules/enhanced-terrain-layer/module.enhanced-terrain-layer.2025-12-19.1766114616257.json
    /home/foundry/data/Backups/modules/enhanced-terrain-layer/module.enhanced-terrain-layer.2025-12-19.1766114616257.bak
    /home/foundry/data/Backups/modules/orcnog-card-viewer/module.orcnog-card-viewer.2025-12-19.1766114637504.json
    /home/foundry/data/Backups/modules/orcnog-card-viewer/module.orcnog-card-viewer.2025-12-19.1766114637504.bak
    /home/foundry/data/Backups/modules/moulinette-core/module.moulinette-core.2025-12-19.1766114636822.json
    /home/foundry/data/Backups/modules/moulinette-core/module.moulinette-core.2025-12-19.1766114636822.bak
    /home/foundry/data/Backups/modules/ready-to-use-cards/module.ready-to-use-cards.2025-12-19.1766114645440.json
    /home/foundry/data/Backups/modules/ready-to-use-cards/module.ready-to-use-cards.2025-12-19.1766114645440.bak
    /home/foundry/data/Backups/modules/advanced-drawing-tools/module.advanced-drawing-tools.2025-12-19.1766114547387.bak
    /home/foundry/data/Backups/modules/advanced-drawing-tools/module.advanced-drawing-tools.2025-12-19.1766114547387.json
    /home/foundry/data/Backups/modules/monks-tokenbar/module.monks-tokenbar.2025-12-19.1766114636571.bak
    /home/foundry/data/Backups/modules/monks-tokenbar/module.monks-tokenbar.2025-12-19.1766114636571.json
    /home/foundry/data/Backups/modules/moulinette-scenes/module.moulinette-scenes.2025-12-19.1766114637146.json
    /home/foundry/data/Backups/modules/moulinette-scenes/module.moulinette-scenes.2025-12-19.1766114637146.bak
    /home/foundry/data/Backups/modules/combat-carousel/module.combat-carousel.2025-12-19.1766114607691.json
    /home/foundry/data/Backups/modules/combat-carousel/module.combat-carousel.2025-12-19.1766114607691.bak
    /home/foundry/data/Backups/modules/world-explorer/module.world-explorer.2025-12-19.1766114655518.bak
    /home/foundry/data/Backups/modules/world-explorer/module.world-explorer.2025-12-19.1766114655518.json
    /home/foundry/data/Backups/modules/forien-quest-log/module.forien-quest-log.2025-12-19.1766114617104.json
    /home/foundry/data/Backups/modules/forien-quest-log/module.forien-quest-log.2025-12-19.1766114617104.bak
    /home/foundry/data/Backups/modules/hand-mini-bar/module.hand-mini-bar.2025-12-19.1766114619994.bak
    /home/foundry/data/Backups/modules/hand-mini-bar/module.hand-mini-bar.2025-12-19.1766114619994.json
    /home/foundry/data/Backups/modules/moulinette-gameicons/module.moulinette-gameicons.2025-12-19.1766114637081.bak
    /home/foundry/data/Backups/modules/moulinette-gameicons/module.moulinette-gameicons.2025-12-19.1766114637081.json
    /home/foundry/data/Backups/modules/caeora-maps-tokens-assets/module.caeora-maps-tokens-assets.2025-12-19.1766114588382.json
    /home/foundry/data/Backups/modules/caeora-maps-tokens-assets/module.caeora-maps-tokens-assets.2025-12-19.1766114588382.bak
    /home/foundry/data/Backups/systems/dnd5e/system.dnd5e.2025-12-19.1766114655545.json
    /home/foundry/data/Backups/systems/dnd5e/system.dnd5e.2025-12-19.1766114655545.bak
)

# Create output directory with date suffix
OUTPUT_PATH="${OUTPUT_DIR}"
mkdir -p "${OUTPUT_PATH}"

echo "=========================================="
echo "Starting backup process..."
echo "Output directory: ${OUTPUT_PATH}"
echo "=========================================="
echo ""

# Backup each file/directory
for file_path in "${FILES_TO_BACKUP[@]}"; do
    echo "------------------------------------------"
    echo "Backing up: ${file_path}"
    
    # Extract the path structure starting from "Backups"
    # Example: /home/foundry/data/Backups/worlds/... -> Backups/worlds/...
    if [[ "${file_path}" == *"/Backups"* ]]; then
        # Get everything after and including "Backups"
        relative_path="${file_path#*/Backups}"
        relative_path="Backups${relative_path}"
        
        # Get the directory path and filename
        local_dir="${OUTPUT_PATH}/$(dirname "${relative_path}")"
        file_name=$(basename "${file_path}")
        
        # Create the directory structure
        mkdir -p "${local_dir}"
        
        # Download to the preserved structure
        local_file_path="${local_dir}/${file_name}"
    else
        # Fallback: if "Backups" not found, just use filename
        file_name=$(basename "${file_path}")
        local_file_path="${OUTPUT_PATH}/${file_name}"
    fi
    
    # Skip if file already exists
    if [ -f "${local_file_path}" ]; then
        echo "⊘ Skipping (already exists): ${local_file_path}"
        echo ""
        continue
    fi
    
    flyctl ssh sftp get -a "${APP_NAME}" "${file_path}" "${local_file_path}"
    
    if [ $? -eq 0 ]; then
        echo "✓ Successfully backed up: ${file_path} -> ${local_file_path}"
    else
        echo "✗ Failed to back up: ${file_path}"
    fi
    echo ""
done

echo "=========================================="
echo "Backup completed. Files saved to: ${OUTPUT_PATH}"
echo "=========================================="