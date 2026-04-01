#!/usr/bin/env bash
# SuiGrove deploy script — run this from WSL terminal.
# Usage:
#   bash scripts/deploy.sh          # deploy to current active env (testnet)
#   bash scripts/deploy.sh mainnet  # deploy to mainnet (Phase 4 only!)
#
# Prerequisites (run once):
#   sui client new-env --alias testnet --rpc https://fullnode.testnet.sui.io:443
#   sui client switch --env testnet
#   sui client faucet

set -e  # Exit immediately on any error

NETWORK=${1:-testnet}
CONTRACTS_DIR="$(dirname "$0")/../contracts"

echo "========================================"
echo " SuiGrove Deploy — Network: $NETWORK"
echo "========================================"

# Safety check — confirm before mainnet deploys
if [ "$NETWORK" = "mainnet" ]; then
    read -p "WARNING: Deploying to MAINNET. Are you sure? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        echo "Aborted."
        exit 1
    fi
    sui client switch --env mainnet
else
    sui client switch --env testnet
fi

echo ""
echo "Active environment:"
sui client active-env
echo ""
echo "Active address:"
sui client active-address
echo ""

# Build contracts
echo "Building Move contracts..."
cd "$CONTRACTS_DIR"
sui move build

# Publish
echo ""
echo "Publishing package..."
PUBLISH_OUTPUT=$(sui client publish --gas-budget 100000000 --json 2>&1)

# Extract key IDs from the output
PACKAGE_ID=$(echo "$PUBLISH_OUTPUT" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for change in data.get('objectChanges', []):
    if change.get('type') == 'published':
        print(change['packageId'])
        break
" 2>/dev/null || echo "")

echo ""
echo "========================================"
echo " Publish complete!"
echo "========================================"
echo ""
echo "PACKAGE_ID: $PACKAGE_ID"
echo ""
echo "Next steps:"
echo ""
echo "1. Find your AdminCap and TreasuryCap IDs from the output above:"
echo "   Look for objectChanges with type 'created' and objectType containing"
echo "   'AdminCap' and 'TreasuryCap'"
echo ""
echo "2. Run initialize_registry with both IDs:"
echo "   sui client call \\"
echo "     --package \$PACKAGE_ID \\"
echo "     --module farm_registry \\"
echo "     --function initialize_registry \\"
echo "     --args \$ADMIN_CAP_ID \$TREASURY_CAP_ID \\"
echo "     --gas-budget 10000000"
echo ""
echo "3. Note the FarmRegistry shared object ID from that output."
echo ""
echo "4. Update frontend/.env.local:"
echo "   NEXT_PUBLIC_PACKAGE_ID=$PACKAGE_ID"
echo "   NEXT_PUBLIC_FARM_REGISTRY_ID=<registry_object_id>"
echo "   NEXT_PUBLIC_NETWORK=$NETWORK"
