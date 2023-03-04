// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "../chocolatos/ChocolatosPoolHelper.sol";

/// @title PoolHelperFactoryLib
/// @author Astor Team
/// @notice Chocolatos Staking is the contract that interacts with ALL Chocolatos contract
/// @dev all functions except harvest are restricted either to owner or to other contracts from the astor protocol
/// @dev the owner of this contract holds a lot of power, and should be owned by a multisig
library PoolHelperFactoryLib {
    function createChocolatosPoolHelper(
        uint256 _pid,
        address _stakingToken,
        address _depositToken,
        address _lpToken,
        address _chocolatosStaking,
        address _masterAstor,
        address _rewarder,
        address _mCho,
        bool _isNative
    ) public returns(address) 
    {
        ChocolatosPoolHelper pool = new ChocolatosPoolHelper(_pid, _stakingToken, _depositToken, _lpToken, _chocolatosStaking, _masterAstor, _rewarder, _mCho, _isNative);
        return address(pool);
    }
}