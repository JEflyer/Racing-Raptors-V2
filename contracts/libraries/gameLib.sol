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
            gameVars = upgradeAggressiveness(gameVars); 
            gameVars = upgradeStrength(gameVars);
            emit FightWinner(gameVars.raptors[gameVars.fighters[0]]);
            gameVars.fightWinner = gameVars.fighters[0];
            if(!gameVars.dr){
                emit InjuredRaptor(gameVars.raptors[gameVars.fighters[1]]);
                gameVars = addCooldownPeriod(gameVars);
            } else{
                _kill(gameVars.raptors[gameVars.fighters[1]], gameVars.minterContract);
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
    function increaseQPWins(GameVars memory gameVars) internal pure returns(GameVars memory){
        gameVars.stats[gameVars.places[0]].quickPlayRacesWon += 1;
        gameVars.stats[gameVars.places[0]].totalRacesTop3Finish +=1;
        return gameVars;
    }

    function increaseQPLosses(GameVars memory gameVars) internal pure returns(GameVars memory){
        for(uint i = 0; i< gameVars.stats.length; i++){
            if(i != gameVars.places[0]) gameVars.stats[i].quickPlayRacesLost += 1;
        }
        return gameVars;
    }

    function increaseCompWins(GameVars memory gameVars) internal pure returns(GameVars memory){
        gameVars.stats[gameVars.places[0]].compRacesWon += 1;
        gameVars.stats[gameVars.places[0]].totalRacesTop3Finish += 1;
        return gameVars;
    }

    function increaseCompLosses(GameVars memory gameVars) internal pure returns(GameVars memory){
        for(uint i = 0; i< gameVars.stats.length; i++){
            if(i != gameVars.places[0]) gameVars.stats[i].compRacesLost += 1;
        }
        return gameVars;
    }

    function increaseDeathRaceWins(GameVars memory gameVars) internal pure returns(GameVars memory){
        gameVars.stats[gameVars.places[0]].deathRacesWon += 1;
        gameVars.stats[gameVars.places[0]].deathRacesSurvived += 1;
        gameVars.stats[gameVars.places[0]].totalRacesTop3Finish += 1;
        return gameVars;
    }

    function increaseDeathRaceLosses(GameVars memory gameVars) internal pure returns(GameVars memory){
        for(uint i = 0; i< gameVars.stats.length; i++){
            if(i != gameVars.places[0]) gameVars.stats[i].deathRacesLost += 1;
        }
        return gameVars;
    }

    function increaseDeathRacesSurvived(GameVars memory gameVars) internal pure returns(GameVars memory){
        uint8 index;
        (gameVars.fightWinner == gameVars.fighters[0]) ? (index = 1) : (index = 0);

        for(uint i =0; i< gameVars.stats.length; i++){
            if(i != index) gameVars.stats[i].deathRacesSurvived += 1;
        }
        return gameVars;
    }

    function increaseTop3RaceFinishes(GameVars memory gameVars) internal pure returns(GameVars memory){
        for(uint i = 0; i < 3; i++){
            gameVars.stats[gameVars.places[i]].totalRacesTop3Finish += 1;
        }
        return gameVars;
    }
                       // -------  +1 ----------//

         // -----  +12 Hours/ Unless Founding Raptor 6 Hours -----//
    
    function addCooldownPeriod(GameVars memory gameVars) internal view returns(GameVars memory){
        uint8 index;
        (gameVars.fightWinner == gameVars.fighters[0]) ? (index = 1) : (index = 0);

        if(gameVars.stats[index].foundingRaptor == true){
            gameVars.stats[index].cooldownTime = block.timestamp + 6 hours;
        } else {
            gameVars.stats[index].cooldownTime += block.timestamp + 12 hours;
        }
        return gameVars;
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
        
        gameVars = handleQPStats(gameVars);


        emit QuickPlayRaceWinner(gameVars.raptors[gameVars.places[0]]);

        return gameVars.raptors[gameVars.places[0]];

    }

    function handleQPStats(GameVars memory gameVars) internal returns(GameVars memory){
        gameVars = increaseQPWins(gameVars);
        gameVars = upgradeSpeed(gameVars);
        gameVars = increaseTop3RaceFinishes(gameVars);
        gameVars= increaseQPLosses(gameVars);
        gameVars = upgradeAggressiveness(gameVars);
        gameVars = upgradeStrength(gameVars);
        
        for(uint8 i = 0; i<gameVars.n; i++){
            updateStats(gameVars.stats[i], gameVars.raptors[i], gameVars.minterContract);
        }
        return gameVars;
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
        gameVars = increaseCompLosses(gameVars);

        //modify losses & update 
        for(uint8 i = 0; i<gameVars.n; i++){
            updateStats(gameVars.stats[i], gameVars.raptors[i], gameVars.minterContract);
        }

        return gameVars;
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
        
        gameVars = handleDRStats(gameVars);

        emit DeathRaceWinner(gameVars.raptors[gameVars.places[0]]);

        return gameVars.raptors[gameVars.places[0]];
    }

    // //DR Kill/BURN RAPTOR
    function _kill(uint16 raptor, address minter) internal {
        IERC721(minter).safeTransferFrom(getOwner(raptor, minter),address(0),raptor);
    }

    function handleDRStats(GameVars memory gameVars) internal returns(GameVars memory){
        gameVars = increaseCompWins(gameVars);
        gameVars = upgradeSpeed(gameVars);
        gameVars = increaseTop3RaceFinishes(gameVars);
        gameVars = upgradeAggressiveness(gameVars);
        gameVars = upgradeStrength(gameVars);
        gameVars = increaseDeathRaceLosses(gameVars);
        //modify losses & update 
        for(uint8 i = 0; i<gameVars.n; i++){
            updateStats(gameVars.stats[i], gameVars.raptors[i], gameVars.minterContract);
        }

        return gameVars;
    }

    // //---------------------------------------DR----------------------------//


}