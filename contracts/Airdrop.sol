// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract Airdrop {
    address public token;
    bytes32 public merkleRoot;
    address public ivan;

    event Claimed(uint256 index, address account, uint256 amount);

    mapping(uint256 => uint256) private claimedBitMap;

    constructor(address token_, bytes32 merkleRoot_, address ivan_) public {
        token = token_;
        merkleRoot = merkleRoot_;
        ivan = ivan_;
    }

    function isClaimed(uint256 index) public view returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimedWordIndex] = claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
    }

    // a user must provide a merkle proof and an ivan signauture associating them with a recipient address
    function claim(
        uint256 index, uint256 amount, bytes32[] calldata merkleProof,
        address account, bytes calldata ivanSignature
    ) external {
        require(!isClaimed(index), 'already claimed');

        bytes32 node = keccak256(abi.encodePacked(index, amount));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), 'invalid merkle proof');

        bytes32 digest = ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(index, account)));
        require(ECDSA.recover(digest, ivanSignature) == ivan, 'invalid ivan signature');

        _setClaimed(index);
        require(IERC20(token).transfer(account, amount), 'transfer failed');

        emit Claimed(index, account, amount);
    }
}
