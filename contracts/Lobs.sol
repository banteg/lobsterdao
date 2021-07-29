pragma solidity =0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract Lobs is ERC20("LobsterDAO", "LOBS") {
    constructor(uint supply) {
        _mint(msg.sender, supply);
    }
}
