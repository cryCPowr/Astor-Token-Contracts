// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import '../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '../node_modules/@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol';

/// @title ASTR
/// @author Astor Team
contract ASTR is ERC20('Astor Token', 'ASTR'), ERC20Permit('Astor Token') {
    constructor(address _receipient, uint256 _totalSupply) {
        _mint(_receipient, _totalSupply);
    }
}