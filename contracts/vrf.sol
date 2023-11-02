// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "base64-sol/base64.sol";

contract GontarV9 is VRFConsumerBaseV2, ConfirmedOwner, ERC721URIStorage {
    //events when request is made to VRF and minted
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);

    using Strings for uint256;
    using Counters for Counters.Counter;

    //Keeps track of minted NFTS
    Counters.Counter private _tokenIds;

    //our uploaded nft image uri on NFT.STORAGE
    string private _imageURI =
        "ipfs://bafkreidpk7kydybncbbtf4br4ifvchqpfjalj74cxmgdnnsfuzgltkm3r4";

    //struct to contain our minted NFT attributes onchain
    struct GontarPack {
        uint256 energy;
        uint256 speed;
        uint256 jump;
        uint256 stamina;
        uint256 physique;
        uint256 focus;
    }

    //Max number of NFTs to be minted
    uint256 constant MAX_VALUE = 100;

    //mapping of NFT token id to attributes
    mapping(uint => GontarPack) public gontarPacks;

    //struct to get the request status of the request id from VRF
    struct RequestStatus {
        bool fulfilled; // whether the request has been successfully fulfilled
        bool exists; // whether a requestId exists
        uint256[] randomWords;
    }

    mapping(uint256 => RequestStatus)
        public s_requests; /* requestId --> requestStatus */
    VRFCoordinatorV2Interface COORDINATOR;

    // Your subscription ID.
    uint64 s_subscriptionId;

    // past requests Id.
    uint256 public lastRequestId;

    // vrf 0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D
    // link token 0x326c977e6efc84e512bb9c30f76e30c160ed06fb
    // keyhash 0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15

    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/docs/vrf/v2/subscription/supported-networks/#configurations
    bytes32 keyHash =
        0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15;

    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
    // so 100,000 is a safe default for this example contract. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    uint32 callbackGasLimit = 1000000;

    // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 3;

    // For this example, retrieve 6random values in one request.
    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
    uint32 numWords = 6;

    constructor(
        uint64 subscriptionId
    )
        ERC721("Gontar Warriors", "GTWRS")
        VRFConsumerBaseV2(0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D)
        ConfirmedOwner(msg.sender)
    {
        COORDINATOR = VRFCoordinatorV2Interface(
            0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D
        );
        s_subscriptionId = subscriptionId;
    }

    function setNFTTraits(
        uint256 randNum1,
        uint256 randNum2,
        uint256 randNum3,
        uint256 randNum4,
        uint256 randNum5,
        uint256 randNum6
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "{",
                    '"trait_type": "energy",',
                    '"value": ',
                    randNum1.toString(),
                    ",",
                    '"max_value": ',
                    MAX_VALUE.toString(),
                    "}",
                    ",",
                    "{",
                    '"trait_type": "speed",',
                    '"value": ',
                    randNum2.toString(),
                    ",",
                    '"max_value": ',
                    MAX_VALUE.toString(),
                    "}",
                    ",",
                    "{",
                    '"trait_type": "jump",',
                    '"value": ',
                    randNum3.toString(),
                    ",",
                    '"max_value": ',
                    MAX_VALUE.toString(),
                    "}",
                    ",",
                    "{",
                    '"trait_type": "stamina",',
                    '"value": ',
                    randNum4.toString(),
                    ",",
                    '"max_value": ',
                    MAX_VALUE.toString(),
                    "}",
                    ",",
                    "{",
                    '"trait_type": "physique",',
                    '"value": ',
                    randNum5.toString(),
                    ",",
                    '"max_value": ',
                    MAX_VALUE.toString(),
                    "}",
                    ",",
                    "{",
                    '"trait_type": "focus",',
                    '"value": ',
                    randNum6.toString(),
                    ",",
                    '"max_value": ',
                    MAX_VALUE.toString(),
                    "}"
                )
            );
    }

    function getTokenURI(
        uint256 tokenId,
        uint256 randNum1,
        uint256 randNum2,
        uint256 randNum3,
        uint256 randNum4,
        uint256 randNum5,
        uint256 randNum6
    ) public view returns (string memory) {
        string memory dataURI = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        "{",
                        '"name": "Gontar #',
                        tokenId.toString(),
                        '",',
                        '"description": "Battles on chain",',
                        '"image": "',
                        _imageURI,
                        '",',
                        '"attributes": [',
                        setNFTTraits(
                            randNum1,
                            randNum2,
                            randNum3,
                            randNum4,
                            randNum5,
                            randNum6
                        ),
                        "]",
                        "}"
                    )
                )
            )
        );
        return
            string(abi.encodePacked("data:application/json;base64,", dataURI));
    }

    // Assumes the subscription is funded sufficiently.
    function requestRandomWords()
        external
        onlyOwner
        returns (uint256 requestId)
    {
        // Will revert if subscription is not set and funded.
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        s_requests[requestId] = RequestStatus({
            randomWords: new uint256[](0),
            exists: true,
            fulfilled: false
        });
        lastRequestId = requestId;
        emit RequestSent(requestId, numWords);
        return requestId;
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        require(s_requests[_requestId].exists, "request not found");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;
        emit RequestFulfilled(_requestId, _randomWords);
    }

    function getRequestStatus(
        uint256 _requestId
    ) public view returns (bool fulfilled, uint256[] memory randomWords) {
        require(s_requests[_requestId].exists, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        return (request.fulfilled, request.randomWords);
    }

    function mint(uint256 _requestId) public {
        //this simply returns the status of a request we made to Chainlink VRF
        (bool fufilled, uint256[] memory randomWords) = getRequestStatus(
            _requestId
        );

        //checks to confirm that our request was fulfilled
        require(fufilled, "Request not fufilled");

        //a function by ERC721 that increase counts when NFT is minted
        _tokenIds.increment();

        uint256 tokenID = _tokenIds.current();

        //a function by ERC721 for minting our NFT to the account that makes the request
        _safeMint(msg.sender, newItemId);

        //This simply divides our random values by 101, and then returns a remainder
        //which might be between 0-100. Tis will be our attributes value
        uint256 randNum1 = randomWords[1] % 101;
        gontarPacks[newItemId].energy = randNum2;
        uint256 randNum2 = randomWords[2] % 101;
        gontarPacks[newItemId].speed = randNum3;
        uint256 randNum3 = randomWords[3] % 101;
        gontarPacks[newItemId].jump = randNum4;
        uint256 randNum4 = randomWords[4] % 101;
        gontarPacks[newItemId].stamina = randNum5;
        uint256 randNum5 = randomWords[5] % 101;
        gontarPacks[newItemId].physique = randNum6;
        uint256 randNum6 = randomWords[6] % 101;
        gontarPacks[tokenID].focus = randNum7;

        //sets token uri to a the tokenID and the randomly generated attributes
        _setTokenURI(
            tokenID,
            getTokenURI(
                newItemId,
                randNum1,
                randNum2,
                randNum3,
                randNum4,
                randNum5,
                randNum6
            )
        );
    }

    function getGontarPacks(
        uint256 _tokenId
    ) public view returns (GontarPack memory) {
        return gontarPacks[_tokenId];
    }
}
