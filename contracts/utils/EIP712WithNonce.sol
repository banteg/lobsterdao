// SPDX-License-Identifier: MIT
// taken from Amxx: https://github.com/Amxx/Permit/blob/master/contracts/EIP712WithNonce.sol

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

abstract contract EIP712WithNonce is EIP712 {
    mapping(address => mapping(uint256 => uint256)) private _nonces;

    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _domainSeparatorV4();
    }

    function nonce(address from) public view virtual returns (uint256) {
        return uint256(_nonces[from][0]);
    }

    function nonce(address from, uint256 timeline) public view virtual returns (uint256) {
        return _nonces[from][timeline];
    }

    function _verifyAndConsumeNonce(address owner, uint256 idx) internal virtual {
        require(idx % (1 << 128) == _nonces[owner][idx >> 128]++, "invalid-nonce");
    }
}