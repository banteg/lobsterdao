import json
import pytest
from eth_account import Account

@pytest.fixture(scope='function', autouse=True)
def shared_setup(fn_isolation):
   pass


@pytest.fixture()
def merkle():
   return json.load(open('merkle.json'))


@pytest.fixture()
def lobs(a, merkle, Lobs):
   return Lobs.deploy(merkle['tokenTotal'], {'from': a[0]})

@pytest.fixture()
def ivan():
   return Account.create()

@pytest.fixture()
def recipient(a):
   return a[2]

@pytest.fixture()
def airdrop(a, merkle, lobs, ivan, Airdrop):
   airdrop = Airdrop.deploy(
      lobs,
      merkle['merkleRoot'],
      ivan.address,
      {'from': a[0]}
   )
   lobs.transfer(airdrop, merkle['tokenTotal'])
   return airdrop
