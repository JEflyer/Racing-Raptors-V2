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

    address private admin;
    address private immutable minterContract;

    uint8 private immutable feePercent;

    address private immutable communityWallet;

    enum CurrentRace = {
        StandBy,
        QuickPlay,
        Competitive,
        DeathRace
    }

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
    }

    function _quickPlayStart(uint16[] raptors, uint prizePool) internal returns (bool){

    }

}