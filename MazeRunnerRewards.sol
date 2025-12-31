// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MazeRunnerRewards is Ownable {
    using ECDSA for bytes32;

    uint256 public rewardAmount = 0.001 ether;
    mapping(bytes32 => bool) public usedHashes;

    address public signer; // your backend / wallet that signs wins

    constructor(address _signer) {
        signer = _signer;
    }

    function setRewardAmount(uint256 amount) external onlyOwner {
        rewardAmount = amount;
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function claimWin(
        address player,
        uint256 nonce,
        bytes calldata signature
    ) external {
        bytes32 hash = keccak256(
            abi.encodePacked(player, nonce, address(this))
        );

        require(!usedHashes[hash], "Already claimed");

        bytes32 ethHash = hash.toEthSignedMessageHash();
        address recovered = ethHash.recover(signature);

        require(recovered == signer, "Invalid signature");

        usedHashes[hash] = true;

        (bool sent, ) = player.call{value: rewardAmount}("");
        require(sent, "ETH transfer failed");
    }

    receive() external payable {}
}
