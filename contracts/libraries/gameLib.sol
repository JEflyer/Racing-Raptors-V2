//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


import "./structs/stats.sol";

import "./interfaces/IMinter.sol";

import "./libraries/simpleOracleLibrary.sol";

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
    modifier isTwo(uint16[] raptors){
        require(raptors.length == 2, "Incorrect Amount of Raptors");
        _;
    }
    //-------------------------Modifiers-------------------------------//

    //-------------------------Storage-------------------------------//
    //-------------------------Vars-------------------------------//
    uint private distance;
    address private minterContract;
    address private payable communityWallet;
    //-------------------------Vars-------------------------------//
    //-------------------------Setters-------------------------------//
    function SetMinter(address _minter) internal returns(bool){
        minterContract = _minter;
        return true;
    }

    function SetCommunityWallet(address _wallet) internal returns(bool){
        communityWallet = payable(_wallet);
        return true;
    }

    function SetDistance(uint _distance) internal returns(bool){
        distance = _distance;
    }

    //-------------------------Setters-------------------------------//
    //-------------------------Getters-------------------------------//

    function _distance() internal view pure returns(uint){
        return distance;
    }

    function _minter() internal view pure returns (address) {
        return minterContract;
    }

    function _community()internal view pure returns (address){
        return communityWallet;
    }

    //-------------------------Getters-------------------------------//
    //-------------------------Storage-------------------------------//

    //-------------------------Helpers-------------------------------//

    function getStats(uint16 raptor, address minter) internal view pure returns(Stats stats){
        stats = IMinter(_minter()).getStats(raptor);
    }

    
    function updateStats(Stats stats, uint16 raptor) external returns(bool success){
        bool success = IMinter(minter).updateStats(stats, raptor);
        require(success, "There was a problem");
    }

    //Check if msg.sender owns token
    function owns(uint16 raptor) internal returns(bool){
        return (IERC721(minterContract).ownerOf(raptor) == _msgSender()) ? true : false
    }

    function getOwner(uint16 raptor) internal returns(address){
        return IERC721(minterContract).ownerOf(raptor);
    }

    function calcFee(uint pool) internal view pure returns(uint fee){
        fee = (pool / 100) * 5;
    }

    function calcPrize(uint pool) internal  view pure returns (uint prize){
        prize = (pool / 100) * 95;
    }

    function getRandom(uint outOf) internal view returns(uint){
        return (SimpleOracleLibrary.getRandomNumber() % outOf) + 1;
    }

    function _payOut(uint16 winner, uint payout,uint communityPayout) internal payable returns(bool){
        payable(getOwner()).transfer(payout);
        _community().transfer(communityPayot);
        return true;
    }

    function checkBounds(uint8 input) internal view pure returns(bool){
        (input < 8 && input >= 0) ? return true; : return false;
    }

    function getFighters() internal view pure returns(uint8 raptor1, uint8 raptor2){
        uint8 rand = getRandom(147);
        while((rand % 40) == 0 || rand < 8){
            rand = getRandom(167);
        }
        raptor1 = (rand % 5);
        raptor2 = (rand % 8);

        if(raptor1 == raptor2){
            raptor1 += rand % 3;
        }
        check = checkBounds(raptor1);
        if(!check) {
            raptor1 =0 + (rand % 3)
        } 
    }

    //agressiveness & strength not currently factors on who wins the fight
    function getFightWinner(uint8 raptor1, uint8 raptor2) internal view pure returns(uint8){
        (getRandom(2) == 0) ? return raptor1; : return raptor2; 
    }

    function getFastest(uint[] time, uint8[] indexesToIgnore) internal view pure returns (uint8 winner, uint8 second, uint8 third){
        uint16 lowest=20000;
        uint8 winner, second, third;
        for(uint8 i =0; i< 8; i++){
            if(i != indexesToIgnore[0] || i != indexesToIgnore[1]){
                if(time[i]<lowest){
                    third = second;
                    second = winner;
                    winner = i;
                    lowest = time[i];            
                }

            }
        }
        return winner, second, third;
    }

    function getWinner(Stats[] stats, uint8[] indexesToIgnore) internal view pure returns(uint8 winner, uint8 second, uint8 third){
        //get randomness for each raptor
        uint8[] memory randomness = new uint8[](8);
        for(uint i =0; i< 8; i++){
            randomness[i] = getRandom(5);
        }

        //calc times to finish the race first with added randomness
        uint[] memory time = new uint[](8);
        for(uint8 i =0; i< 8; i++){
            time[i] = _distance() / (stats[i].speed + randomness[i]);
        }
        
        //gets fastest & ignores fighter indexes
        return winner, second, third = getFastest(time, indexesToIgnore);
    }

    //-------------------------Helpers--------------------------------//

    //------------------------Stat-Changes------------------------------//
                       // -------  +vary ----------//
    function upgradeAggressiveness(Stats stats) internal returns(Stats){
        uint8 rand = (getRandom(592) %3) +1;
        stats.aggressiveness += rand;
        return stats;
    }

    function upgradeStrength(Stats stats) internal returns(Stats){
        uint8 rand = (getRandom(768) %3) +1;
        stats.strength += rand;
        return stats;
    }

    function upgradeSpeed(Stats stats) internal returns(Stats){
        uint8 rand = (getRandom(523) %3) +1;
        stats.speed += rand;
        return stats;
    }
                       // -------  +Vary ----------//

                       // -------  +1 ----------//
    function increaseQPWins(Stats stats) internal returns(Stats){
        stats.quickPlayRacesWon += 1;
        stats.totalRacesTop3Finish +=1;
        return stats;
    }

    function increaseQPLosses(Stats stats) internal returns(Stats){
        stats.quickPlayRacesLost += 1;
        return stats;
    }

    function increaseCompWins(Stats stats) internal returns(Stats){
        stats.compRacesWon += 1;
        stats.totalRacesTop3Finish += 1;
        return stats;
    }

    function increaseCompLosses(Stats stats) internal returns(Stats){
        stats.compRacesLost += 1;
        return stats;
    }

    function increaseDeathRaceWins(Stats stats) internal returns(Stats){
        stats.deathRacesWon += 1;
        stats.deathRacesSurvived += 1;
        stats.totalRacesTop3Finish += 1;
        return stats;
    }

    function increaseDeathRacesSurvived(Stats stats) internal returns(Stats){
        stats.dathRacesSurvived += 1;
        return stats;
    }

    function increaseTop3RaceFinishes(Stats stats) internal returns(Stats){
        stats.totalRacesTop3Finish += 1;
        return stats;
    }
                       // -------  +1 ----------//

         // -----  +12 Hours/ Unless Founding Raptor 6 Hours -----//
    
    function addCooldownPeriod(Stats stats) internal returns(Stats){
        if(stats.foundingRaptor == true){
            stats.cooldownTime = block.Timestamp() + 6 hours;
        } else {
            stats.cooldownTime += block.Timestamp() + 12 hours;
        }
        return stats;
    }
         // -----  +12 Hours/ Unless Founding Raptor 6 Hours -----//
    //------------------------Stat-Changes---------------------------------//

    //-----------------------------QP--------------------------------------//

    //QP Start
    function _quickPlayStart(uint16[] raptors, uint prizePool) internal returns (bool){
        emit QuickPlayRaceStarted(raptors,prizePool);

        //get stats for each raptor
        Stats[] memory stats = new Stats[](8);
        for (uint8 i =0; i<8;i++){
            stats[i] = getStats(raptors[i]);
        }

        //gets fighters, finds the winner & adds them to indexes to ignore for choosing winner
        uint8 raptor1, raptor2 = getFighters();
        uint8 fightWinner = getFightWinner(raptor1, raptor2);
        uint8[] indexesToIgnore = [raptor1, raptor2];


        //gets the winner & next two places
        uint8 raceWinner, second, third = getWinner(stats,indexesToIgnore);

        //modify states
        stats[raceWinner] = increaseQuickPlayWins(stats[raceWinner]);
        stats[second] = increaseTop3RaceFinishes(stats[second]);
        stats[third] = increaseTop3RaceFinishes(stats[third]);
        stats[raceWinner] = increaseSpeed(stats[raceWinner]);
        stats[fightWinner] = increaseStrength(stats[fightWinner]);

        if(fightWinner == raptor1){ 
            stats[raptor2] = increaseAggressiveness(stats[raptor2]); 
            stats[raptor2] = increaseCooldownTime(stats[raptor2]);
            emit InjuredRaptor(raptor2);
        }else{
            stats[raptor1] = increaseAggressiveness(stats[raptor1]);
            stats[raptor1] = increaseCooldownTime(stats[raptor1]);
            emit InjuredRaptor(raptor1);
        }

        emit FightWinner(fightWinner);        

        //modify losses & update 
        for(uint8 i =0; i<8; i++){
            if(i != raceWinner){
                stats[i] = increaseQuickPlayLosses(stats[i]);
            }
            updateStats(stats[i], raptors[i]);
        }

        //calculates rewards & pays out
        uint fee = calcFee(prizePool);
        uint prize = calcPrize(prizePool);
        _payOut(raceWinner, prize, fee);

        emit QuickPlayRaceWinner(raceWinner, prize, getOwner(raceWinner));

    }

    //---------------------------QP--------------------------------------//
    //----------------------------Comp-----------------------------------//

    //Comp Start
    function _compStart(uint16[] raptors, uint prizePool) internal returns(bool){

    }

    //---------------------------------Comp--------------------------------//
    //-------------------------------DR------------------------------------//

    //DR Start
    function _deathRaceStart(uint16[] raptors, uint prizePool) internal returns(bool){

    }

    //DR Kill/BURN RAPTOR
    function _kill(uint16 raptor) internal returns (bool){
        IERC721(_minter()).safeTransferFrom(ownerOf(raptor),address(0),raptor);
    }

    //---------------------------------------DR----------------------------//


}