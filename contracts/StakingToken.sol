// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract StakingToken is ERC20 {
    constructor() ERC20("Staking Token", "ST") {
        _mint(msg.sender, 1e25); //setting initial supply to 1e30
    }


    function mint(address account, uint256 value) external{
        _mint(account,value);
    }
    
}