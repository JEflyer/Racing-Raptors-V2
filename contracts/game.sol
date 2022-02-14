//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./interfaces/IGame.sol";
import "./interfaces/IMinter.sol";

import "./libraries/gameLib.sol";

import "./structs/stats.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/blob/master/contracts/utils/Context.sol";

contract Game is IGame, IERC721Receiver, Context {

    event QuickPlayRaceStarted(uint16[] raptors, uint prizePool);
    event QuickPlayRaceWinner(uint16 raptor, uint prize);

    event CompetitiveRaceStarted(uint16[] raptors, uint prizePool);
    event CompetitiveRaceWinner(uint16 raptor, uint prize);
    event InjuredRaptor(uint16 raptor, uint time);

    event DeathRaceStarted(uint16[] raptors, uint prizePool);
    event DeathRaceWinner(uint16 raptor, uint prize);
    event RipRaptor(uint16 raptor);

    event NewAdmin(address admin);
    event UpdatedStats(uint16 raptor, Stats stats);

    event RaceChosen(string raceType);

    address private admin;
    address private immutable minterContract;

    uint8 private immutable feePercent;

    address private immutable communityWallet;

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
        uint8 _feePercent,
        address _communityWallet
    ){
        require(_feePercent == 5);
        minterContract = _minterContract;
        admin = _msgSender();
        feePercent = _feePercent;
        communityWallet = _communityWallet;
        currentRace = CurrentRace(0);
    }

    function _payOut(uint payout,uint communityPayout) internal payable returns(bool){

    }

    modifier onlyAdmin (
        require(msg.sender == admin, "You can not call this function");
        _;
    )

    modifier isTwo(uint16[] raptors){
        require(raptors.length == 2, "Too many raptors");
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

    }

    //Competitive Entry
    function enterRaptorIntoComp(uint16 raptor) public payable returns (bool){

    }

    //DeathRace Entry
    function enterRaptorIntoDR(uint16 raptor) public payable returns(bool){

    }


    //Race Start
    function RaceStart() public onlyAdmin{
        //selects different paths based on the state position of the enumerator chosen by the raceSelect 

        //Standby
        if(currentRace == 0){
            revert("You must choose a race");
        }
        
        //Quickplay
        if(currentRace == 1){

        }

        //Competitive
        if(currentRace == 2){

        }

        //DeathRace
        if(currentRace ==3){
            
        }
    }
    

    

}