import json
import os

import telebot
from brownie import Airdrop, Lobs, accounts, web3
from eth_abi.packed import encode_abi_packed
from eth_account import Account
from eth_account.messages import encode_defunct
from eth_utils import is_address, to_checksum_address

merkle = json.load(open('merkle.json'))
deployer = accounts[0]
signer = Account.create()
bot = telebot.TeleBot(os.environ['BOT_TOKEN'], parse_mode=None)


def deploy():
    lobs = Lobs.deploy(merkle['tokenTotal'], {'from': deployer})
    airdrop = Airdrop.deploy(
        lobs,
        merkle['merkleRoot'],
        signer.address,
        {'from': deployer}
    )
    lobs.transfer(airdrop, merkle['tokenTotal'])


def is_claimed(index):
    return Airdrop[0].isClaimed(index)


def produce_signature(signer, index, account):
    digest = encode_defunct(web3.keccak(encode_abi_packed(['uint', 'address'], [index, account])))
    s = signer.sign_message(digest)
    return encode_abi_packed(['uint256', 'uint256', 'uint8'], [s.r, s.s, s.v])


def encode_data(claim, account, signature):
    return Airdrop[0].claim.encode_input(
        claim['index'], claim['amount'], claim['proof'], account, signature
    )


@bot.message_handler(func=lambda message: True)
def handle_other(message):
    if message.chat.type != 'private':
        return

    claim = merkle['claims'].get(str(message.chat.id))

    if claim is None:
        return bot.send_message(message.chat.id, "you don't have an allocation")
    
    if is_claimed(claim['index']):
        return bot.send_message(message.chat.id, "allocation already claimed")

    if is_address(message.text):
        bot.send_message(message.chat.id, f"perfect, your lobsters are on their way")
        account = to_checksum_address(message.text)
        signature = produce_signature(signer, claim['index'], account)
        data = encode_data(claim, account, signature)
        bot.send_message(message.chat.id, f'to: {Airdrop[0]}\ndata: {data}')

    else:
        amount = claim['amount']
        bot.send_message(message.chat.id, f"you can claim {amount} 🦞, reply with your eth address")


def main():
    deploy()
    bot.polling()
