// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestCoins is ERC20 {
    constructor() ERC20("TestCoins", "TSTC") {
        _mint(msg.sender, 1000000000000000000000000); // Mint 1,000,000 TSTC to the contract creator
    }

    function myTransfer(address _to, uint256 _amount) external  {
        require(transfer(_to, _amount), 'Transfer failed');
    }
}
