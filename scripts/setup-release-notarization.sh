#!/usr/bin/env bash
set -euo pipefail
echo 'Robey Voice local builds require no notarization account.'
echo 'For independent distribution, obtain your own Developer ID identity and store'
echo 'credentials using xcrun notarytool store-credentials <your-profile>.'
echo 'Never put credentials/private keys into source. No account or profile is created by this script.'
