// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract MyNFT is ERC721Enumerable, Ownable, VRFConsumerBase {
        
    // Chainlink VRF variables
    bytes32 internal keyHash;
    uint256 internal fee;
    uint256 public randomResult;
    uint256 public tokenIdCounter;

    // NFT traits
    struct NFTAttributes {
        uint256 energy;
        uint256 speed;
        uint256 strength;
        string color;
        string rarity;
        uint256 size;
    }

    // Mapping to track token IDs to their attributes
    mapping(uint256 => NFTAttributes) public tokenIdToAttributes;

    // Events
    event Minted(uint256 indexed tokenId, address indexed owner, uint256 energy, uint256 speed, uint256 strength, string color, string rarity, uint256 size);

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
        tokenIdCounter = 1;
    }

    // Mint function
    function mintNFT() external {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK tokens");
        uint256 requestId = requestRandomness(keyHash, fee);
        // Store the request ID for later use in fulfillRandomness
    }

    // Callback function for Chainlink VRF
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        require(msg.sender == vrfCoordinator, "Only VRF coordinator can fulfill");
        randomResult = randomness;
        uint256 energy = randomness % 101; // Random number between 0 and 100
        uint256 speed = (randomness >> 128) % 101; // Another random number between 0 and 100
        uint256 strength = (randomness >> 256) % 101; // Yet another random number between 0 and 100
        string memory color = "Blue"; // You can replace with actual color generation logic
        string memory rarity = "Common"; // You can replace with rarity calculation logic
        uint256 size = (randomness >> 384) % 101; // Another random number between 0 and 100
        
        // Create a new NFT with these traits
        NFTAttributes memory attributes = NFTAttributes(energy, speed, strength, color, rarity, size);
        tokenIdToAttributes[tokenIdCounter] = attributes;
        _mint(msg.sender, tokenIdCounter);
        emit Minted(tokenIdCounter, msg.sender, energy, speed, strength, color, rarity, size);
        tokenIdCounter++;
    }
}
