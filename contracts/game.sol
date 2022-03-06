//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

//Imported so function calls show correctly on explorer
import "./interfaces/IMinter.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

//using library for the majority of internal functions as to reduce gas units used in function calls
import "./libraries/gameLib.sol";

//importing of structs as they are used in multiple file
import "./structs/stats.sol";
import "./structs/gameVars.sol";

//importing receiver so that I can block people being dumb & sending NFTs to the contract
//apparently this is a common stupidity
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

//importing so msg.sender can be replaced with _msgSender() - this is more secure
import "@openzeppelin/contracts/utils/Context.sol";

//imports for oracle usage
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";

contract GameV3 is IERC721Receiver, Context, VRFConsumerBase{
    
    //does these need an explanation?
    event NewAdmin(address admin);
    event RaceChosen(string raceType);
    event QPRandomRequested();
    event CompRandomRequested();
    event DRRandomRequested();

    //imported the following events so that events showup on the explorer correctly
    //as the events are emitted in the library & do not show otherwise
    event InjuredRaptor(uint16 raptor);
    event FightWinner(uint16 raptor);
    event Fighters(uint16[2] fighters);
    event Top3(uint16[3] places);
    event QuickPlayRaceStarted(uint16[8] raptors);
    event QuickPlayRaceWinner(uint16 raptor);
    event CompetitiveRaceStarted(uint16[8] raptors);
    event CompetitiveRaceWinner(uint16 raptor);
    event DeathRaceStarted(uint16[8] raptors);
    event DeathRaceWinner(uint16 raptor);
    event RipRaptor(uint16 raptor);

    //wallet that controls the game
    address private admin;

    //an array of 8 tokenIds used for keeping track of the current list of tokens in queue
    uint16[8] private currentRaptors;

    //used to store the current balance for a race
    uint256 private pot;

    //fee storage for different races
    uint256 private QPFee;
    uint256 private CompFee;
    uint256 private DRFee;

    //used in oracle request generation
    uint256 private constant USER_SEED_PLACEHOLDER = 0;

    //the usage of prime numbers allows me to generate multiple random values from 1 random number
    //the reason I use large prime numbers is that they are only divisible by 1 or the prime number
    //this means that the end resulting numbers should not be trackable 
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
    
    //used for keeping track of oracle details
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

    //instantiates a set of the above variables
    VRF private vrf;

    //enumerator for keeping track of the current race that has been set
    enum CurrentRace {
        StandBy,
        QuickPlay,
        Competitive,
        DeathRace
    }

    //used for returning a string value of the game
    string[] raceNames =[
        "StandBy",
        "QuickPlay",
        "Competitive",
        "DeathRace"
    ];

    //instantiating a variable of the currentRace enumerator
    CurrentRace public currentRace;

    //instantiates a struct of gamevariables
    GameVars private currentVars;

    //wallet that will receive 5% of the pot of each race for buying NFTs from other community projects
    // & giving these away to the community to help bring exposure to upcoming projects 
    address payable private communityWallet;

    //used for keeping a track of how many raptors are currently in the queue
    uint16 private currentPosition;

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

    function setDist(uint32 dist) public onlyAdmin {
        gameLib.setDistance(dist);
    }

    //builds the struct of game variables to be passed to game library
    function buildVars(uint16[8] memory raptors, uint16[8] memory expandedNums, bool dr) internal returns (GameVars memory gameVars){
        currentVars.raptors = raptors;
        currentVars.expandedNums = expandedNums;
        currentVars.dr = dr;
        gameVars = currentVars;
    }

    //Select Race only callable by admin
    function raceSelect(uint8 choice)public onlyAdmin{
        require(choice >= 0 && choice <=3);
        currentRace = CurrentRace(choice);
        emit RaceChosen(raceNames[choice]);
    }

    //pays 95% of pot to the winner & 5% to the community wallet & resets the pot var to 0
    function _payOut(uint16 winner, uint payout,uint communityPayout) internal {
        payable(gameLib.getOwner(winner)).transfer(payout);
        communityWallet.transfer(communityPayout);
        pot =0;
    }
    
    //returns the array of tokenIDs currently in the queue - this also returns 0 in unfilled slots
    function getCurrentQueue() public view returns(uint16[8] memory raptors){
        return currentRaptors;
    }

    //Quickplay Entry
    function enterRaptorIntoQuickPlay(uint16 raptor) public payable {
        //check that current race is enabled
        require(uint(currentRace) == 1, "This race queue is not available at the moment");


        //check if there are spaces left
        require(currentRaptors[7] ==0, "You can not join at this time");

        //check the raptor is owned by msg.Sender
        require(gameLib.owns(raptor), "You do not own this raptor");

        //check that raptor is not on cooldown
        require(gameLib.getTime(raptor) < block.timestamp, "Your raptor is not available right now");

        //check that msg.value is the entrance fee
        require(msg.value == QPFee, "You have not sent enough funds");

        //add msg.value to pot
        pot += msg.value;

        //add raptor to the queue
        currentRaptors[currentPosition] = raptor;

        //increment current Position
        currentPosition += 1;

        //if 8 entrants then start race
        if(currentPosition ==8){
            getRandomNumber();
            emit QPRandomRequested();
        } 
    }

    //Competitive Entry
    function enterRaptorIntoComp(uint16 raptor) public payable {
        //check that current race is enabled
        require(uint(currentRace) == 2, "This race queue is not available at the moment");

        //check if there are spaces left
        require(currentRaptors[7] ==0, "You can not join at this time");

        //check that raptor is not on cooldown
        require(gameLib.getTime(raptor) < block.timestamp, "Your raptor is not available right now");

        //check the raptor is owned by msg.Sender
        require(gameLib.owns(raptor), "You do not own this raptor");

        //check that msg.value is the entrance fee
        require(msg.value == CompFee, "You have not sent enough funds");

        //add msg.value to pot
        pot += msg.value;

        //add raptor to the queue
        currentRaptors[currentPosition] = raptor;

        //increment current Position
        currentPosition += 1;

        //if 8 entrants then start race
        if(currentPosition == 8){
            getRandomNumber();
            emit CompRandomRequested();
        } 
    }

    //DeathRace Entry
    function enterRaptorIntoDR(uint16 raptor) public payable {
        //check that current race is enabled
        require(uint(currentRace) == 3, "This race queue is not available at the moment");

        //check if there are spaces left
        require(currentRaptors[7] ==0, "You can not join at this time");

        //check that raptor is not on cooldown
        require(gameLib.getTime(raptor) < block.timestamp, "Your raptor is not available right now");

        //check the raptor is owned by msg.Sender
        require(gameLib.owns(raptor), "You do not own this raptor");

        // gameLib._approve(raptor);

        //check that msg.value is the entrance fee
        require(msg.value == DRFee, "You have not sent enough funds");

        //add msg.value to pot
        pot += msg.value;

        //add raptor to the queue
        currentRaptors[currentPosition] = raptor;

        //increment current Position
        currentPosition += 1;

        //if 8 entrants then start race
        if(currentPosition == 8){
            getRandomNumber();
            emit DRRandomRequested();
        }  
    }

    //reverts before letting a ERC721 token be sent to this contract
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
    //stores the request ID to make sure the correct request ID is used on the callback from the oracle
    function getRandomNumber() internal  {
        require(vrf.LINK.balanceOf(address(this)) >= vrf.fee, "Not enough LINK balance");
        bytes32 requestId = requestRandomness(vrf.keyHash, vrf.fee);
        vrf.lastRequestId = requestId;
    }
    
    //------------------------------------------Helper Function----------------------------------------------
   
    //generates 8 random values from a given random value using the 8 prime numbers defined earlier
    function expand(uint256 _rnd) internal view returns(uint16[8] memory){
        uint16[8] memory expandedValues;
        for(uint8 i = 0; i<8 ; i++){
            expandedValues[i] = uint16(uint256(keccak256(abi.encode(_rnd,i))) % primes[i]);
        }
        return expandedValues;
    }
    //------------------------------------------Helper Function----------------------------------------------

    //-----------------------------------------Do Not Use These Functions In Your Contract----------------------
    //first function used in callback from VRF
    //requires that the _msgSender() is the VRFCoordinator
    function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external override{
        require(_msgSender() == vrf.vrfCoordinator, "Only VRFCoordinator can fulfill");
        fulfillRandomness(requestId, randomness);
    }

    //callback function used by VRF Coordinator
    //checks that the request ID is the correct request ID that we were expecting
    //declares the winner var before the if statements to save space as YUL allows only 16 slots
    //expands the randomnumber into 8 random numbers
    //starts the correct game logic dependant on what race is currently selected
    //deletes currentRace, currentRaptors & currentVars to set these back to null/0 for the next race
    //^this also reduces gas used in the function call allowing us to use more gas elsewhere
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        require(requestId == vrf.lastRequestId, "Err: WRID");
        vrf.randomResult = randomness;
        uint16[8] memory expandedNums;
        uint16 winner;
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
        requestId = makeRequestId(_keyHash, vRFSeed);
    }
    //-----------------------------------------Do Not Use These Functions In Your Contract----------------------


    //allows admin to withdraw LINK from the contract when changing to a new game contract
    function withdrawLink() public onlyAdmin {
        vrf.LINK.transfer(msg.sender, vrf.LINK.balanceOf(address(this)));
    }

}