// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.6;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

interface ILobsNFT {
    function mint(address to) external returns(bool);
}

contract AirdropNFT {
    address public nft;
    bytes32 public merkleRoot;
    address public ivan;

    event Claimed(uint256 index, address account);

    mapping(uint256 => uint256) private claimedBitMap;

    constructor(address nft_, bytes32 merkleRoot_, address ivan_) public {
        nft = nft_;
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
        uint256 index, bytes32[] calldata merkleProof,
        address account, bytes calldata ivanSignature
    ) external {
        require(!isClaimed(index), 'already claimed');

        bytes32 node = keccak256(abi.encodePacked(index));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), 'invalid merkle proof');

        bytes32 digest = ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(index, account)));
        require(ECDSA.recover(digest, ivanSignature) == ivan, 'invalid ivan signature');

        _setClaimed(index);
        require(ILobsNFT(nft).mint(account), 'mint failed');

        emit Claimed(index, account);
    }
}
