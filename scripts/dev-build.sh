set -e

# pesde
pesde install

# rojo
mkdir -p dist/rojo
rojo build dev.project.json --output dist/rojo/game.rbxl
