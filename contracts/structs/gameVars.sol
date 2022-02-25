pragma solidity ^0.8.7;

import "./stats.sol";

struct GameVars {
    Stats[8] stats;
    uint16[8] raptors;
    uint16[8] expandedNums;
    uint8[2] fighters;
    uint8 fightWinner;
    uint8[3] places;
    bool dr;
}