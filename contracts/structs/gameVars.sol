pragma solidity ^0.8.7;

import "./stats.sol";

struct GameVars {
    Stats[] stats;
    uint16[] raptors;
    uint64[] expandedNums;
    uint8 n;
    address minterContract;
    uint distance;
    uint8[2] fighters;
    uint8[3] places;
    bool dr;
    uint[] time;
}