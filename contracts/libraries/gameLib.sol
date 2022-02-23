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

    function getFighters(uint64[2] memory rng, uint8 n) internal returns(uint8[2] memory fighters){
        require(rng.length == 2);
        
        uint8 raptor1 = uint8(rng[0] % n);
        uint8 raptor2 = uint8(rng[1] % 8);

        while(raptor1 == raptor2){
            bool check = checkBounds(raptor1,n);
            if(!check) {
                raptor1 =0 + uint8(rng[1] % 7);
            } 
        }

        fighters[0] = raptor1;
        fighters[1] = raptor2;
    }

    //agressiveness & strength not currently factors on who wins the fight
    function getFightWinner(uint8[2] memory fighters, uint64 rng, Stats[] memory stats, uint16[] memory raptors, bool dr, address minterContract) internal returns(Stats[] memory _stats){
        uint8 index;
        (rng%2 == 0) ? index = fighters[0] : index = fighters[1]; 

        if(index == fighters[0]){ 
            stats[fighters[1]] = upgradeAggressiveness(stats[fighters[1]], rng); 
            stats[fighters[0]] = upgradeStrength(stats[fighters[0]], rng);
            emit FightWinner(raptors[fighters[0]]);
            if(!dr){
                emit InjuredRaptor(raptors[fighters[1]]);
                stats[fighters[1]] = addCooldownPeriod(stats[fighters[1]]);
            } else{
                _kill(raptors[fighters[1]], minterContract);
                emit RipRaptor(raptors[fighters[1]]);
            }
        }else{
            stats[fighters[0]] = upgradeAggressiveness(stats[fighters[0]], rng);
            
            stats[fighters[1]] = upgradeStrength(stats[fighters[1]], rng);
            
            emit FightWinner(raptors[fighters[1]]);
            if(!dr){
                stats[fighters[0]] = addCooldownPeriod(stats[fighters[0]]);
                emit InjuredRaptor(raptors[fighters[0]]);
            } else{
                _kill(raptors[fighters[0]], minterContract);
                emit RipRaptor(raptors[fighters[0]]);
            }
        }
    }

    function getFastest(uint[] memory time, uint8[2] memory indexesToIgnore, uint8 n) internal pure returns (uint8[3] memory places){
        uint16 lowest=20000;
        uint8 winner;
        uint8 second;
        uint8 third;
        for(uint8 i =0; i< n; i++){
            if(i != indexesToIgnore[0] || i != indexesToIgnore[1]){
                if(time[i]<lowest){
                    third = second;
                    second = winner;
                    winner = i;
                    lowest = uint16(time[i]);            
                }
            }
        }
        
        places =  [winner, second, third];
    }

    function getWinner(Stats[] memory stats, uint8[2] memory indexesToIgnore, uint8 n, uint64[] memory rng, uint256 distance) internal returns(uint8[3] memory places){
        require(rng.length == n);
        //get randomness for each raptor
        uint8[] memory randomness = new uint8[](n);
        for(uint8 i =0; i< n; i++){
            randomness[i] = uint8(rng[i] % 5);
        }

        //calc times to finish the race first with added randomness
        uint256[] memory time = new uint256[](n);
        for(uint8 i =0; i< n; i++){
            time[i] = distance / (stats[i].speed + randomness[i]);
        }
        
        //gets fastest indexes & ignores fighter indexes
        places = getFastest(time, indexesToIgnore,n);
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
        gameVars.fighters = getFighters([gameVars.expandedNums[0],gameVars.expandedNums[1]], gameVars.n);
        gameVars.stats = getFightWinner(gameVars.fighters, gameVars.expandedNums[6], gameVars.stats,gameVars.raptors, gameVars.dr, gameVars.minterContract);
        //gets the winner & next two places
        gameVars.places = getWinner(gameVars.stats,gameVars.fighters, gameVars.n, gameVars.expandedNums, gameVars.distance);
        
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
        gameVars.fighters = getFighters([gameVars.expandedNums[0],gameVars.expandedNums[1]], gameVars.n);
        gameVars.stats = getFightWinner(gameVars.fighters, gameVars.expandedNums[6], gameVars.stats, gameVars.raptors, gameVars.dr, gameVars.minterContract);
        //gets the winner & next two places
        gameVars.places = getWinner(gameVars.stats,gameVars.fighters, gameVars.n, gameVars.expandedNums, gameVars.distance);
        
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
        gameVars.fighters = getFighters([gameVars.expandedNums[0],gameVars.expandedNums[1]], gameVars.n);
        gameVars.stats = getFightWinner(gameVars.fighters, gameVars.expandedNums[6], gameVars.stats, gameVars.raptors, gameVars.dr, gameVars.minterContract);
        //gets the winner & next two places
        gameVars.places = getWinner(gameVars.stats,gameVars.fighters, gameVars.n, gameVars.expandedNums, gameVars.distance);
        
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