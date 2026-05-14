#!/bin/bash

# Navigate to the Foundry project root (contracts directory)
# This allows the script to be run from anywhere and correctly use forge
cd "$(dirname "$0")/../.."

# Exit on error
set -e

# Load .env variables if .env file exists
if [ -f .env ]; then
    set -a
    source .env
    set +a
fi

# Arguments or environment variables
PRIMARY_LAYER="${1:-$PRIMARY_LAYER}"
NONCE="${2:-$NONCE}"
PRIVATE_KEYS="${3:-$PRIVATE_KEYS}"
EXTRA_ARGS="${@:4}" # Any additional arguments like --broadcast, --private-key, etc.

if [ -z "$PRIMARY_LAYER" ] || [ -z "$NONCE" ] || [ -z "$PRIVATE_KEYS" ]; then
    echo "Error: Missing required arguments."
    echo "Usage: $0 <PRIMARY_LAYER_ADDRESS> <NONCE> <PRIVATE_KEYS_ARRAY> [EXTRA_ARGS...]"
    echo "Example: $0 0x123... 0 \"[1, 2]\" --broadcast"
    echo "Note: Arguments can also be provided via .env file variables (PRIMARY_LAYER, NONCE, PRIVATE_KEYS)."
    exit 1
fi

# 6 minutes in seconds
INTERVAL=360 

echo "=========================================================="
echo "Starting Timed Ideas Layer Deployment Process"
echo "Primary Layer: $PRIMARY_LAYER"
echo "Nonce: $NONCE"
echo "Interval: 6 minutes ($INTERVAL seconds) between steps"
echo "=========================================================="
echo ""

echo "[1/3] Executing deployIdeasLayer1..."
forge script governance/actions/Initialise.s.sol:Initialise \
    --sig "deployIdeasLayer1(address,uint256,uint256[])" \
    "$PRIMARY_LAYER" "$NONCE" "$PRIVATE_KEYS" \
    $EXTRA_ARGS
echo "deployIdeasLayer1 completed successfully."

echo ""
echo "Waiting for 6 minutes ($INTERVAL seconds) before executing the next step..."
sleep $INTERVAL
echo ""

echo "[2/3] Executing deployIdeasLayer2..."
forge script governance/actions/Initialise.s.sol:Initialise \
    --sig "deployIdeasLayer2(address,uint256,uint256[])" \
    "$PRIMARY_LAYER" "$NONCE" "$PRIVATE_KEYS" \
    $EXTRA_ARGS
echo "deployIdeasLayer2 completed successfully."

echo ""
echo "Waiting for 6 minutes ($INTERVAL seconds) before executing the next step..."
sleep $INTERVAL
echo ""

echo "[3/3] Executing deployIdeasLayer3..."
forge script governance/actions/Initialise.s.sol:Initialise \
    --sig "deployIdeasLayer3(address,uint256)" \
    "$PRIMARY_LAYER" "$NONCE" \
    $EXTRA_ARGS
echo "deployIdeasLayer3 completed successfully."

echo ""
echo "=========================================================="
echo "Ideas Layer Deployment Process Complete!"
echo "=========================================================="
