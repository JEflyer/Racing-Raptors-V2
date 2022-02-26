//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


struct Stats{
    uint16 speed;
    uint16 strength;
    uint16 fightsWon;
    uint16 quickPlayRacesWon;
    uint16 compRacesWon;
    uint16 deathRacesWon;
    uint16 totalRacesTop3Finish;
    uint32 cooldownTime;
}