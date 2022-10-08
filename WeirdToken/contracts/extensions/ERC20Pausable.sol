// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../security/Pausable.sol";

/**
 * @dev Extension of {ERC20} that allows to pause and unpause token transfers/burns
 */
abstract contract ERC20Pausable is ERC20, Pausable {
    /**
     * @dev Pause token, only owner allowed while not paused
     *
     */
    function pause() public virtual whenNotPaused isOwner {
        _pause();
    }

    /**
     * @dev Unpause token, only owner allowed while paused
     *
     */
    function unpause() public virtual whenPaused isOwner {
        _unpause();
    }
}
