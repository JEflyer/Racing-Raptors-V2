//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./interfaces/IGame.sol";
import "./interfaces/IMinter.sol";

import "./libraries/gameLib.sol";

import "./structs/stats.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/blob/master/contracts/utils/Context.sol";

contract Game is IGame, IERC721Receiver, Context, IERC721, Stats, gameLib, IMinter {

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
    ]

    CurrentRace public currentRace;

    constructor(
        address _minterContract,
        address _communityWallet,
        uint256 _QPFee,
        uint256 _CompFee,
        uint256 _DRFee
    ){
        gameLib.SetMinter(_minterContract);
        admin = _msgSender();
        gameLib.SetCommunityWallet(_communityWallet);
        currentRace = CurrentRace(0);
        pot =0;
        QPFee = _QPFee;
        CompFee = _CompFee;
        DRFee = _DRFee;
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

    

    //Quickplay Entry
    function enterRaptorIntoQuickPlay(uint16 raptor) public payable returns (bool){
        //check that current race is enabled
        require(currentRace == 1, "This race queue is not available at the moment");


        //check if there are spaces left
        require(currentRaptors.length() <=8, "You can not join at this time");

        //check the raptor is owned by _msgSender()
        require(gameLib.owns(raptor), "You do not own this raptor");

        //check that raptor is not on cooldown
        require(gameLib.getStats(raptor).cooldownTime < block.TimeStamp(), "Your raptor is not available right now");

        //check that msg.value is the entrance fee
        require(msg.value == QPFee, "You have not sent enough funds");

        //add msg.value to pot
        pot += msg.value;

        //add raptor to the queue
        curentRaptors[currentPosition];

        //increment current Position
        currentPosition = currentRaptors.length();

        //if 8 entrants then start race
        if(currentRaptors == 8){
            gameLib._quickPlayStart(currentRaptors, pot);
            emit QuickPlayRaceStarted(currentRaptors, pot);
            currentPosition = 0;
        } 
    }

    //Competitive Entry
    function enterRaptorIntoComp(uint16 raptor) public payable returns (bool){
        //check that current race is enabled
        require(currentRace == 2, "This race queue is not available at the moment");

        //check if there are spaces left
        require(currentRaptors.length <=8, "You can not join at this time");

        //check the raptor is owned by _msgSender()
        require(gameLib.owns(raptor), "You do not own this raptor");

        //check that msg.value is the entrance fee
        require(msg.value == CompFee, "You have not sent enough funds");

        //add msg.value to pot
        pot += msg.value;

        //add raptor to the queue
        curentRaptors[currentPosition];

        //increment current Position
        currentPosition = currentRaptors.length()

        //if 8 entrants then start race
        if(currentRaptors == 8){
            gameLib._compStart(currentRaptors, pot);
            emit CompetitiveRaceStarted(currentRaptors, pot);
            currentPosition = 0;
        } 
    }

    //DeathRace Entry
    function enterRaptorIntoDR(uint16 raptor) public payable returns(bool){
        //check that current race is enabled
        require(currentRace == 3, "This race queue is not available at the moment");

        //check if there are spaces left
        require(currentRaptors.length <=8, "You can not join at this time");

        //check the raptor is owned by _msgSender()
        require(gameLib.owns(raptor), "You do not own this raptor");

        //check that msg.value is the entrance fee
        require(msg.value == DRFee, "You have not sent enough funds");

        //add msg.value to pot
        pot += msg.value;

        //add raptor to the queue
        curentRaptors[currentPosition];

        //increment current Position
        currentPosition = currentRaptors.length()

        //if 8 entrants then start race
        if(currentRaptors == 8){
            gameLib._deathRaceStart(currentRaptors, pot);
            emit DeathRaceStarted(currentRaptors, pot);
            currentPosition = 0;
        }  
    }
}