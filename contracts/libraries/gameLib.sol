//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


import "../structs/stats.sol";

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
    function getFightWinner(uint8 raptor1, uint8 raptor2, uint64 rng) internal returns(uint8 index){
        (rng%2 == 0) ? index = raptor1 : index = raptor2; 
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
    function _quickPlayStart(uint16[] memory raptors, uint64[] memory expandedNums,uint8 n,address minterContract, uint256 distance) internal returns (uint16){
        require(expandedNums.length == n);
        emit QuickPlayRaceStarted(raptors);

        //get stats for each raptor
        Stats[] memory stats = new Stats[](n);
        for (uint8 i =0; i<n;i++){
            stats[i] = getStats(raptors[i], minterContract);
        }

        //gets fighters, finds the winner & adds them to indexes to ignore for choosing winner
        uint8[2] memory fighters = getFighters([expandedNums[0],expandedNums[1]], n);
        uint8 fightWinner = getFightWinner(fighters[0], fighters[1], expandedNums[6]);
        uint8[2] memory indexesToIgnore = [fighters[0], fighters[1]];


        //gets the winner & next two places
        uint8[3] memory places = getWinner(stats,indexesToIgnore, n, expandedNums, distance);

        //modify states //index 0 = winner; index 1 = second; index 2 = third
        {
            stats[places[0]] = increaseQPWins(stats[places[0]]);
            stats[places[0]] = upgradeSpeed(stats[places[0]], expandedNums[2]);
            stats[places[1]] = increaseTop3RaceFinishes(stats[places[1]]);
            stats[places[2]] = increaseTop3RaceFinishes(stats[places[2]]);
            stats[fightWinner] = upgradeStrength(stats[fightWinner], expandedNums[3]);
            if(fightWinner == fighters[0]){ 
                stats[fighters[1]] = upgradeAggressiveness(stats[fighters[1]], expandedNums[4]); 
                stats[fighters[1]] = addCooldownPeriod(stats[fighters[1]]);
                emit InjuredRaptor(fighters[1]);
            }else{
                stats[fighters[0]] = upgradeAggressiveness(stats[fighters[0]], expandedNums[5]);
                stats[fighters[0]] = addCooldownPeriod(stats[fighters[0]]);
                emit InjuredRaptor(fighters[0]);
            }
        }

        

        

        emit FightWinner(fightWinner); 

        //modify losses/survivals & update 
        for(uint8 i =0; i<n; i++){
            
            if(i != fighters[0] || i != fighters[1] || i != places[0]){
                stats[i] = increaseDeathRacesSurvived(stats[i]);
            }

            if(i != places[0]){
                stats[i] = increaseQPLosses(stats[i]);
            }
            updateStats(stats[i], raptors[i], minterContract);
        }


        emit QuickPlayRaceWinner(raptors[places[0]]);

        return raptors[places[0]];

    }

    //---------------------------QP--------------------------------------//
    //----------------------------Comp-----------------------------------//

    // //Comp Start
    function _compStart(uint16[] memory raptors, uint64[] memory expandedNums,uint8 n,address minterContract, uint256 distance) internal returns(uint16){
        require(expandedNums.length == n);
        emit CompetitiveRaceStarted(raptors);

        //get stats for each raptor
        Stats[] memory stats = new Stats[](n);
        for (uint8 i =0; i<n;i++){
            stats[i] = getStats(raptors[i], minterContract);
        }

        

        //gets fighters, finds the winner & adds them to indexes to ignore for choosing winner
        uint8[2] memory fighters = getFighters([expandedNums[0],expandedNums[1]], n);
        uint8 fightWinner = getFightWinner(fighters[0], fighters[1], expandedNums[6]);
        uint8[2] memory indexesToIgnore = [fighters[0], fighters[1]];


        //gets the winner & next two places
        uint8[3] memory places = getWinner(stats,indexesToIgnore, n, expandedNums, distance);

        //modify states //index 0 = winner; index 1 = second; index 2 = third
        {
            stats[places[0]] = increaseCompWins(stats[places[0]]);
            stats[places[0]] = upgradeSpeed(stats[places[0]], expandedNums[2]);
            stats[places[1]] = increaseTop3RaceFinishes(stats[places[1]]);
            stats[places[2]] = increaseTop3RaceFinishes(stats[places[2]]);
            stats[fightWinner] = upgradeStrength(stats[fightWinner], expandedNums[3]);
            if(fightWinner == fighters[0]){ 
                stats[fighters[1]] = upgradeAggressiveness(stats[fighters[1]], expandedNums[4]); 
                stats[fighters[1]] = addCooldownPeriod(stats[fighters[1]]);
                emit InjuredRaptor(raptors[fighters[1]]);
            }else{
                stats[fighters[0]] = upgradeAggressiveness(stats[fighters[0]], expandedNums[4]);
                stats[fighters[0]] = addCooldownPeriod(stats[fighters[0]]);
                emit InjuredRaptor(raptors[fighters[0]]);
            }
        }

        

        

        emit FightWinner(fightWinner);        

        //modify losses & update 
        for(uint8 i =0; i<n; i++){
            if(i != places[0]){
                stats[i] = increaseCompLosses(stats[i]);
            }
            updateStats(stats[i], raptors[i], minterContract);
        }


        emit CompetitiveRaceWinner(raptors[places[0]]);

        return raptors[places[0]];

    }

    // //---------------------------------Comp--------------------------------//
    // //-------------------------------DR------------------------------------//

    // //DR Start
    function _deathRaceStart(uint16[] memory raptors, uint64[] memory expandedNums,uint8 n,address minterContract, uint256 distance) internal returns(uint16){
        require(expandedNums.length == n);
        emit DeathRaceStarted(raptors);

        //get stats for each raptor
        Stats[] memory stats = new Stats[](n);
        for (uint8 i =0; i<n;i++){
            stats[i] = getStats(raptors[i], minterContract);
        }

        //gets fighters, finds the winner & adds them to indexes to ignore for choosing winner
        uint8[2] memory fighters = getFighters([expandedNums[0],expandedNums[1]], n);
        uint8 fightWinner = getFightWinner(fighters[0], fighters[1], expandedNums[6]);
        uint8[2] memory indexesToIgnore = [fighters[0], fighters[1]];


        //gets the winner & next two places
        uint8[3] memory places = getWinner(stats,indexesToIgnore, n, expandedNums, distance);

        //modify states //index 0 = winner; index 1 = second; index 2 = third
        {
            stats[places[0]] = increaseDeathRaceWins(stats[places[0]]);
            stats[places[0]] = upgradeSpeed(stats[places[0]], expandedNums[2]);
            stats[places[1]] = increaseTop3RaceFinishes(stats[places[1]]);
            stats[places[2]] = increaseTop3RaceFinishes(stats[places[2]]);
            stats[fightWinner] = upgradeStrength(stats[fightWinner], expandedNums[3]);
            if(fightWinner == fighters[0]){ 
                _kill(raptors[fighters[1]], minterContract);
                emit RipRaptor(raptors[fighters[1]]);
            }else{
                _kill(raptors[fighters[0]], minterContract);
                emit RipRaptor(raptors[fighters[0]]);
            }
        }

        

        

        emit FightWinner(raptors[fightWinner]);        

        //modify losses & update 
        for(uint8 i =0; i<n; i++){
            if(i != places[0]){
                stats[i] = increaseDeathRaceLosses(stats[i]);
            }
            updateStats(stats[i], raptors[i], minterContract);
        }

        emit DeathRaceWinner(raptors[places[0]]);

        return raptors[places[0]];
    }

    // //DR Kill/BURN RAPTOR
    function _kill(uint16 raptor, address minter) internal {
        IERC721(minter).safeTransferFrom(getOwner(raptor, minter),address(0),raptor);
    }

    // //---------------------------------------DR----------------------------//


}