// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract NFT is ERC721, VRFConsumerBase {
    struct Attribute {
        uint256 energy;
        uint256 speed;
        uint256 strength;
        uint256 color;
        uint256 rarity;
        uint256 size;
    }

    Attribute[] public attributes;

    bytes32 internal keyHash;
    uint256 internal fee;
    address public VRFCoordinator;
    address public LinkToken;

    mapping(bytes32 => string) requestToAttributeName;
    mapping(bytes32 => address) requestToSender;
    mapping(bytes32 => uint256) requestToTokenId;

    constructor(
        address _VRFCoordinator,
        address _LinkToken,
        bytes32 _keyhash
    )
        ERC721("NFTAttributes", "NAB")
        VRFConsumerBase(_VRFCoordinator, _LinkToken)
    {
        VRFCoordinator = _VRFCoordinator;
        LinkToken = _LinkToken;
        keyHash = _keyhash;
        fee = 0.1 ether;
    }

    // vrf 0x2ca8e0c643bde4c2e08ab1fa0da3401adad7734d
    // link token 0x326c977e6efc84e512bb9c30f76e30c160ed06fb
    // keyhash 0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15

    function requestNewRandomAttribute(
        string memory name
    ) public returns (bytes32) {
        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough LINK - fill contract with faucet"
        );
        bytes32 requestId = requestRandomness(keyHash, fee);
        requestToAttributeName[requestId] = name;
        requestToSender[requestId] = msg.sender;
        return requestId;
    }

    function fulfillRandomness(
        bytes32 requestId,
        uint256 randomNumber
    ) internal override {
        uint256 newId = attributes.length;
        uint256 energy = (randomNumber % 100);
        uint256 speed = ((randomNumber % 10000) / 100);
        uint256 strength = ((randomNumber % 1000000) / 10000);
        uint256 color = ((randomNumber % 100000000) / 1000000);
        uint256 rarity = ((randomNumber % 10000000000) / 100000000);
        uint256 size = ((randomNumber % 1000000000000) / 10000000000);

        attributes.push(
            Attribute(energy, speed, strength, color, rarity, size)
        );
        _safeMint(requestToSender[requestId], newId);
    }

    function getNumberOfAttributes() public view returns (uint256) {
        return attributes.length;
    }
}
