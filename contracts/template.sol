// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyNFT is ERC721Enumerable, Ownable, VRFConsumerBase {
    // Chainlink VRF variables
    bytes32 internal keyHash;
    uint256 internal fee;

    // NFT traits
    struct NFTAttributes {
        uint256 energy;
        uint256 speed;
        // Add more traits as needed
    }

    NFTAttributes[] public nftAttributes;

    // Mapping to track token IDs to their attributes
    mapping(uint256 => uint256) public tokenIdToAttributes;

    // Constructor
    constructor(
        address _vrfCoordinator,
        address _linkToken,
        bytes32 _keyHash,
        uint256 _fee
    )
        ERC721("MyNFT", "NFT")
        VRFConsumerBase(_vrfCoordinator, _linkToken)
    {
        keyHash = _keyHash;
        fee = _fee;
    }

    // Mint function
    function mintNFT() external {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK tokens");
        uint256 requestId = requestRandomness(keyHash, fee);
        // Store the request ID for later use in fulfillRandomness
        // You can associate the requestId with the token being minted
    }

    // Callback function for Chainlink VRF
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        uint256 energy = randomness % 101; // Random number between 0 and 100
        uint256 speed = (randomness >> 128) % 101; // Another random number between 0 and 100
        // Create a new NFT with these traits
        nftAttributes.push(NFTAttributes(energy, speed));
        uint256 tokenId = totalSupply() + 1;
        tokenIdToAttributes[tokenId] = nftAttributes.length - 1;
        _mint(msg.sender, tokenId);
    }
}
