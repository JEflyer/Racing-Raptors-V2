//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


import "../structs/stats.sol";

import "../interfaces/IMinter.sol";

import "./simpleOracleLibrary.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

library gameLib {
    //-------------------------Events-------------------------------//
    event InjuredRaptor(uint16 raptor);
    event FightWinner(uint16 raptor);

    event QuickPlayRaceStarted(uint16[] raptors, uint prizePool);
    event QuickPlayRaceWinner(uint16 raptor, uint prize, address raptorOwner);

    event CompetitiveRaceStarted(uint16[] raptors, uint prizePool);
    event CompetitiveRaceWinner(uint16 raptor, uint prize);

    event DeathRaceStarted(uint16[] raptors, uint prizePool);
    event DeathRaceWinner(uint16 raptor, uint prize);
    event RipRaptor(uint16 raptor);
    //-------------------------Events-------------------------------//

    //-------------------------Modifiers-------------------------------//
    modifier isTwo(uint16[] memory raptors){
        require(raptors.length == 2, "Incorrect Amount of Raptors");
        _;
    }
    //-------------------------Modifiers-------------------------------//

    //-------------------------Storage-------------------------------//
    //-------------------------Vars-------------------------------//
    //use assembly slots for these

    bytes32 constant distanceSlot = keccak256("Distnce");
    // uint private distance;
    
    bytes32 constant minterContractSlot = keccak256("Minter");
    // address private minterContract;

    bytes32 constant communityWalletSlot = keccak256("Community");
    // address private payable communityWallet;

    //-------------------------Vars-------------------------------//
    //-------------------------Structs-------------------------------//
    struct DistanceStore {
        uint distance;
    }

    struct MinterStore{
        address minterContract;
    }

    //-------------------------Structs-------------------------------//
    //-------------------------Slotter-------------------------------//

    function distanceStorage() internal pure returns (DistanceStore storage distanceStore){
        bytes32 slot = distanceSlot;
        assembly {
            distanceStore.slot := slot
        }
    }

    function minterStorage() internal pure returns (MinterStore storage minterStore){
        bytes32 slot = minterContractSlot;
        assembly{
            minterStore.slot := slot
        }
    }

    //-------------------------Slotter-------------------------------//
    
    //-------------------------Getters-------------------------------//

    function _distance() internal view returns(uint){
        return distanceStorage().distance;
    }

    function _minter() internal view returns (address) {
        return minterStorage().minterContract;
    }

    //-------------------------Getters-------------------------------//

    //-------------------------Setters-------------------------------//

    function SetMinter(address minter) internal returns(bool){
        minterStorage().minterContract = minter;
        return true;
    }

    function SetDistance(uint distance) internal returns(bool){
        distanceStorage().distance = distance;
        return true;
    }

    //-------------------------Setters-------------------------------//
    //-------------------------Storage-------------------------------//

    //-------------------------Helpers-------------------------------//

    function getStats(uint16 raptor) internal view returns(Stats memory stats){
        stats = IMinter(_minter()).getStats(raptor);
    }

    
    function updateStats(Stats memory stats, uint16 raptor) internal returns(bool success){
        success = IMinter(_minter()).updateStats(stats, raptor);
        require(success, "There was a problem");
    }

    //Check if msg.sender owns token
    function owns(uint16 raptor) internal view returns(bool){
        return (IERC721(_minter()).ownerOf(raptor) == msg.sender) ? true : false;
    }

    function getOwner(uint16 raptor) internal view returns(address){
        return IERC721(_minter()).ownerOf(raptor);
    }

    function calcFee(uint pool) internal pure returns(uint fee){
        fee = (pool / 100) * 5;
    }

    function calcPrize(uint pool) internal pure returns (uint prize){
        prize = (pool / 100) * 95;
    }

    function getRandom(uint outOf) internal returns(uint){
        return (SimpleOracleLibrary.getRandomNumber() % outOf) + 1;
    }

    function checkBounds(uint8 input) internal pure returns(bool response){
        (input < 8 && input >= 0) ? response = true : response = false;
    }

    function getFighters() internal returns(uint8[2] memory fighters){
        uint8 rand = uint8(getRandom(147));
        while((rand % 40) == 0 || rand < 8){
            rand = uint8(getRandom(167));
        }
        uint8 raptor1 = (rand % 5);
        uint8 raptor2 = (rand % 8);

        if(raptor1 == raptor2){
            raptor1 += rand % 3;
        }
        bool check = checkBounds(raptor1);
        if(!check) {
            raptor1 =0 + (rand % 3);
        } 
        fighters[0] = raptor1;
        fighters[1] = raptor2;
    }

    //agressiveness & strength not currently factors on who wins the fight
    function getFightWinner(uint8 raptor1, uint8 raptor2) internal returns(uint8 index){
        (getRandom(2) == 0) ? index = raptor1 : index = raptor2; 
    }

    function getFastest(uint[8] memory time, uint8[2] memory indexesToIgnore) internal pure returns (uint8[3] memory places){
        uint16 lowest=20000;
        uint8 winner;
        uint8 second;
        uint8 third;
        for(uint8 i =0; i< 8; i++){
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

    function getWinner(Stats[] memory stats, uint8[2] memory indexesToIgnore) internal returns(uint8[3] memory places){
        //get randomness for each raptor
        uint8[] memory randomness = new uint8[](8);
        for(uint i =0; i< 8; i++){
            randomness[i] = uint8(getRandom(5));
        }

        //calc times to finish the race first with added randomness
        uint[8] memory time;
        for(uint8 i =0; i< 8; i++){
            time[i] = _distance() / (stats[i].speed + randomness[i]);
        }
        
        //gets fastest & ignores fighter indexes
        places = getFastest(time, indexesToIgnore);
    }

    //-------------------------Helpers--------------------------------//

    //------------------------Stat-Changes------------------------------//
                       // -------  +vary ----------//
    function upgradeAggressiveness(Stats memory stats) internal returns(Stats memory){
        uint8 rand = uint8(getRandom(592) %3) +1;
        stats.agressiveness += rand;
        return stats;
    }

    function upgradeStrength(Stats memory stats) internal returns(Stats memory){
        uint8 rand = uint8(getRandom(768) %3) +1;
        stats.strength += rand;
        return stats;
    }

    function upgradeSpeed(Stats memory stats) internal returns(Stats memory){
        uint8 rand = uint8(getRandom(523) %3) +1;
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
    function _quickPlayStart(uint16[] memory raptors, uint prizePool) internal returns (uint16){
        emit QuickPlayRaceStarted(raptors,prizePool);

        //get stats for each raptor
        Stats[] memory stats = new Stats[](8);
        for (uint8 i =0; i<8;i++){
            stats[i] = getStats(raptors[i]);
        }

        //gets fighters, finds the winner & adds them to indexes to ignore for choosing winner
        uint8[2] memory fighters = getFighters();
        uint8 fightWinner = getFightWinner(fighters[0], fighters[1]);
        uint8[2] memory indexesToIgnore = [fighters[0], fighters[1]];


        //gets the winner & next two places
        uint8[3] memory places = getWinner(stats,indexesToIgnore);

        //modify states //index 0 = winner; index 1 = second; index 2 = third
        stats[places[0]] = increaseQPWins(stats[places[0]]);
        stats[places[0]] = upgradeSpeed(stats[places[0]]);
        stats[places[1]] = increaseTop3RaceFinishes(stats[places[1]]);
        stats[places[2]] = increaseTop3RaceFinishes(stats[places[2]]);

        stats[fightWinner] = upgradeStrength(stats[fightWinner]);

        if(fightWinner == fighters[0]){ 
            stats[fighters[1]] = upgradeAggressiveness(stats[fighters[1]]); 
            stats[fighters[1]] = addCooldownPeriod(stats[fighters[1]]);
            emit InjuredRaptor(fighters[1]);
        }else{
            stats[fighters[0]] = upgradeAggressiveness(stats[fighters[0]]);
            stats[fighters[0]] = addCooldownPeriod(stats[fighters[0]]);
            emit InjuredRaptor(fighters[0]);
        }

        emit FightWinner(fightWinner); 

        //modify losses/survivals & update 
        for(uint8 i =0; i<8; i++){
            
            if(i != fighters[0] || i != fighters[1] || i != places[0]){
                stats[i] = increaseDeathRacesSurvived(stats[i]);
            }

            if(i != places[0]){
                stats[i] = increaseQPLosses(stats[i]);
            }
            updateStats(stats[i], raptors[i]);
        }

        //calculates reward
        uint prize = calcPrize(prizePool);

        emit QuickPlayRaceWinner(places[0], prize, getOwner(places[0]));

        return places[0];

    }

    //---------------------------QP--------------------------------------//
    //----------------------------Comp-----------------------------------//

    // //Comp Start
    function _compStart(uint16[] memory raptors, uint prizePool) internal returns(uint16){
        emit CompetitiveRaceStarted(raptors,prizePool);

        //get stats for each raptor
        Stats[] memory stats = new Stats[](8);
        for (uint8 i =0; i<8;i++){
            stats[i] = getStats(raptors[i]);
        }

        //gets fighters, finds the winner & adds them to indexes to ignore for choosing winner
        uint8[2] memory fighters = getFighters();
        uint8 fightWinner = getFightWinner(fighters[0], fighters[1]);
        uint8[2] memory indexesToIgnore = [fighters[0], fighters[1]];


        //gets the winner & next two places
        uint8[3] memory places = getWinner(stats,indexesToIgnore);

        //modify states //index 0 = winner; index 1 = second; index 2 = third
        stats[places[0]] = increaseCompWins(stats[places[0]]);
        stats[places[0]] = upgradeSpeed(stats[places[0]]);
        stats[places[1]] = increaseTop3RaceFinishes(stats[places[1]]);
        stats[places[2]] = increaseTop3RaceFinishes(stats[places[2]]);

        stats[fightWinner] = upgradeStrength(stats[fightWinner]);

        if(fightWinner == fighters[0]){ 
            stats[fighters[1]] = upgradeAggressiveness(stats[fighters[1]]); 
            stats[fighters[1]] = addCooldownPeriod(stats[fighters[1]]);
            emit InjuredRaptor(raptors[fighters[1]]);
        }else{
            stats[fighters[0]] = upgradeAggressiveness(stats[fighters[0]]);
            stats[fighters[0]] = addCooldownPeriod(stats[fighters[0]]);
            emit InjuredRaptor(raptors[fighters[0]]);
        }

        emit FightWinner(fightWinner);        

        //modify losses & update 
        for(uint8 i =0; i<8; i++){
            if(i != places[0]){
                stats[i] = increaseCompLosses(stats[i]);
            }
            updateStats(stats[i], raptors[i]);
        }

        //calculates reward
        uint prize = calcPrize(prizePool);

        emit CompetitiveRaceWinner(places[0], prize);

        return raptors[places[0]];

    }

    // //---------------------------------Comp--------------------------------//
    // //-------------------------------DR------------------------------------//

    // //DR Start
    function _deathRaceStart(uint16[] memory raptors, uint prizePool) internal returns(uint16){
        emit DeathRaceStarted(raptors,prizePool);

        //get stats for each raptor
        Stats[] memory stats = new Stats[](8);
        for (uint8 i =0; i<8;i++){
            stats[i] = getStats(raptors[i]);
        }

        //gets fighters, finds the winner & adds them to indexes to ignore for choosing winner
        uint8[2] memory fighters = getFighters();
        uint8 fightWinner = getFightWinner(fighters[0], fighters[1]);
        uint8[2] memory indexesToIgnore = [fighters[0], fighters[1]];


        //gets the winner & next two places
        uint8[3] memory places = getWinner(stats,indexesToIgnore);

        //modify states //index 0 = winner; index 1 = second; index 2 = third
        stats[places[0]] = increaseDeathRaceWins(stats[places[0]]);
        stats[places[0]] = upgradeSpeed(stats[places[0]]);
        stats[places[1]] = increaseTop3RaceFinishes(stats[places[1]]);
        stats[places[2]] = increaseTop3RaceFinishes(stats[places[2]]);

        stats[fightWinner] = upgradeStrength(stats[fightWinner]);

        if(fightWinner == fighters[0]){ 
            _kill(raptors[fighters[1]]);
            emit RipRaptor(raptors[fighters[1]]);
        }else{
            _kill(raptors[fighters[0]]);
            emit RipRaptor(raptors[fighters[0]]);
        }

        emit FightWinner(raptors[fightWinner]);        

        //modify losses & update 
        for(uint8 i =0; i<8; i++){
            if(i != places[0]){
                stats[i] = increaseDeathRaceLosses(stats[i]);
            }
            updateStats(stats[i], raptors[i]);
        }

        //calculates reward
        uint prize = calcPrize(prizePool);

        emit DeathRaceWinner(places[0], prize);

        return raptors[places[0]];
    }

    // //DR Kill/BURN RAPTOR
    function _kill(uint16 raptor) internal returns (bool){
        IERC721(_minter()).safeTransferFrom(getOwner(raptor),address(0),raptor);
    }

    // //---------------------------------------DR----------------------------//


}