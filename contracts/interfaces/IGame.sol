//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IGame {
    function raceSelect(uint8 choice) external;

    //Quickplay Entry
    function enterRaptorIntoQuickPlay(uint16 raptor) external payable returns (bool);

    //Competitive Entry
    function enterRaptorIntoComp(uint16 raptor) external payable returns (bool);

    //DeathRace Entry
    function enterRaptorIntoDR(uint16 raptor) external payable returns(bool);
}