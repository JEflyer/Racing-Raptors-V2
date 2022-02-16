//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./interfaces/IGame.sol";
import "./interfaces/IMinter.sol";

import "./libraries/gameLib.sol";

import "./structs/stats.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol";

contract Game is IERC721Receiver, Context{

    event NewAdmin(address admin);
    event UpdatedStats(uint16 raptor, Stats stats);

    event RaceChosen(string raceType);

    address private admin;

    uint16[] public currentRaptors = new uint16[](8);

    uint256 public pot;

    uint256 public QPFee;
    uint256 public CompFee;
    uint256 public DRFee;

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

    address payable private communityWallet;
    uint16 private currentPosition;

    constructor(
        address _minterContract,
        address _communityWallet,
        uint256 _QPFee,
        uint256 _CompFee,
        uint256 _DRFee
    ){
        gameLib.SetMinter(_minterContract);
        admin = _msgSender();
        communityWallet = payable(_communityWallet);
        currentRace = CurrentRace(0);
        pot =0;
        QPFee = _QPFee;
        CompFee = _CompFee;
        DRFee = _DRFee;
        currentPosition = 0;
    }

    

    modifier onlyAdmin {
        require(msg.sender == admin, "You can not call this function");
        _;
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
        return true;
    }
    

    //Quickplay Entry
    function enterRaptorIntoQuickPlay(uint16 raptor) public payable returns (bool){
        //check that current race is enabled
        require(uint(currentRace) == 1, "This race queue is not available at the moment");


        //check if there are spaces left
        require(currentRaptors.length <=8, "You can not join at this time");

        //check the raptor is owned by _msgSender()
        require(gameLib.owns(raptor), "You do not own this raptor");

        //check that raptor is not on cooldown
        require(gameLib.getStats(raptor).cooldownTime < block.timestamp, "Your raptor is not available right now");

        //check that msg.value is the entrance fee
        require(msg.value == QPFee, "You have not sent enough funds");

        //add msg.value to pot
        pot += msg.value;

        //add raptor to the queue
        currentRaptors[currentPosition];

        //increment current Position
        currentPosition = uint8(currentRaptors.length);

        //if 8 entrants then start race
        if(currentRaptors.length == 8){
            uint16 winner = gameLib._quickPlayStart(currentRaptors, pot);
            currentPosition = 0;
            uint fee = gameLib.calcFee(pot);
            uint prize = gameLib.calcPrize(pot);
            _payOut(winner, prize, fee);
        } 
    }

    //Competitive Entry
    function enterRaptorIntoComp(uint16 raptor) public payable returns (bool){
        //check that current race is enabled
        require(uint(currentRace) == 2, "This race queue is not available at the moment");

        //check if there are spaces left
        require(currentRaptors.length <=8, "You can not join at this time");

        //check that raptor is not on cooldown
        require(gameLib.getStats(raptor).cooldownTime < block.timestamp, "Your raptor is not available right now");

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
        if(currentRaptors.length == 8){
            uint16 winner = gameLib._compStart(currentRaptors, pot);
            currentPosition = 0;
            uint fee = gameLib.calcFee(pot);
            uint prize = gameLib.calcPrize(pot);
            _payOut(winner, prize, fee);
        } 
    }

    //DeathRace Entry
    function enterRaptorIntoDR(uint16 raptor) public payable returns(bool){
        //check that current race is enabled
        require(uint(currentRace) == 3, "This race queue is not available at the moment");

        //check if there are spaces left
        require(currentRaptors.length <=8, "You can not join at this time");

        //check that raptor is not on cooldown
        require(gameLib.getStats(raptor).cooldownTime < block.timestamp, "Your raptor is not available right now");

        //check the raptor is owned by _msgSender()
        require(gameLib.owns(raptor), "You do not own this raptor");

        //check that msg.value is the entrance fee
        require(msg.value == DRFee, "You have not sent enough funds");

        //add msg.value to pot
        pot += msg.value;

        //add raptor to the queue
        currentRaptors[currentPosition];

        //increment current Position
        currentPosition = currentRaptors.length;

        //if 8 entrants then start race
        if(currentRaptors.length == 8){
            uint16 winner = gameLib._deathRaceStart(currentRaptors, pot);
            currentPosition = 0;
            uint fee = gameLib.calcFee(pot);
            uint prize = gameLib.calcPrize(pot);
            _payOut(winner, prize, fee);
        }  
    }

    function onERC721Received(
        address operator, 
        address from, 
        uint256 tokenId, 
        bytes calldata data) external override returns (bytes4) {
        revert();
        return IERC721Receiver.onERC721Received.selector;
    }
}