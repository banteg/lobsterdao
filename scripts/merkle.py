from brownie import web3
from eth_utils import encode_hex
from itertools import zip_longest
from typing import List
import pandas as pd
from eth_abi.packed import encode_abi_packed
import json


def main():
    df = pd.read_csv('lobsterdao-2021-07-29.csv')
    elements = [
        (index, row.id, row.days)
        for index, row in df.iterrows()
        if row.days > 0
    ]
    # store as (index, chat_id, amount)
    nodes = [
        encode_hex(encode_abi_packed(["uint", "uint"], [el[0], el[2]]))
        for el in elements
    ]
    tree = MerkleTree(nodes)
    distribution = {
        "merkleRoot": encode_hex(tree.root),
        "tokenTotal": int(df.days.sum()),
        "claims": {
            int(user): {
                "index": int(index),
                "amount": int(amount),
                "proof": tree.get_proof(nodes[index]),
            }
            for index, user, amount in elements
        },
    }
    with open('merkle.json', 'wt') as f:
        json.dump(distribution, f, indent=2)


class MerkleTree:
    def __init__(self, elements: List[bytes]):
        self.elements = sorted(set(web3.keccak(hexstr=el) for el in elements))
        self.layers = MerkleTree.get_layers(self.elements)

    @property
    def root(self):
        return self.layers[-1][0]

    def get_proof(self, el):
        el = web3.keccak(hexstr=el)
        idx = self.elements.index(el)
        proof = []
        for layer in self.layers:
            pair_idx = idx + 1 if idx % 2 == 0 else idx - 1
            if pair_idx < len(layer):
                proof.append(encode_hex(layer[pair_idx]))
            idx //= 2
        return proof

    @staticmethod
    def get_layers(elements):
        layers = [elements]
        while len(layers[-1]) > 1:
            layers.append(MerkleTree.get_next_layer(layers[-1]))
        return layers

    @staticmethod
    def get_next_layer(elements):
        return [
            MerkleTree.combined_hash(a, b)
            for a, b in zip_longest(elements[::2], elements[1::2])
        ]

    @staticmethod
    def combined_hash(a, b):
        if a is None:
            return b
        if b is None:
            return a
        return web3.keccak(b"".join(sorted([a, b])))
