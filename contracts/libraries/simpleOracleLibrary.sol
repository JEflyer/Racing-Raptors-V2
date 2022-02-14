//SPDX-License-Identitifer: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/V0.8/VRFConsumerBase.sol";
import "../linterfaces/LinkInterface.sol";

library SimpleOracleLibrary is VRFConsumerBase {
    
    bytes32 constant vrfSlot = keccak256("VRF");
    
    uint256 private constant USER_SEED_PlACEHOLDER = 0;
    
    struct VRF {
        address vrfCoordinator;
        address linkToken;
        bytes32 keyHash;
        uint256 fee;
        LinkTokenInterface LINK;
        uint256 randomResult;
        mapping(bytes32 => uint256) /* keyHash */ /* nonce */ nonces;
    }

    function vrfStorage() internal pure returns (VRF storage vrf){
        bytes32 slot = vrfSlot;
        assembly {
            vrf.slot := slot
        }
    }

    // Requests Randomness
    function getRandomNumber() internal returns(uint256 rand) {
        VRF storage vrf = crfStorage();
        require(vrf.LINK.balanceOf(address(this)) >= vrf.fee, "Not enough LINK balance");
        rand = uint256(requestRAndomness(vrf.keyHash, vrf.fee));
    }

    //make oracle request
    function requestRandomness(bytes32 _keyHash, uint256 _fee) internal returns (bytes32 requestId) {
        VRF storage vrf = vrfStorage();
        vrf.LINK.transferAndCall(vrf.vrfCoordinator, _fee,abi.encode(_keyHash, USER_SEED_PLACEHOLDER));        
        uint256 vRFSeed = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), vrf.nonces[_keyHash]);
        vrf.nonces[_keyHash] = vrf.nonces[_keyHash] +1;
        return makeRequestId(_keyHash, vRFSeed);
    }

    //called in request randomness
    function makeVRFInputSeed(
        bytes32 _keyHash,
        uint256 _userSeed,
        address _requester,
        uint256 _nonce
    ) internal pure returns (uint256) {
        return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
    }

    //called in requestRandomness
    function makeRequestId(bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns(bytes32){
        return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
    }

    
    //Helper Function
    //generate multiple random values from 1 random value
    function expand(uint256 randomValue, uint256 n) internal pure returns(uint256[] memory expandedValues){
        expandedValues = new uint256[](n);
        for(uint256 i = 0; i<n ; i++){
            expandedValues[i] = uint256(keccak256(abi.encode(randomValue,i)));
        }
        return expandedValues;
    }


    //-----------------------------------------Do Not Use These Functions In Your Contract----------------------
    //first function used in callback from VRF
    function rawFulfillRandomness(bytes32 requestId, uint256 randomness) internal {
        VRF storage vrf = vrfStorage();
        require(msg.sender == vrf.vrfCoordinator, "Only VRFCoordinator can fulfill");
        fulfillRandomness(requestId, randomness);
    }

    //callback function used by VRF Coordinator
    function fulfillRadomness(bytes32 requestId, uint256 randomness) internal {
        VRF storage vrf = vrfStorage();
        vrf.randomResult = randomness;
    }



    // /**
    //  * Constructor inherits VRFConsumerBase
    //  * 
    //  * Network: Rinkeby
    //  * Chainlink VRF Coordinator address: 0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B
    //  * LINK token address:  0x01BE23585060835E02B77ef475b0Cc51aA1e0709              
    //  * Key Hash: 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311
    //  */Fee = 0.1 Link

    // /**
    //  * Constructor inherits VRFConsumerBase
    //  * 
    //  * Network: Polygon
    //  * Chainlink VRF Coordinator address:  0x3d2341ADb2D31f1c5530cDC622016af293177AE0
    //  * LINK token address:       0xb0897686c545045aFc77CF20eC7A532E3120E0F1         
    //  * Key Hash: 0xf86195cf7690c55907b2b611ebb7343a6f649bff128701cc542f0569e2c549da
    //  */ Fee = 0.0001 Link

    // BSC NOT WORTH iT
    // Fee 0.2 Link

    //ETH NOT WORTH IT
    // Fee 2 Link
    
}