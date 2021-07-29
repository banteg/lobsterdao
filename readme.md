# LobsterDAO

This uses a modified [MerkleDistributor](https://github.com/Uniswap/merkle-distributor), which allows to issue a lazy airdrop using temporary IDs.

In this example it uses Telegram `chat_id` to allocate to active users in a certain chat.
A user needs to provide a merkle proof of `(index, amount)`, as well as a signature of `(index, account)`.

A signer account verifies the address provided by a user and discards the temp ID.
This way it stays private if the full merkle tree is never publicized.
