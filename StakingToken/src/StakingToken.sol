// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./token/ERC20.sol";
import "./token/IERC20.sol";
import "./utils/Context.sol";
// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
// import "@openzeppelin/contracts/utils/Context.sol";
// import "@nomiclabs/builder/console.sol";
import "./IStakingToken.sol";

// TODO: struct StakeStore { uint40 stakeId, stakedTime, ??? } -> mapping(address => StakeStore[]) public stakeLists;

/**
 * @dev ERC20 token minted by staking another Token.
 * Gas not efficient when rewards are based on all tokens inside contract.
 */
contract StakingToken is Context, ERC20, IStakingToken {
    uint256 public reward_rate = 0; // wei tokens per second
    uint256 public total_staked_tokens = 0; // contract supply of token for staking

    address public immutable owner;
    address public immutable accepted_staking_token_address; // we exclude Ether in this contract

    uint256 private constant MAX_TOKENS_UINT256 = type(uint256).max;
    uint256 private _all_rewards = 0; // all waiting tokens to be minted, calculate on "get"
    uint256 private _last_reward_epoch = 0; // evaluate on each deposit stake / withdrawal reward or stake
    address[] private _stakers; // list of addresses of stakers
    mapping(address => uint256) private _current_stakes;
    mapping(address => uint256) private _current_rewards;

    error ContractNeverStartedStaking();
    error InsufficientRewardBalance();
    error TooBigStakeAmount();
    error EtherNotAcceptedAsStakingToken();
    error CannotProcessZeroValue();

    constructor(address staking_token_address) ERC20("TokenPrinter", "TP") {
        if (staking_token_address == address(0))
            revert EtherNotAcceptedAsStakingToken();
        accepted_staking_token_address = staking_token_address;
        owner = _msgSender();
    }

    function _contract_owner() internal view returns (address) {
        return owner;
    }

    modifier isOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(_contract_owner() == _msgSender(), "!OWNER");
        require(tx.origin == _msgSender(), "!TX-OWNER");
        _;
    }

    modifier validateContract() {
        if (_last_reward_epoch == 0) revert ContractNeverStartedStaking();
        _;
    }

    modifier updateStakedBalances() {
        // gas intensive on high amount of users, not optimal function
        uint256 currentTime = block.timestamp;

        if (
            _stakers.length > 0 &&
            currentTime > _last_reward_epoch &&
            total_staked_tokens > 0 &&
            reward_rate > 0
        ) {
            uint256 timeDifference = currentTime - _last_reward_epoch;
            uint256 total_rewards = timeDifference * reward_rate;
            uint256 calculated_new_rewards = 0;
            uint256 calculated_new_rewards_sum = 0;
            for (uint192 i = 0; i < _stakers.length; i++) {
                unchecked {
                    calculated_new_rewards = ((_current_stakes[_stakers[i]] *
                        total_rewards) / total_staked_tokens); // can this overflow during multiplification?
                }
                if (calculated_new_rewards > 0) {
                    _current_rewards[_stakers[i]] += calculated_new_rewards; // gas intensive write
                    calculated_new_rewards_sum += calculated_new_rewards;
                }
            }
            _all_rewards += calculated_new_rewards_sum;
        }
        _last_reward_epoch = currentTime;
        _;
    }

    function totalSupplyPending()
        public
        override
        validateContract
        updateStakedBalances
        returns (uint256)
    {
        return _all_rewards;
    }

    function getStakedBalance() public view override returns (uint256) {
        require(tx.origin == _msgSender(), "!TX-OWNER");
        return _current_stakes[_msgSender()];
    }

    function setRewardRate(uint256 new_reward_rate)
        public
        override
        isOwner
        updateStakedBalances
        returns (bool)
    {
        reward_rate = new_reward_rate;
        emit RewardRate(new_reward_rate);
        return true;
    }

    function getClaimableReward()
        public
        override
        validateContract
        updateStakedBalances
        returns (uint256)
    {
        require(tx.origin == _msgSender(), "!TX-OWNER");
        return _current_rewards[_msgSender()];
    }

    function withdrawReward(uint256 amount)
        public
        override
        validateContract
        updateStakedBalances
        returns (bool)
    {
        require(tx.origin == _msgSender(), "!TX-OWNER");
        if (amount > _current_rewards[_msgSender()])
            revert InsufficientRewardBalance();
        return _withdrawReward(amount, _msgSender(), _msgSender());
    }

    function withdrawRewardTo(uint256 amount, address to)
        public
        override
        validateContract
        updateStakedBalances
        returns (bool)
    {
        require(tx.origin == _msgSender(), "!TX-OWNER");
        if (amount > _current_rewards[_msgSender()])
            revert InsufficientRewardBalance();
        return _withdrawReward(amount, to, _msgSender());
    }

    function _withdrawReward(
        uint256 amount,
        address to,
        address from
    ) internal returns (bool) {
        if (amount == 0) revert CannotProcessZeroValue();
        _current_rewards[from] -= amount;
        _mint(to, amount);
        _all_rewards -= amount;
        emit WithdrawReward(amount, to);
        return true;
    }

    function depositStake(uint256 amount)
        public
        override
        updateStakedBalances
        returns (bool)
    {
        if (amount == 0) revert CannotProcessZeroValue();
        if (amount + total_staked_tokens < MAX_TOKENS_UINT256) {
            IERC20(accepted_staking_token_address).transferFrom(
                _msgSender(),
                address(this),
                amount
            );
            bool found_staker = false;
            for (uint192 i = 0; i < _stakers.length; i++) {
                if (_stakers[i] == _msgSender()) {
                    found_staker = true;
                    break;
                }
            }
            if (found_staker == false) _stakers.push(_msgSender());
            total_staked_tokens += amount;
            _current_stakes[_msgSender()] += amount;
            emit DepositStake(amount, _msgSender());
        } else revert TooBigStakeAmount();
        return true;
    }

    function withdrawStake(uint256 amount)
        public
        override
        updateStakedBalances
        returns (bool)
    {
        if (amount > _current_stakes[_msgSender()])
            revert InsufficientRewardBalance();
        IERC20(accepted_staking_token_address).transfer(_msgSender(), amount);
        _current_stakes[_msgSender()] -= amount;
        total_staked_tokens -= amount;
        emit WithdrawStake(amount, _msgSender());
        withdrawReward(_current_rewards[_msgSender()]);
        return true;
    }
}
