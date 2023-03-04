// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { SafeERC20 } from "../../node_modules/@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "../../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "../interfaces/IBaseRewardPool.sol";
import "../interfaces/IHarvesttablePoolHelper.sol";
import "../interfaces/chocolatos/IChocolatosStaking.sol";
import "../interfaces/chocolatos/IMasterChocolatos.sol";
import "../interfaces/IMasterAstor.sol";
import "../interfaces/IMintableERC20.sol";
import "../interfaces/IWNative.sol";

/// @title ChocolatosPoolHelper
/// @author Astor Team
/// @notice This contract is the main contract that user will intreact with in order to stake stable in Chocolatos Pool

contract ChocolatosPoolHelper is IHarvesttablePoolHelper {
    using SafeERC20 for IERC20;

    /* ============ Constants ============ */

    address public immutable depositToken; // token to deposit into Chocolatos
    address public immutable lpToken;      // lp token receive from Chocolatos, also the pool identified on ChoabtStaking
    address public immutable stakingToken; // token staking to master astor
    address public immutable mCho;
    
    address public immutable masterAstor;
    address public immutable ChocolatosStaking; 
    address public immutable rewarder; 

    uint256 public immutable pid; // pid on master Chocolatos

    bool public immutable isNative;

    /* ============ Events ============ */

    event NewDeposit(address indexed _user, uint256 _amount);
    event NewLpDeposit(address indexed _user, uint256 _amount);
    event NewWithdraw(address indexed _user, uint256 _amount);

    /* ============ Errors ============ */

    error NotNativeToken();

    /* ============ Constructor ============ */

constructor(
        uint256 _pid,
        address _stakingToken,
        address _depositToken,
        address _lpToken,
        address _chocolatosStaking,
        address _masterAstor,
        address _rewarder,
        address _mCho,
        bool _isNative
    ) {
        pid = _pid;
        stakingToken = _stakingToken;
        depositToken = _depositToken;
        lpToken = _lpToken;
        ChocolatosStaking = _chocolatosStaking;
        masterAstor = _masterAstor;
        rewarder = _rewarder;
        mCho = _mCho;
        isNative = _isNative;
    }

    /* ============ External Getters ============ */

    /// @notice Get the amount of total staked LP token in master Astor.
    function totalStaked() external override view returns (uint256) {
        return IBaseRewardPool(rewarder).totalStaked();
    }
    
    /// @notice Get the total amount of shares of a user.
    /// @param _address The user.
    /// @return The amount of shares.
    function balance(address _address) external override view returns (uint256) {
        return IBaseRewardPool(rewarder).balanceOf(_address);
    }

    function pendingCho() external view returns (uint256 pendingTokens) {
        (pendingTokens, , , ) = IMasterChocolatos(
            IChocolatosStaking(ChocolatosStaking).masterChocolatos()
        ).pendingTokens(pid, ChocolatosStaking);
    }    


    /* ============ External Functions ============ */
    
    /// @notice Deposit stables in Chocolatos pool, autostake in master Astor.    
    /// @param _amount The amount of stables to deposit.
    /// @param _minimumLiquidity The minimum liquidity required.
    function deposit(uint256 _amount, uint256 _minimumLiquidity) external override {
        _deposit(_amount, _minimumLiquidity, msg.sender);
    }

    /// @notice Deposit LP token in Chocolatos pool, autostake in master Astor.
    /// @param _lpAmount The amount of LP token to deposit.
    function depositLP(uint256 _lpAmount) external {
        uint256 beforeDeposit = IERC20(stakingToken).balanceOf(address(this));
        IChocolatosStaking(ChocolatosStaking).depositLP(lpToken, _lpAmount, msg.sender);
        uint256 afterDeposit = IERC20(stakingToken).balanceOf(address(this));
        _stake(afterDeposit - beforeDeposit, msg.sender);
        
        emit NewLpDeposit(msg.sender, _lpAmount);
    }

    /// @notice Deposit native token in Chocolatos pool, autostake in master Astor.
    function depositNative(uint256 _minimumLiquidity) external payable {
        if (!isNative) revert NotNativeToken();
        // Does it need to limit the amount must > 0?

        // Swap the BNB to wBNB.
        _wrapNative();
        // Deposit wBNB to the pool.
        IWNative(depositToken).approve(ChocolatosStaking, msg.value);
        _deposit(msg.value, _minimumLiquidity, address(this));
        IWNative(depositToken).approve(ChocolatosStaking, 0);
    }

    /// @notice withdraw stables from chocolatos pool, auto unstake from master Astor
    /// @param _liquidity the amount of liquidity to withdraw
    function withdraw(uint256 _liquidity, uint256 _minAmount) external override {
        // we have to withdraw from chocolatos exchange to harvest reward to base rewarder
        IChocolatosStaking(ChocolatosStaking).withdraw(
            lpToken,
            _liquidity,
            _minAmount,
            msg.sender
        );
        // then we unstake from master chocolatos to trigger reward distribution from basereward
        _unstake(_liquidity, msg.sender);
        //  last burn the staking token withdrawn from Master Astor
        IChocolatosStaking(ChocolatosStaking).burnReceiptToken(lpToken, _liquidity);


        emit NewWithdraw(msg.sender, _liquidity);
    }

    function harvest() external override {
        IChocolatosStaking(ChocolatosStaking).harvest(lpToken);
    }

    /* ============ Internal Functions ============ */

    function _deposit(uint256 _amount, uint256 _minimumLiquidity, address _from) internal {
        uint256 beforeDeposit = IERC20(stakingToken).balanceOf(address(this));
        IChocolatosStaking(ChocolatosStaking).deposit(lpToken, _amount, _minimumLiquidity, msg.sender, _from);
        uint256 afterDeposit = IERC20(stakingToken).balanceOf(address(this));
        _stake(afterDeposit - beforeDeposit, msg.sender);
        
        emit NewDeposit(msg.sender, _amount);
    }

    function _wrapNative() internal {
        IWNative(depositToken).deposit{value: msg.value}();
    }

    /// @notice stake the receipt token in the masterchief of GMP on behalf of the caller
    function _stake(uint256 _amount, address _sender) internal {
        IERC20(stakingToken).safeApprove(masterAstor, _amount);
        IMasterAstor(masterAstor).depositFor(stakingToken, _amount, _sender);
    }

    /// @notice unstake from the masterchief of GMP on behalf of the caller
    function _unstake(uint256 _amount, address _sender) internal {
        IMasterAstor(masterAstor).withdrawFor(stakingToken, _amount, _sender);
    }
}