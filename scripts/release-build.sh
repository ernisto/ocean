set -e

# arguments
if [ -z "$1" ]; then
    echo "Usage: $0 <rojo project name>"
    exit 1
fi
GAME_NAME="$1"

# pesde
pesde install --prod

# rojo
mkdir -p dist/rojo
rojo build places/"$GAME_NAME"/game.project.json --output dist/rojo/"$GAME_NAME".rbxl
