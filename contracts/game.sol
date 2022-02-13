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

    function raceSelect(uint8 choice)public onlyAdmin{
        require(choice >= 0 && choice <=3);
        currentRace = CurrentRace(choice);
        emit RaceChosen(raceNames[choice]);
    }

    //quickplay functions
    function _quickPlayStart(uint16[] raptors, uint prizePool) internal returns (bool){

    }

    function enterRaptorIntoQuickPlay(uint16 raptor) public payable returns (bool){

    }

    function _quickPlayEnd(uint16 winner, uint payout, uint communityPayout) internal payable returns(bool){

    }

    function _quickPlayFight(uint16[] raptorsFighting) internal returns (uint16 winner){

    }

    //competitive functions
    function enterRaptorIntoComp(uint16 raptor) public payable returns (bool){

    }

    function _compStart(uint16[] raptors, uint prizePool) internal returns(bool){

    }
    
    function _compEnd(uint16 winner, uint payout, uint communityPayout) internal payable returns(bool){

    }

    function _compFight(uint16[] raptorsFighting) internal returns (uint16 winner){

    }

    //DeathRace functions
    function enterRaptorIntoDR(uint16 raptor) public payable returns(bool){

    }

    function _deathRaceStart(uint16[] raptors, uint prizePool) internal returns(bool){

    }

    function _deathRaceEnd(uint16 winner, uint payout, uint communityPayout) internal payable returns(bool){

    }

    function _fightToTheDeath(uint16[] raptorsFighting) internal returns(bool){

    }

    function _kill(uint16 raptor) internal returns (bool){

    }

    

}