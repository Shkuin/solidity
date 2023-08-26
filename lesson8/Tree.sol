// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// Merkle tree

contract Tree {
    bytes32[] public hashes;
    string[4] transactions = [
        "TX1: Sherlock -> John",
        "TX2: John -> Sherlock",
        "TX3: John -> Mary",
        "TX3: Mary -> Sherlock"
    ];

    constructor() {// this code is not so efficient as in lesson it works for O(n
        for (uint8 i = 0; i < transactions.length; i++) {
            hashes.push(makeHash(transactions[i]));
        }

        for (uint8 i = 0; i <= transactions.length + 1; i += 2) {
            hashes.push(keccak256(abi.encodePacked(hashes[i], hashes[i + 1])));
        }
    }

    function encode(string memory transactions) public pure returns(bytes memory) {
        return abi.encodePacked(transactions); // кодируем транзакцию
    }

    function makeHash(string memory transaction) public pure returns(bytes32) {
        return keccak256(encode(transaction)); // возвращает 32байтный хэш
    }

    function validateTransaction(string memory transaction, uint index) public view returns(bool) {
        bytes32 hashToCheck = makeHash(transaction);
        while (index < hashes.length - 1) {
            if (index % 2 == 0) {
                hashToCheck = keccak256(abi.encodePacked(hashToCheck, hashes[index + 1]));
            }
            else {
                hashToCheck = keccak256(abi.encodePacked(hashes[index - 1], hashToCheck));
            }
            index = transactions.length + index / 2;
        }

        return hashToCheck == hashes[hashes.length - 1];
    }

}