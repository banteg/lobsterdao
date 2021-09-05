// SPDX-License-Identifier: MIT
// permit implementation taken from Amxx: https://github.com/Amxx/Permit/blob/master/contracts/EIP712WithNonce.sol
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./utils/EIP712WithNonce.sol";

contract LobsNFT is ERC721, Ownable, EIP712WithNonce {
  using Counters for Counters.Counter;

  bytes32 private immutable _PERMIT721_TYPEHASH = keccak256("Permit721(address registry,uint256 tokenid,address to,uint256 nonce,uint256 deadline,address relayer)");
  Counters.Counter private _tokenId;
  address private airdropContract;
  string private baseUri_;

  event AirdropContractSet(address indexed contractAddress);
  event BaseURISet(string indexed uri);

  modifier onlyAirdrop() {
    require(msg.sender == airdropContract || msg.sender == owner()
      , "only airdrop & owner can mint");
    _;
  }

  constructor() 
    EIP712("LobsterDAO NFT", "1") 
    ERC721("LobsterDAO NFT", "LOBS") {}

  function getAirdropAddress() external returns(address) {
    return airdropContract;
  }

  function setBaseUri(string memory _uri) external onlyOwner {
    baseUri_ = _uri;
    emit BaseURISet(_uri);
  }

  function setAirdrop(address _airdropContract) external onlyOwner {
    airdropContract = _airdropContract;
    emit AirdropContractSet(_airdropContract);
  }

  function mint(address to) onlyAirdrop external returns(bool) {
    _tokenId.increment();
    uint256 currentId = _tokenId.current();
    _safeMint(to, currentId);

    return true;
  }

  function transfer721WithSign(
      uint256 tokenId,
      address to,
      uint256 nonce,
      uint256 deadline,
      bytes memory signature
  )
      external
  {
      address from = ownerOf(tokenId);

      require(block.timestamp <= deadline, "NFTPermit::transfer721WithSign: Expired deadline");
      _verifyAndConsumeNonce(from, nonce);
      require(
          SignatureChecker.isValidSignatureNow(
              from,
              _hashTypedDataV4(keccak256(abi.encode(
                  _PERMIT721_TYPEHASH,
                  address(this),
                  tokenId,
                  to,
                  nonce,
                  deadline
              ))),
              signature
          ),
          "NFTPermit::transfer721WithSign: Invalid signature"
      );

      safeTransferFrom(from, to, tokenId);
  }

  function _baseURI() internal override view returns(string memory) {
    return baseUri_;
  }
}