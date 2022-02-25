//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


import "../structs/stats.sol";
import "../structs/gameVars.sol";

import "../interfaces/IMinter.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

library gameLib {
    //-------------------------Events-------------------------------//
    event InjuredRaptor(uint16 raptor);
    event FightWinner(uint16 raptor);

    event QuickPlayRaceStarted(uint16[8] raptors);
    event QuickPlayRaceWinner(uint16 raptor);

    event CompetitiveRaceStarted(uint16[8] raptors);
    event CompetitiveRaceWinner(uint16 raptor);

    event DeathRaceStarted(uint16[8] raptors);
    event DeathRaceWinner(uint16 raptor);
    event RipRaptor(uint16 raptor);
    //-------------------------Events-------------------------------//

    //-------------------------Modifiers-------------------------------//
    modifier isTwo(uint16[] memory raptors){
        require(raptors.length == 2, "Incorrect Amount of Raptors");
        _;
    }
    //-------------------------Modifiers-------------------------------//

    //-------------------------storage----------------------------------//
    //-------------------------minter----------------------------------//
    bytes32 constant minterSlot = keccak256("minterAddress");

    struct MinterStore{
        address minterContract;
    }

    function minterStore() internal pure returns(MinterStore storage minter){
        bytes32 slot = minterSlot;
        assembly{
            minter.slot := slot
        }
    }

    function setMinter(address _minter) internal {
        MinterStore storage store = minterStore();
        store.minterContract = _minter;
    }
    //-------------------------minter----------------------------------//
    //-------------------------distance----------------------------------//
    bytes32 constant distanceSlot = keccak256("distance");

    struct DistanceStore{
        uint32 distance;
    }

    function distanceStore() internal pure returns(DistanceStore storage distance){
        bytes32 slot = distanceSlot;
        assembly{
            distance.slot := slot
        }
    }

    function setDistance(uint32 _distance) internal {
        DistanceStore storage store = distanceStore();
        store.distance = _distance;
    }
    //-------------------------distance----------------------------------//
    //-------------------------storage----------------------------------//

    //-------------------------Helpers-------------------------------//

    function getStats(uint16 raptor) internal view returns(Stats memory stats){
        MinterStore storage store = minterStore();
        stats = IMinter(store.minterContract).getStats(raptor);
    }

    
    function updateStats(Stats memory stats, uint16 raptor) internal returns(bool success){
        MinterStore storage store = minterStore();
        success = IMinter(store.minterContract).updateStats(stats, raptor);
        require(success, "There was a problem");
    }

    //Check if msg.sender owns token
    function owns(uint16 raptor) internal view returns(bool){
        MinterStore storage store = minterStore();
        return (IERC721(store.minterContract).ownerOf(raptor) == msg.sender) ? true : false;
    }

    function getOwner(uint16 raptor) internal view returns(address){
        MinterStore storage store = minterStore();
        return IERC721(store.minterContract).ownerOf(raptor);
    }

    function calcFee(uint pool) internal pure returns(uint fee){
        fee = (pool / 100) * 5;
    }

    function calcPrize(uint pool) internal pure returns (uint prize){
        prize = (pool / 100) * 95;
    }

    function checkBounds(uint8 input) internal pure returns(bool response){
        (input < 8 && input >= 0) ? response = true : response = false;
    }

    function getFighters(GameVars memory gameVars) internal returns(GameVars memory){
        require(gameVars.expandedNums.length == 2);
        
        gameVars.fighters[0] = uint8(gameVars.expandedNums[0] % 8);
        gameVars.fighters[1] = uint8(gameVars.expandedNums[1] % 8);

        while(gameVars.fighters[0] == gameVars.fighters[1]){
            bool check = checkBounds(gameVars.fighters[0]);
            if(!check) {
                gameVars.fighters[0] =0 + uint8(gameVars.expandedNums[3] % 7);
            } 
        }

        return gameVars;

    }

    //agressiveness & strength not currently factors on who wins the fight
    function getFightWinner(GameVars memory gameVars) internal returns(GameVars memory){
        uint8 index;
        (gameVars.expandedNums[4]%2 == 0) ? index = gameVars.fighters[0] : index = gameVars.fighters[1]; 

        if(index == gameVars.fighters[0]){ 
            gameVars = upgradeAggressiveness(gameVars); 
            gameVars = upgradeStrength(gameVars);
            emit FightWinner(gameVars.raptors[gameVars.fighters[0]]);
            gameVars.fightWinner = gameVars.fighters[0];
            if(!gameVars.dr){
                emit InjuredRaptor(gameVars.raptors[gameVars.fighters[1]]);
                gameVars = addCooldownPeriod(gameVars);
            } else{
                _kill(gameVars.raptors[gameVars.fighters[1]]);
                emit RipRaptor(gameVars.raptors[gameVars.fighters[1]]);
            }
        }else{
            gameVars = upgradeAggressiveness(gameVars);
            
            gameVars = upgradeStrength(gameVars);
            gameVars.fightWinner = gameVars.fighters[1];
            emit FightWinner(gameVars.raptors[gameVars.fighters[1]]);
            if(!gameVars.dr){
                gameVars = addCooldownPeriod(gameVars);
                emit InjuredRaptor(gameVars.raptors[gameVars.fighters[0]]);
            } else{
                _kill(gameVars.raptors[gameVars.fighters[0]]);
                emit RipRaptor(gameVars.raptors[gameVars.fighters[0]]);
            }
        }
        return gameVars;
    }

    function getFastest(uint8[2] memory fighters,uint32[8] memory time) internal returns (uint8[3] memory){
        uint16 lowest=20000;
        uint8 winner;
        uint8 second;
        uint8 third;
        uint8[3] memory places;
        uint8 i = 0;
        for(; i< 8; i++){
            if(i != fighters[0] || i != fighters[1]){
                if(time[i]<lowest){
                    lowest = uint16(time[i]); 
                    places[0] = i;           
                }
            }
        }
        lowest = 20000;
        i = 0;
        for(; i< 8; i++){
            if(i != fighters[0] || i != fighters[1] || i != places[0]){
                if(time[i]<lowest){
                    lowest = uint16(time[i]); 
                    places[1] = i;           
                }
            }
        }
        lowest = 20000;
        i = 0;
        for(; i< 8; i++){
            if(i != fighters[0] || i != fighters[1] || i != places[0] || i != places[2]){
                if(time[i]<lowest){
                    lowest = uint16(time[i]); 
                    places[2] = i;            
                }
            }
        }
        
        return places;
    }

    function getWinner(GameVars memory gameVars) internal returns(GameVars memory){
        require(gameVars.expandedNums.length == 8);

        //get randomness for each raptor
        //calc times to finish the race first with added randomness
        uint8 i =0;
        uint8[8] memory randomness;
        uint32[8] memory time;
        uint32 distance = distanceStore().distance;
        for(; i< 8; i++){
            randomness[i] = uint8(gameVars.expandedNums[i] % 5);
            time[i] = distance / (gameVars.stats[i].speed + randomness[i]);
        }      
        
        //gets fastest indexes & ignores fighter indexes
        gameVars.places = getFastest(gameVars.fighters, time);
        return gameVars;
    }

    //-------------------------Helpers--------------------------------//

    //------------------------Stat-Changes------------------------------//
                       // -------  +vary ----------//
    function upgradeAggressiveness(GameVars memory gameVars) internal returns(GameVars memory){
        uint8 rand = uint8(gameVars.expandedNums[5] %3) +1;
        uint8 index;
        (gameVars.fightWinner == gameVars.fighters[0]) ? (index = 1) : (index = 0);
        gameVars.stats[index].agressiveness += rand;
        return gameVars;
    }

    function upgradeStrength(GameVars memory gameVars) internal returns(GameVars memory){
        uint8 rand = uint8(gameVars.expandedNums[4] %3) +1;
        uint8 index;
        (gameVars.fightWinner == gameVars.fighters[0]) ? (index = 0) : (index = 1);
        gameVars.stats[index].strength += rand;
        return gameVars;
    }

    function upgradeSpeed(GameVars memory gameVars) internal returns(GameVars memory){
        uint8 rand = uint8(gameVars.expandedNums[7] %3) +1;
        gameVars.stats[gameVars.places[0]].speed += rand;
        return gameVars;
    }
                       // -------  +Vary ----------//

                       // -------  +1 ----------//
    function increaseQPWins(GameVars memory gameVars) internal returns(GameVars memory){
        gameVars.stats[gameVars.places[0]].quickPlayRacesWon += 1;
        gameVars.stats[gameVars.places[0]].totalRacesTop3Finish +=1;
        return gameVars;
    }

    function increaseCompWins(GameVars memory gameVars) internal returns(GameVars memory){
        gameVars.stats[gameVars.places[0]].compRacesWon += 1;
        gameVars.stats[gameVars.places[0]].totalRacesTop3Finish += 1;
        return gameVars;
    }

    function increaseDeathRaceWins(GameVars memory gameVars) internal returns(GameVars memory){
        gameVars.stats[gameVars.places[0]].deathRacesWon += 1;
        gameVars.stats[gameVars.places[0]].totalRacesTop3Finish += 1;
        return gameVars;
    }

    function increaseTop3RaceFinishes(GameVars memory gameVars) internal returns(GameVars memory){
        for(uint i = 0; i < 3; i++){
            gameVars.stats[gameVars.places[i]].totalRacesTop3Finish += 1;
        }
        return gameVars;
    }
                       // -------  +1 ----------//

         // -----  +12 Hours/ Unless Founding Raptor 6 Hours -----//
    
    function addCooldownPeriod(GameVars memory gameVars) internal returns(GameVars memory){
        uint8 index;
        (gameVars.fightWinner == gameVars.fighters[0]) ? (index = 1) : (index = 0);
        address minter = minterStore().minterContract;
        if(IMinter(minter).isFoundingRaptor(gameVars.raptors[index]) == true){
            gameVars.stats[index].cooldownTime = uint32(block.timestamp + 6 hours);
        } else {
            gameVars.stats[index].cooldownTime += uint32(block.timestamp + 12 hours);
        }
        return gameVars;
    }
         // -----  +12 Hours/ Unless Founding Raptor 6 Hours -----//
    //------------------------Stat-Changes---------------------------------//

    //-----------------------------QP--------------------------------------//

    //QP Start
    function _quickPlayStart(GameVars memory gameVars) internal returns (uint16){
        require(gameVars.expandedNums.length == 8);
        emit QuickPlayRaceStarted(gameVars.raptors);

        uint8 i =0;

        //get stats for each raptor
        for (; i<8;i++){
            gameVars.stats[i] = getStats(gameVars.raptors[i]);
        }
        
        //gets fighters, finds the winner & adds them to indexes to ignore for choosing winner
        gameVars = getFighters(gameVars);
        gameVars = getFightWinner(gameVars);
        //gets the winner & next two places
        gameVars = getWinner(gameVars);
        
        gameVars = handleQPStats(gameVars);


        emit QuickPlayRaceWinner(gameVars.raptors[gameVars.places[0]]);

        return gameVars.raptors[gameVars.places[0]];

    }

    function handleQPStats(GameVars memory gameVars) internal returns(GameVars memory){
        gameVars = increaseQPWins(gameVars);
        gameVars = upgradeSpeed(gameVars);
        gameVars = increaseTop3RaceFinishes(gameVars);
        gameVars = upgradeAggressiveness(gameVars);
        gameVars = upgradeStrength(gameVars);
        
        for(uint8 i = 0; i<8; i++){
            updateStats(gameVars.stats[i], gameVars.raptors[i]);
        }
        return gameVars;
    }

    //---------------------------QP--------------------------------------//
    //----------------------------Comp-----------------------------------//

    // //Comp Start
    function _compStart(GameVars memory gameVars) internal returns(uint16){
        require(gameVars.expandedNums.length == 8);
        emit CompetitiveRaceStarted(gameVars.raptors);

        uint8 i =0;
        for (; i<8;i++){
            gameVars.stats[i] = getStats(gameVars.raptors[i]);
        }
        
        //gets fighters, finds the winner & adds them to indexes to ignore for choosing winner
        gameVars = getFighters(gameVars);
        gameVars = getFightWinner(gameVars);
        //gets the winner & next two places
        gameVars = getWinner(gameVars);
        
        //modify states //index 0 = winner; index 1 = second; index 2 = third
        
        gameVars = handleCompStats(gameVars);       


        emit CompetitiveRaceWinner(gameVars.raptors[gameVars.places[0]]);

        return gameVars.raptors[gameVars.places[0]];

    }

    function handleCompStats(GameVars memory gameVars) internal returns(GameVars memory){
        gameVars = increaseCompWins(gameVars);
        gameVars = upgradeSpeed(gameVars);
        gameVars = increaseTop3RaceFinishes(gameVars);
        gameVars = upgradeAggressiveness(gameVars);
        gameVars = upgradeStrength(gameVars);

        //modify losses & update 
        for(uint8 i = 0; i<8; i++){
            updateStats(gameVars.stats[i], gameVars.raptors[i]);
        }

        return gameVars;
    }

    // //---------------------------------Comp--------------------------------//
    // //-------------------------------DR------------------------------------//

    // //DR Start
    function _deathRaceStart(GameVars memory gameVars) internal returns(uint16){
        require(gameVars.expandedNums.length == 8);
        emit DeathRaceStarted(gameVars.raptors);

        uint8 i =0;

        //get stats for each raptor
        for (; i<8;i++){
            gameVars.stats[i] = getStats(gameVars.raptors[i]);
        }
        
        //gets fighters, finds the winner & adds them to indexes to ignore for choosing winner
        gameVars = getFighters(gameVars);
        gameVars = getFightWinner(gameVars);
        //gets the winner & next two places
        gameVars = getWinner(gameVars);
        
        gameVars = handleDRStats(gameVars);

        emit DeathRaceWinner(gameVars.raptors[gameVars.places[0]]);

        return gameVars.raptors[gameVars.places[0]];
    }

    // //DR Kill/BURN RAPTOR
    function _kill(uint16 raptor) internal {
        MinterStore storage store = minterStore();
        IERC721(store.minterContract).safeTransferFrom(getOwner(raptor),address(0),raptor);
    }

    function handleDRStats(GameVars memory gameVars) internal returns(GameVars memory){
        gameVars = increaseCompWins(gameVars);
        gameVars = upgradeSpeed(gameVars);
        gameVars = increaseTop3RaceFinishes(gameVars);
        gameVars = upgradeAggressiveness(gameVars);
        gameVars = upgradeStrength(gameVars);
        //modify losses & update 
        for(uint8 i = 0; i<8; i++){
            updateStats(gameVars.stats[i], gameVars.raptors[i]);
        }

        return gameVars;
    }

    // //---------------------------------------DR----------------------------//


}