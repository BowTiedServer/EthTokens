// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the TAX standard.
 */
interface ITAX {
    /**
     * @dev Emitted when `value` tokens are burned forever in terms of global taxation!
     *
     * Note that `value` is not less then 1 * 10**18.
     */
    event TaxBurn(uint256 value);

    /**
     * @dev Returns the amount of tokens taxed in existence.
     */
    function totalTax() external view returns (uint256);
}
