// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

import { InVault } from "../interfaces/InVault.sol";

/// @title functions to extend the nVault interface
/// @author loveistheindex
library nVaultHelpersLib {
  uint256 constant MAX_TOKENS_INDEX = 100; 
  function tokenSet(InVault vault) internal view returns (address[] memory result) {
    result = new address[](MAX_TOKENS_INDEX);
    uint256 i = 0;
    for (;;i++) {
      (bool success, bytes memory response) = address(vault).staticcall(abi.encodeWithSelector(InVault.tokens.selector, i));
      if (!success) break;
      (result[i]) = abi.decode(response, (address));
    }
    assembly {
      let length := mload(result)
      mstore(result, i)
    }
  }
}
    
