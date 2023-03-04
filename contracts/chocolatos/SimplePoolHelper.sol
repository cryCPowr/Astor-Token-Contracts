// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Ownable } from "../../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import { SafeERC20 } from "../../node_modules/@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20, ERC20 } from "../../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "../interfaces/IBaseRewardPool.sol";
import "../interfaces/IMasterAstor.sol";
import "../interfaces/IPoolHelper.sol";

/// @title Poolhelper
/// @author Astor Team
/// @notice This contract is the pool helper for staking mCho and ASTR
contract SimplePoolHelper is Ownable {
    using SafeERC20 for IERC20;
    address public immutable masterAstor;
    address public immutable stakeToken;

    /* ============ State Variables ============ */

    mapping(address => bool) authorized;

    /* ============ Errors ============ */

    error OnlyAuthorizedCaller();    

    /* ============ Constructor ============ */

    constructor(address _masterAstor, address _stakeToken) {
        masterAstor = _masterAstor;
        stakeToken = _stakeToken;
    }

    /* ============ Modifiers ============ */

    modifier onlyAuthorized() {
        if (!authorized[msg.sender])
            revert OnlyAuthorizedCaller();
        _;
    }    

    /* ============ External Functions ============ */

    function depositFor(uint256 _amount, address _for) external onlyAuthorized {
        IERC20(stakeToken).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );
        IERC20(stakeToken).safeApprove(masterAstor, _amount);
        IMasterAstor(masterAstor).depositFor(stakeToken, _amount, _for);
    }

    /* ============ Admin Functions ============ */

    function authorize(address _for) external onlyOwner {
        authorized[_for] = true;
    }

    function unauthorize(address _for) external onlyOwner {
        authorized[_for] = false;
    }
}