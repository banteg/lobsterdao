import json
from eth_account import Account
from eth_abi.packed import encode_abi_packed
from eth_account.messages import encode_defunct
from eth_abi.packed import encode_abi_packed
from brownie import web3


def produce_signature(signer, index, account):
    digest = encode_defunct(web3.keccak(encode_abi_packed(['uint', 'address'], [index, account])))
    sig = signer.sign_message(digest)
    signature = encode_abi_packed(['uint256', 'uint256', 'uint8'], [sig.r, sig.s, sig.v])
    return signature
    

def main():
    ivan = Account.create()
    data = json.load(open('merkle.json'))

    while True:
        identifier = input('chat_id? ')
        if identifier not in data['claims']:
            print('unknown identifier')
            continue
        
        claim = data['claims'][identifier]
        # manually verified by ivan, a bot could just match by chat_id
        account = input('account? ')
        signature = produce_signature(ivan, claim['index'], account)
        print(identifier, claim['index'], account, signature.hex())
