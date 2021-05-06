// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";

library nVaultLib {
  using SafeMath for *;
  function fullToken(address _token) internal view returns (uint256 result) {
    result = 10**safeDecimals(_token);
  }
  function sortTokens(address[] memory _set) internal pure returns (address[] memory) {
    for (uint256 i = 1; i < _set.length; i++){
      uint256 temp = uint256(uint160(_set[i]));
      uint256 j;
      for (j = i - 1; j >= 0 && temp < uint256(uint160(_set[j])); j--)
        _set[j + 1] = _set[j];
      _set[j + 1] = address(uint160(temp));
    }
    return _set;
  }
  function safeDecimals(address _token) internal view returns (uint8 decimals) {
    (bool success, bytes memory result) = _token.staticcall(abi.encodeWithSelector(IERC20Metadata.decimals.selector));
    if (!success) return 18;
    (decimals) = abi.decode(result, (uint8));
  }
  function sum(uint256[] memory _set) internal pure returns (uint256 result) {
    for (uint256 i = 0; i < _set.length; i++) {
      result = result.add(_set[i]);
    }
  }
}

