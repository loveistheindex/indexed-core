// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;
import { nVaultLib } from "./nVaultLib.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IController {
  function balanceOf(address) external view returns (uint256);
  function earn(address[] calldata, uint256[] calldata) external;
}

contract nVault is ERC20 {
  using SafeERC20 for *;
  using SafeMath for *;
  using nVaultLib for *;
  address[] public tokens;
  mapping (address => uint256) public min;
  mapping (address => uint256) public max;
  address public governance;
  address public controller;
  address public compareValueTo;
  uint8 internal _decimals;
  function valueOf(address _token, uint256 _amount) internal view returns (uint256) {
    // return the amount of compareValueTo you would get for swapping _amount worth of _token
  }
  function value(address _token) internal view returns (uint256 result) {
    result = valueOf(_token, balance(_token));
  }
  function valueSet() internal view returns (uint256[] memory result) {
    uint256 _length = tokens.length;
    result = new uint256[](_length);
    for (uint256 i = 0; i < _length; i++) {
      result[i] = value(tokens[i]);
    }
  }
  function decimals() public view virtual override returns (uint8) {
    return _decimals;
  }
  constructor(address[] memory _tokens, address _compareValueTo, address _controller, string memory _name, string memory _symbol) ERC20(_name, _symbol) {
    _decimals = IERC20Metadata(compareValueTo).decimals();
    tokens = nVaultLib.sortTokens(_tokens);
    controller = _controller;
    governance = msg.sender;
    compareValueTo = _compareValueTo;
  }
  function balance(address _token) public view returns (uint256 result) {
    result = IERC20(_token).balanceOf(address(this)).add(IController(controller).balanceOf(address(_token)));
  }
  function balanceSet() public view returns (uint256[] memory result) {
    uint256 _length = tokens.length;
    result = new uint256[](_length);
    for (uint256 i = 0; i < _length; i++) {
      result[i] = balance(tokens[i]);
    }
  }
  function exists(address _token) internal view returns (bool result) {
    return max[_token] != 0;
  }
  function setMin(address _token, uint256 _min) external {
    require(msg.sender == governance, "!governance");
    min[_token] = _min;
  }
  function setMax(address _token, uint256 _max) internal {
    require(msg.sender == governance, "!governance");
    max[_token] = _max;
  }
  function setGovernance(address _governance) public {
    require(msg.sender == governance, "!governance");
    governance = _governance;
  }
  function setController(address _controller) public {
    require(msg.sender == governance, "!governance");
    controller = _controller;
  }
  function available(address _token) public view returns (uint256) {
    return IERC20(_token).balanceOf(address(this)).mul(min[_token]).div(max[_token]);
  }
  function earnOne(address _token) internal returns (uint256 _bal) {
    _bal = available(_token);
    IERC20(_token).safeTransfer(controller, _bal);
  }
  function earn() public {
    uint256 _length = tokens.length;
    uint256[] memory _sent = new uint256[](_length);
    for (uint256 i = 0; i < _length; i++) {
      _sent[i] = earnOne(tokens[i]);
    }
    IController(controller).earn(tokens, _sent);
  }
  function getPricesPerFullShare() public view returns (uint256[] memory result) {
    uint256 _length = tokens.length;
    result = new uint256[](_length);
    uint256[] memory weights = valueSet();
    uint256 grossValue = weights.sum();
    for (uint256 i = 0; i < _length; i++) {
      result[i] = balance(tokens[i]).mul(weights[i]).div(grossValue.mul(totalSupply()));
    }
  }
  function deposit(uint256 _shares, uint256[] memory _maxAmounts) public {
    uint256[] memory amountsNeeded = getPricesPerFullShare();
    for (uint256 i = 0; i < _maxAmounts.length; i++) {
      require(amountsNeeded[i] <= _maxAmounts[i], "!price");
      IERC20(tokens[i]).safeTransferFrom(msg.sender, address(this), amountsNeeded[i].mul(_shares).div(10**decimals())); 
    }
    _mint(msg.sender, _shares);
  }
  function withdraw(uint256 _shares) public {
    uint256[] memory amountsToRedeem = getPricesPerFullShare();
    for (uint256 i = 0; i < amountsToRedeem.length; i++) {
      IERC20(tokens[i]).safeTransfer(msg.sender, amountsToRedeem[i].mul(_shares).div(10**decimals()));
    }
    _burn(msg.sender, _shares);
  }
  function withdrawAll() public {
    withdraw(balanceOf(msg.sender));
  }
  function harvest(address reserve, uint256 amount) public {
    require(msg.sender == controller, "!controller");
    require(!exists(reserve), "token");
    IERC20(reserve).safeTransfer(controller, amount);
  }
}
