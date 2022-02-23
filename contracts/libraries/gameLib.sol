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

    event QuickPlayRaceStarted(uint16[] raptors);
    event QuickPlayRaceWinner(uint16 raptor);

    event CompetitiveRaceStarted(uint16[] raptors);
    event CompetitiveRaceWinner(uint16 raptor);

    event DeathRaceStarted(uint16[] raptors);
    event DeathRaceWinner(uint16 raptor);
    event RipRaptor(uint16 raptor);
    //-------------------------Events-------------------------------//

    //-------------------------Modifiers-------------------------------//
    modifier isTwo(uint16[] memory raptors){
        require(raptors.length == 2, "Incorrect Amount of Raptors");
        _;
    }
    //-------------------------Modifiers-------------------------------//

    //-------------------------Helpers-------------------------------//

    function getStats(uint16 raptor, address minter) internal view returns(Stats memory stats){
        stats = IMinter(minter).getStats(raptor);
    }

    
    function updateStats(Stats memory stats, uint16 raptor, address minter) internal returns(bool success){
        success = IMinter(minter).updateStats(stats, raptor);
        require(success, "There was a problem");
    }

    //Check if msg.sender owns token
    function owns(uint16 raptor, address minter) internal view returns(bool){
        return (IERC721(minter).ownerOf(raptor) == msg.sender) ? true : false;
    }

    function getOwner(uint16 raptor, address minter) internal view returns(address){
        return IERC721(minter).ownerOf(raptor);
    }

    function calcFee(uint pool) internal pure returns(uint fee){
        fee = (pool / 100) * 5;
    }

    function calcPrize(uint pool) internal pure returns (uint prize){
        prize = (pool / 100) * 95;
    }

    function checkBounds(uint8 input, uint8 n) internal pure returns(bool response){
        (input < n && input >= 0) ? response = true : response = false;
    }

    function getFighters(GameVars memory gameVars) internal returns(GameVars memory){
        require(gameVars.expandedNums.length == 2);
        
        gameVars.fighters[0] = uint8(gameVars.expandedNums[0] % 8);
        gameVars.fighters[1] = uint8(gameVars.expandedNums[1] % 8);

        while(gameVars.fighters[0] == gameVars.fighters[1]){
            bool check = checkBounds(gameVars.fighters[0],gameVars.n);
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
            gameVars.stats[gameVars.fighters[1]] = upgradeAggressiveness(gameVars.stats[gameVars.fighters[1]], gameVars.expandedNums[2]); 
            gameVars.stats[gameVars.fighters[0]] = upgradeStrength(gameVars.stats[gameVars.fighters[0]], gameVars.expandedNums[3]);
            emit FightWinner(gameVars.raptors[gameVars.fighters[0]]);
            if(!gameVars.dr){
                emit InjuredRaptor(gameVars.raptors[gameVars.fighters[1]]);
                gameVars.stats[gameVars.fighters[1]] = addCooldownPeriod(gameVars.stats[gameVars.fighters[1]]);
            } else{
                _kill(gameVars.raptors[gameVars.fighters[1]], gameVars.minterContract);
                emit RipRaptor(gameVars.raptors[gameVars.fighters[1]]);
            }
        }else{
            gameVars.stats[gameVars.fighters[0]] = upgradeAggressiveness(gameVars.stats[gameVars.fighters[0]], gameVars.expandedNums[2]);
            
            gameVars.stats[gameVars.fighters[1]] = upgradeStrength(gameVars.stats[gameVars.fighters[1]], gameVars.expandedNums[5]);
            
            emit FightWinner(gameVars.raptors[gameVars.fighters[1]]);
            if(!gameVars.dr){
                gameVars.stats[gameVars.fighters[0]] = addCooldownPeriod(gameVars.stats[gameVars.fighters[0]]);
                emit InjuredRaptor(gameVars.raptors[gameVars.fighters[0]]);
            } else{
                _kill(gameVars.raptors[gameVars.fighters[0]], gameVars.minterContract);
                emit RipRaptor(gameVars.raptors[gameVars.fighters[0]]);
            }
        }
        return gameVars;
    }

    function getFastest(GameVars memory gameVars) internal pure returns (GameVars memory){
        uint16 lowest=20000;
        uint8 winner;
        uint8 second;
        uint8 third;
        for(uint8 i =0; i< gameVars.n; i++){
            if(i != gameVars.fighters[0] || i != gameVars.fighters[1]){
                if(gameVars.time[i]<lowest){
                    third = second;
                    second = winner;
                    winner = i;
                    lowest = uint16(gameVars.time[i]);            
                }
            }
        }
        
        return gameVars;
    }

    function getWinner(GameVars memory gameVars) internal returns(GameVars memory){
        require(gameVars.expandedNums.length == gameVars.n);

        //get randomness for each raptor
        //calc times to finish the race first with added randomness
        uint8 i =0;
        uint8[] memory randomness = new uint8[](gameVars.n);
        for(; i< gameVars.n; i++){
            randomness[i] = uint8(gameVars.expandedNums[i] % 5);
            gameVars.time[i] = gameVars.distance / (gameVars.stats[i].speed + randomness[i]);
        }      
        
        //gets fastest indexes & ignores fighter indexes
        gameVars = getFastest(gameVars);
        return gameVars;
    }

    //-------------------------Helpers--------------------------------//

    //------------------------Stat-Changes------------------------------//
                       // -------  +vary ----------//
    function upgradeAggressiveness(Stats memory stats, uint64 rng) internal returns(Stats memory){
        uint8 rand = uint8(rng %3) +1;
        stats.agressiveness += rand;
        return stats;
    }

    function upgradeStrength(Stats memory stats, uint64 rng) internal returns(Stats memory){
        uint8 rand = uint8(rng %3) +1;
        stats.strength += rand;
        return stats;
    }

    function upgradeSpeed(Stats memory stats, uint64 rng) internal returns(Stats memory){
        uint8 rand = uint8(rng %3) +1;
        stats.speed += rand;
        return stats;
    }
                       // -------  +Vary ----------//

                       // -------  +1 ----------//
    function increaseQPWins(Stats memory stats) internal pure returns(Stats memory){
        stats.quickPlayRacesWon += 1;
        stats.totalRacesTop3Finish +=1;
        return stats;
    }

    function increaseQPLosses(Stats memory stats) internal pure returns(Stats memory){
        stats.quickPlayRacesLost += 1;
        return stats;
    }

    function increaseCompWins(Stats memory stats) internal pure returns(Stats memory){
        stats.compRacesWon += 1;
        stats.totalRacesTop3Finish += 1;
        return stats;
    }

    function increaseCompLosses(Stats memory stats) internal pure returns(Stats memory){
        stats.compRacesLost += 1;
        return stats;
    }

    function increaseDeathRaceWins(Stats memory stats) internal pure returns(Stats memory){
        stats.deathRacesWon += 1;
        stats.deathRacesSurvived += 1;
        stats.totalRacesTop3Finish += 1;
        return stats;
    }

    function increaseDeathRaceLosses(Stats memory stats) internal pure returns(Stats memory){
        stats.deathRacesLost += 1;
        return stats;
    }

    function increaseDeathRacesSurvived(Stats memory stats) internal pure returns(Stats memory){
        stats.deathRacesSurvived += 1;
        return stats;
    }

    function increaseTop3RaceFinishes(Stats memory stats) internal pure returns(Stats memory){
        stats.totalRacesTop3Finish += 1;
        return stats;
    }
                       // -------  +1 ----------//

         // -----  +12 Hours/ Unless Founding Raptor 6 Hours -----//
    
    function addCooldownPeriod(Stats memory stats) internal view returns(Stats memory){
        if(stats.foundingRaptor == true){
            stats.cooldownTime = block.timestamp + 6 hours;
        } else {
            stats.cooldownTime += block.timestamp + 12 hours;
        }
        return stats;
    }
         // -----  +12 Hours/ Unless Founding Raptor 6 Hours -----//
    //------------------------Stat-Changes---------------------------------//

    //-----------------------------QP--------------------------------------//

    //QP Start
    function _quickPlayStart(GameVars memory gameVars) internal returns (uint16){
        require(gameVars.expandedNums.length == gameVars.n);
        emit QuickPlayRaceStarted(gameVars.raptors);

        uint8 i =0;

        //get stats for each raptor
        for (; i<gameVars.n;i++){
            gameVars.stats[i] = getStats(gameVars.raptors[i], gameVars.minterContract);
        }
        
        //gets fighters, finds the winner & adds them to indexes to ignore for choosing winner
        gameVars = getFighters(gameVars);
        gameVars = getFightWinner(gameVars);
        //gets the winner & next two places
        gameVars = getWinner(gameVars);
        
        //modify states //index 0 = winner; index 1 = second; index 2 = third
        
        gameVars.stats[gameVars.places[0]] = increaseQPWins(gameVars.stats[gameVars.places[0]]);
        gameVars.stats[gameVars.places[0]] = upgradeSpeed(gameVars.stats[gameVars.places[0]], gameVars.expandedNums[2]);
        gameVars.stats[gameVars.places[1]] = increaseTop3RaceFinishes(gameVars.stats[gameVars.places[1]]);
        gameVars.stats[gameVars.places[2]] = increaseTop3RaceFinishes(gameVars.stats[gameVars.places[2]]);
        
        i =0;

        //modify losses/survivals & update 
        for(; i<gameVars.n; i++){
            
            if(i != gameVars.fighters[0] || i != gameVars.fighters[1] || i != gameVars.places[0]){
                gameVars.stats[i] = increaseDeathRacesSurvived(gameVars.stats[i]);
            }

            if(i != gameVars.places[0]){
                gameVars.stats[i] = increaseQPLosses(gameVars.stats[i]);
            }
            updateStats(gameVars.stats[i], gameVars.raptors[i], gameVars.minterContract);
        }


        emit QuickPlayRaceWinner(gameVars.raptors[gameVars.places[0]]);

        return gameVars.raptors[gameVars.places[0]];

    }

    //---------------------------QP--------------------------------------//
    //----------------------------Comp-----------------------------------//

    // //Comp Start
    function _compStart(GameVars memory gameVars) internal returns(uint16){
        require(gameVars.expandedNums.length == gameVars.n);
        emit CompetitiveRaceStarted(gameVars.raptors);

        uint8 i =0;
        for (; i<gameVars.n;i++){
            gameVars.stats[i] = getStats(gameVars.raptors[i], gameVars.minterContract);
        }
        
        //gets fighters, finds the winner & adds them to indexes to ignore for choosing winner
        gameVars = getFighters(gameVars);
        gameVars = getFightWinner(gameVars);
        //gets the winner & next two places
        gameVars = getWinner(gameVars);
        
        //modify states //index 0 = winner; index 1 = second; index 2 = third
        
        gameVars.stats[gameVars.places[0]] = increaseCompWins(gameVars.stats[gameVars.places[0]]);
        gameVars.stats[gameVars.places[0]] = upgradeSpeed(gameVars.stats[gameVars.places[0]], gameVars.expandedNums[2]);
        gameVars.stats[gameVars.places[1]] = increaseTop3RaceFinishes(gameVars.stats[gameVars.places[1]]);
        gameVars.stats[gameVars.places[2]] = increaseTop3RaceFinishes(gameVars.stats[gameVars.places[2]]);

        i = 0;  

        //modify losses & update 
        for(; i<gameVars.n; i++){
            if(i != gameVars.places[0]){
                gameVars.stats[i] = increaseCompLosses(gameVars.stats[i]);
            }
            updateStats(gameVars.stats[i], gameVars.raptors[i], gameVars.minterContract);
        }


        emit CompetitiveRaceWinner(gameVars.raptors[gameVars.places[0]]);

        return gameVars.raptors[gameVars.places[0]];

    }

    // //---------------------------------Comp--------------------------------//
    // //-------------------------------DR------------------------------------//

    // //DR Start
    function _deathRaceStart(GameVars memory gameVars) internal returns(uint16){
        require(gameVars.expandedNums.length == gameVars.n);
        emit DeathRaceStarted(gameVars.raptors);

        uint8 i =0;

        //get stats for each raptor
        for (; i<gameVars.n;i++){
            gameVars.stats[i] = getStats(gameVars.raptors[i], gameVars.minterContract);
        }
        
        //gets fighters, finds the winner & adds them to indexes to ignore for choosing winner
        gameVars = getFighters(gameVars);
        gameVars = getFightWinner(gameVars);
        //gets the winner & next two places
        gameVars = getWinner(gameVars);
        
        //modify states //index 0 = winner; index 1 = second; index 2 = third
        
        gameVars.stats[gameVars.places[0]] = increaseDeathRaceWins(gameVars.stats[gameVars.places[0]]);
        gameVars.stats[gameVars.places[0]] = upgradeSpeed(gameVars.stats[gameVars.places[0]], gameVars.expandedNums[2]);
        gameVars.stats[gameVars.places[1]] = increaseTop3RaceFinishes(gameVars.stats[gameVars.places[1]]);
        gameVars.stats[gameVars.places[2]] = increaseTop3RaceFinishes(gameVars.stats[gameVars.places[2]]);

        i=0;

        //modify losses & update 
        for(; i<gameVars.n; i++){
            if(i != gameVars.places[0]){
                gameVars.stats[i] = increaseDeathRaceLosses(gameVars.stats[i]);
            }
            updateStats(gameVars.stats[i], gameVars.raptors[i], gameVars.minterContract);
        }

        emit DeathRaceWinner(gameVars.raptors[gameVars.places[0]]);

        return gameVars.raptors[gameVars.places[0]];
    }

    // //DR Kill/BURN RAPTOR
    function _kill(uint16 raptor, address minter) internal {
        IERC721(minter).safeTransferFrom(getOwner(raptor, minter),address(0),raptor);
    }

    // //---------------------------------------DR----------------------------//


}