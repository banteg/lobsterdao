from eth_abi.packed import encode_abi_packed
from eth_account.messages import encode_defunct
from eth_abi.packed import encode_abi_packed
from brownie import web3

def test_merkle(lobs, airdrop, merkle, ivan, recipient):
    identifier = '375542731'
    claim = merkle['claims'][identifier]
    # a user provides an address, ivan verifies their identifier (e.g. chat_id) an signs the digest
    digest = encode_defunct(web3.keccak(encode_abi_packed(['uint', 'address'], [claim['index'], str(recipient)])))
    sig = ivan.sign_message(digest)
    signature = encode_abi_packed(['uint256', 'uint256', 'uint8'], [sig.r, sig.s, sig.v])
    # claim the airdrop
    tx = airdrop.claim(claim['index'], claim['amount'], claim['proof'], recipient, signature, {'from': recipient})
    tx.info()
    assert lobs.balanceOf(recipient) == claim['amount']
