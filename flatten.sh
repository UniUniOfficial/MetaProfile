LICENSE_INFO="SPDX-License-Identifier"

./node_modules/.bin/truffle-flattener contracts/MetaProfile.sol | grep -v "$LICENSE_INFO" > flattened/MetaProfile.sol
