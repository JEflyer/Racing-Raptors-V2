//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


struct Stats{
    uint16 speed,
    uint16 strength,
    uint16 agressiveness,
    uint16 fightsWon,
    uint16 fightsLost,
    uint16 quickPlayRacesWon,
    uint16 quickPlayRacesLost,
    uint16 compRacesWon,
    uint16 compRacesLost,
    uint16 deathRacesWon,
    uint16 deathRacesSurvived,
    uint16 deathRaceFightsWon,
    uint16 totalRacesTop3Finish,
    uint256 cooldownTime,
    bool foundingRaptor
}