//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./interfaces/IGame.sol";
import "./interfaces/IMinter.sol";

import "./libraries/gameLib.sol";

import "./structs/stats.sol";
import "./structs/gameVars.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";

contract Game is IERC721Receiver, Context, VRFConsumerBase{

    event NewAdmin(address admin);
    event UpdatedStats(uint16 raptor, Stats stats);

    event RaceChosen(string raceType);

    address private admin;

    uint16[8] public currentRaptors;

    uint256 public pot;

    uint256 public QPFee;
    uint256 public CompFee;
    uint256 public DRFee;

    uint256 private constant USER_SEED_PLACEHOLDER = 0;

    uint64[] private primes = [
        6619,
        6719,
        7309,
        7393,
        7853,
        7919,
        7727,
        3167
    ];
    
    struct VRF {
        address vrfCoordinator;
        address linkToken;
        bytes32 keyHash;
        uint256 fee;
        LinkTokenInterface LINK;
        uint256 randomResult;
        mapping(bytes32 => uint256) /* keyHash */ /* nonce */ nonces;
        bytes32 lastRequestId;
    }

    VRF private vrf;

    enum CurrentRace {
        StandBy,
        QuickPlay,
        Competitive,
        DeathRace
    }

    string[] raceNames =[
        "StandBy",
        "QuickPlay",
        "Competitive",
        "DeathRace"
    ];

    CurrentRace public currentRace;
    GameVars private currentVars;

    address payable private communityWallet;
    uint16 private currentPosition;
    uint32 private distance;

    constructor(
        address _minterContract,
        address _communityWallet,
        uint256 _Fee,
        address _vrfCoordinator,
        address _linkToken,
        bytes32 _keyHash,
        uint256 _OracleFee,
        uint32 _distance
    ) VRFConsumerBase( _vrfCoordinator, _linkToken){
        gameLib.setDistance(_distance);
        vrf.LINK = LinkTokenInterface(_linkToken);
        vrf.vrfCoordinator = _vrfCoordinator;
        vrf.linkToken = _linkToken;
        vrf.keyHash = _keyHash;
        vrf.fee = _OracleFee;
        gameLib.setMinter(_minterContract);
        admin = _msgSender();
        communityWallet = payable(_communityWallet);
        pot =0;
        QPFee = _Fee;
        CompFee = _Fee * 5;
        DRFee = _Fee * 25;
        currentPosition = 0;
    }    

    modifier onlyAdmin {
        require(msg.sender == admin, "You can not call this function");
        _;
    }

    function buildVars(uint16[8] memory raptors, uint16[8] memory expandedNums, bool dr) internal returns (GameVars memory gameVars){
        currentVars.raptors = raptors;
        currentVars.expandedNums = expandedNums;
        currentVars.dr = dr;
        gameVars = currentVars;
    }

    //Select Race
    function raceSelect(uint8 choice)public onlyAdmin{
        require(choice >= 0 && choice <=3);
        currentRace = CurrentRace(choice);
        emit RaceChosen(raceNames[choice]);
    }

    function _payOut(uint16 winner, uint payout,uint communityPayout) internal returns(bool){
        payable(gameLib.getOwner(winner)).transfer(payout);
        communityWallet.transfer(communityPayout);
        pot =0;
        return true;
    }
    
    function getCurrentQueue() public view returns(uint16[8] memory raptors){
        return currentRaptors;
    }

    //Quickplay Entry
    function enterRaptorIntoQuickPlay(uint16 raptor) public payable {
        //check that current race is enabled
        require(uint(currentRace) == 1, "This race queue is not available at the moment");


        //check if there are spaces left
        require(currentRaptors.length <8, "You can not join at this time");

        //check the raptor is owned by _msgSender()
        require(gameLib.owns(raptor), "You do not own this raptor");

        //check that raptor is not on cooldown
        require(gameLib.getTime(raptor) < block.timestamp, "Your raptor is not available right now");

        //check that msg.value is the entrance fee
        require(msg.value == QPFee, "You have not sent enough funds");

        //add msg.value to pot
        pot += msg.value;

        //add raptor to the queue
        currentRaptors[currentPosition];

        //increment current Position
        currentPosition = uint8(currentRaptors.length);

        //if 8 entrants then start race
        if(currentPosition ==8){
            getRandomNumber();
        } 
    }

    //Competitive Entry
    function enterRaptorIntoComp(uint16 raptor) public payable {
        //check that current race is enabled
        require(uint(currentRace) == 2, "This race queue is not available at the moment");

        //check if there are spaces left
        require(currentRaptors.length < 8, "You can not join at this time");

        //check that raptor is not on cooldown
        require(gameLib.getTime(raptor) < block.timestamp, "Your raptor is not available right now");

        //check the raptor is owned by _msgSender()
        require(gameLib.owns(raptor), "You do not own this raptor");

        //check that msg.value is the entrance fee
        require(msg.value == CompFee, "You have not sent enough funds");

        //add msg.value to pot
        pot += msg.value;

        //add raptor to the queue
        currentRaptors[currentPosition];

        //increment current Position
        currentPosition = uint16(currentRaptors.length);

        //if 8 entrants then start race
        if(currentPosition == 8){
            getRandomNumber();
        } 
    }

    //DeathRace Entry
    function enterRaptorIntoDR(uint16 raptor) public payable {
        //check that current race is enabled
        require(uint(currentRace) == 3, "This race queue is not available at the moment");

        //check if there are spaces left
        require(currentRaptors.length < 8, "You can not join at this time");

        //check that raptor is not on cooldown
        require(gameLib.getTime(raptor) < block.timestamp, "Your raptor is not available right now");

        //check the raptor is owned by _msgSender()
        require(gameLib.owns(raptor), "You do not own this raptor");

        //check that msg.value is the entrance fee
        require(msg.value == DRFee, "You have not sent enough funds");

        //add msg.value to pot
        pot += msg.value;

        //add raptor to the queue
        currentRaptors[currentPosition];

        //increment current Position
        currentPosition = uint16(currentRaptors.length);

        //if 8 entrants then start race
        if(currentPosition == 8){
            getRandomNumber();
        }  
    }

    function onERC721Received(
        address operator, 
        address from, 
        uint256 tokenId, 
        bytes calldata data) external pure override returns (bytes4) {
        revert();
        return IERC721Receiver.onERC721Received.selector;
    }

    //------------------------------------Oracle functions--------------------------------------------//

    // Requests Randomness
    function getRandomNumber() internal  {
        require(vrf.LINK.balanceOf(address(this)) >= vrf.fee, "Not enough LINK balance");
        bytes32 requestId = requestRandomness(vrf.keyHash, vrf.fee);
        vrf.lastRequestId = requestId;
    }
    
    //------------------------------------------Helper Function----------------------------------------------
   
    //generate n random values from random value
    function expand(uint256 _rnd) internal view returns(uint16[8] memory){
        uint16[8] memory expandedValues;
        for(uint256 i = 0; i<8 ; i++){
            expandedValues[i] = uint16(uint256(keccak256(abi.encode(_rnd,i))) % primes[i]);
        }
        return expandedValues;
    }
    //------------------------------------------Helper Function----------------------------------------------

    //-----------------------------------------Do Not Use These Functions In Your Contract----------------------
    //first function used in callback from VRF
    function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external override{
        require(msg.sender == vrf.vrfCoordinator, "Only VRFCoordinator can fulfill");
        fulfillRandomness(requestId, randomness);
    }

    //callback function used by VRF Coordinator
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        require(requestId == vrf.lastRequestId);
        vrf.randomResult = randomness;
        uint16[8] memory expandedNums;
        uint16 winner;
        uint fee;
        uint prize;
        expandedNums = expand(vrf.randomResult);
        if(uint(currentRace) == 1){
            winner = gameLib._quickPlayStart(buildVars(currentRaptors,expandedNums,false));
            currentPosition = 0;
            _payOut(winner, gameLib.calcPrize(pot), gameLib.calcFee(pot));
            delete currentRace;
            delete currentRaptors;
            delete currentVars;
        }
        else if(uint(currentRace) == 2){
            winner = gameLib._compStart(buildVars(currentRaptors,expandedNums,false));
            currentPosition = 0;
            _payOut(winner, gameLib.calcPrize(pot), gameLib.calcFee(pot));            
            delete currentRace;
            delete currentRaptors;
            delete currentVars;
        }
        else if(uint(currentRace) == 3){
            winner = gameLib._deathRaceStart(buildVars(currentRaptors,expandedNums,true));
            currentPosition = 0;
            _payOut(winner, gameLib.calcPrize(pot), gameLib.calcFee(pot));
            delete currentRace;
            delete currentRaptors;
            delete currentVars;
        }
    }

    //called in request randomness
    function makeVRFInputSeed(
        bytes32 _keyHash,
        uint256 _userSeed,
        address _requester,
        uint256 _nonce
    ) internal pure override returns (uint256) {
        return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
    }

    //called in requestRandomness
    function makeRequestId(bytes32 _keyHash, uint256 _vRFInputSeed) internal pure override returns(bytes32){
        return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
    }

    //make oracle request
    function requestRandomness(bytes32 _keyHash, uint256 _fee) internal override returns(bytes32 requestId) {
        vrf.LINK.transferAndCall(vrf.vrfCoordinator, _fee,abi.encode(_keyHash, USER_SEED_PLACEHOLDER));        
        uint256 vRFSeed = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), vrf.nonces[_keyHash]);
        vrf.nonces[_keyHash] = vrf.nonces[_keyHash] +1;
        bytes32 requestId = makeRequestId(_keyHash, vRFSeed);
    }
    //-----------------------------------------Do Not Use These Functions In Your Contract----------------------



    function withdrawLink() public onlyAdmin {
        vrf.LINK.transfer(msg.sender, vrf.LINK.balanceOf(address(this)));
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