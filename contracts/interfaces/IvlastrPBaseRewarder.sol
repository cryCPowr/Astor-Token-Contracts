// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IBaseRewardPool.sol";

interface IvlastrPBaseRewarder is IBaseRewardPool {
    
    function queueASTR(uint256 _amount, address _user) external returns(bool);
}