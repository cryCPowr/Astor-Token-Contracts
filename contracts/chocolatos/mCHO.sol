// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { SafeERC20 } from "../../node_modules/@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "../../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC20Upgradeable } from "../../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { OwnableUpgradeable } from "../../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import { Initializable } from "../../node_modules/@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { ReentrancyGuardUpgradeable } from '../../node_modules/@openzeppelin/contracts/security/ReentrancyGuard.sol';
import { PausableUpgradeable } from '../../node_modules/@openzeppelin/contracts/security/Pausable.sol';

import "../interfaces/chocolatos/IChocolatosStaking.sol";
import "../interfaces/ISimpleHelper.sol";

/// @title mCHO
/// @author Astor Team
/// @notice mCHO is a token minted when 1 CHO is locked in Astor
contract mCHO is Initializable, ERC20Upgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable {
    using SafeERC20 for IERC20;

    /* ============ State Variables ============ */

    address public chobatStaking;
    address public cho;
    address public helper;
    uint256 public totalConverted;
    uint256 public totalAccumulated;

    bool    public isChoUp;

    /* ============ Events ============ */

    event mChoMinted(address indexed user, uint256 amount);
    event HelperSet(address indexed _helper);
    event ChobatStakingSet(address indexed _chocolatosStaking);
    event ChoConverted(uint256 _choAmount, uint256 _veChoAmount);
    event ChoUpSet(bool _isChoUp);

    /* ============ Errors ============ */

    error HelperNotSet();
    error ChocolatosStakingNotSet();
    error OnlyChoUp();

    /* ============ Constructor ============ */

    function __mCho_init(address _chocolatosStaking, address _cho) public initializer {
        __ERC20_init("mCHO", "mCHO");
        __Ownable_init();
        chocolatosStaking = _chocolatosStaking;
        cho = _cho;
        totalConverted = 0;
        totalAccumulated = 0;

        isChoUp = true; // when deployed, it should be during Cho Up campaign.
    }

    /* ============ External Functions ============ */
    
    /// @notice deposit Cho in Astor finance and get mCho at a 1:1 rate
    /// @param _amount the amount of Cho
    function convert(uint256 _amount) whenNotPaused external {
        _convert(_amount, false, true);
    }

    function convertAndStake(uint256 _amount) whenNotPaused external {
        _convert(_amount, true, true);
    }

    function deposit(uint256 _amount) whenNotPaused external {
        if(!isChoUp)
            revert OnlyChoUp();

        _convert(_amount, false, false);
    }

    /* ============ Internal Functions ============ */

    function _convert(uint256 _amount, bool _forStake, bool _doConvert) whenNotPaused nonReentrant internal {
        if (_doConvert) {
            if (chocolatosStaking == address(0))
                revert ChocolatosStakingNotSet();
            IERC20(cho).safeTransferFrom(msg.sender, chocolatosStaking, _amount);
            _lockCho(_amount, false);

        } else {
            IERC20(cho).safeTransferFrom(msg.sender, address(this), _amount);
        }

        if(_forStake) {
            if (helper == address(0))
                revert HelperNotSet();
            _mint(address(this), _amount);
            IERC20(address(this)).safeApprove(helper, _amount);
            ISimpleHelper(helper).depositFor(_amount, address(msg.sender));
            IERC20(address(this)).safeApprove(helper, 0);
        } else {
            _mint(msg.sender, _amount);
        }

        totalConverted = totalConverted + _amount;
        emit mChoMinted(msg.sender, _amount);
    }

    function _lockCho(uint256 _amount, bool _needSend) internal {
        if (_needSend)
            IERC20(cho).safeTransfer(chocolatosStaking, _amount);

        uint256 mintedVeChoAmount = IChocolatosStaking(chocolatosStaking).convertCHO(_amount);
        totalAccumulated = totalAccumulated + mintedVeChoAmount;

        emit ChoConverted(_amount, mintedVeChoAmount);
    }

    /* ============ Admin Functions ============ */

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setHelper(address _helper) external onlyOwner {
        helper = _helper;

        emit HelperSet(_helper);
    }

    function setChocolatosStaking(address _chocolatosStaking) external onlyOwner {
        chocolatosStaking =_chocolatosStaking;

        emit ChocolatosStakingSet(chocolatosStaking);
    }

    function setChoUp(bool _isChoUp) external onlyOwner {
        isChoUp = _isChoUp;

        emit ChoUpSet(isChoUp);
    }

    function lockAllCho() external onlyOwner {
        uint256 allCho = IERC20(cho).balanceOf(address(this));
        _lockCho(allCho, true);
    }
}