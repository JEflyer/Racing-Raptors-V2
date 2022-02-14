//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


import "./structs/stats.sol";

import "./interfaces/IMinter.sol";

import "./libraries/simpleOracleLibrary.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

library gameLib {
    //-------------------------Storage-------------------------------//
    //-------------------------Vars-------------------------------//

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

    //-------------------------Setters-------------------------------//
    //-------------------------Getters-------------------------------//

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

    function calcFee(uint pool, uint8 feePercent) internal view pure returns(uint fee){
        fee = (pool / 100) * feePercent;
    }

    function getRandom(uint outOf) internal view returns(uint){
        return (SimpleOracleLibrary.getRandomNumber() % outOf) + 1;
    }

    function _payOut(uint16 winner, uint payout,uint communityPayout) internal payable returns(bool){
        payable(getOwner()).transfer(payout);
        _community().transfer(communityPayot);
        return true;
    }

    //-------------------------Helpers--------------------------------//

    //------------------------Stat-Changes------------------------------//
                       // -------  +vary ----------//
    function upgradeAggressiveness(uint16 raptor) internal returns (bool){
        uint rand = (getRandom(592) %3) +1;
        stats = getStats(raptor);
        stats.aggressiveness += rand;
        bool success = updateStats(stats,raptor);
        require(success);
        return true;
    }

    function upgradeStrength(uint16 raptor) internal returns (bool){
        uint rand = (getRandom(768) %3) +1;
        stats = getStats(raptor);
        stats.strength += rand;
        bool success = updateStats(stats,raptor);
        require(success);
        return true;
    }

    function upgradeSpeed(uint16 raptor) internal returns (bool){
        uint rand = (getRandom(523) %3) +1;
        stats = getStats(raptor);
        stats.speed += rand;
        bool success = updateStats(stats,raptor);
        require(success);
        return true;
    }
                       // -------  +Vary ----------//



// struct Stats{
//     uint16 speed,
//     uint16 strength,
//     uint16 agressiveness,
//     uint16 fightsWon,
//     uint16 fightsLost,
//     uint16 quickPlayRacesWon,
//     uint16 quickPlayRacesLost,
//     uint16 compRacesWon,
//     uint16 compRacesLost,
//     uint16 deathRacesWon,
//     uint16 deathRacesSurvived,
//     uint16 deathRaceFightsWon,
//     uint16 totalRacesTop3Finish,
//     uint256 cooldownTime,

                       // -------  +1 ----------//
    function increaseQPWins(uint16 raptor) internal returns(bool){
        stats = getStats(raptor);
        stats.quickPlayRacesWon += 1;
        bool success = updateStats(stats,raptor);
        require(success);
        return true;
    }

    function increaseQPLosses(uint16 raptor) internal returns(bool){
        stats = getStats(raptor);
        stats.quickPlayRacesLost += 1;
        bool success = updateStats(stats,raptor);
        require(success);
        return true;
    }

    function increaseCompWins(uint16 raptor) internal returns(bool){
        stats = getStats(raptor);
        stats.compRacesWon += 1;
        bool success = updateStats(stats,raptor);
        require(success);
        return true;
    }

    function increaseCompLosses(uint16 raptor) internal returns(bool){
        stats = getStats(raptor);
        stats.compRacesLost += 1;
        bool success = updateStats(stats,raptor);
        require(success);
        return true;
    }

    function increaseDeathRaceWins(uint16 raptor) internal returns(bool){
        stats = getStats(raptor);
        stats.deathRacesWon += 1;
        stats.deathRacesSurvived += 1;
        bool success = updateStats(stats,raptor);
        require(success);
        return true;
    }

    function increaseDeathRacesSurvived(uint16 raptor) internal returns (bool){
        stats = getStats(raptor);
        stats.dathRacesSurvived += 1;
        bool success = updateStats(stats,raptor);
        require(success);
        return true;
    }

    function increaseTop3RaceFinishes(uint16 raptor) internal returns(bool){
        stats = getStats(raptor);
        stats.totalRacesTop3Finish += 1;
        bool success = updateStats(stats,raptor);
        require(success);
        return true;
    }
                       // -------  +1 ----------//

         // -----  +12 Hours/ Unless Founding Raptor 6 Hours -----//
    
    function addCooldownPeriod(uint16 raptor) internal returns(bool){
        stats = getStats(raptor);
        if(stats.foundingRaptor == true){
            stats.cooldownTime = block.Timestamp() + 6 hours;
        } else {
            stats.cooldownTime += block.Timestamp() + 12 hours;
        }
        bool success = updateStats(stats,raptor);
        require(success);
        return true;
    }
         // -----  +12 Hours/ Unless Founding Raptor 6 Hours -----//
    //------------------------Stat-Changes---------------------------------//

    //-----------------------------QP--------------------------------------//

    //QP Start
    function _quickPlayStart(uint16[] raptors, uint prizePool) internal returns (bool){

    }

    //QP End
    function _quickPlayEnd(uint16 winner, uint payout, uint communityPayout) internal payable returns(bool){

    }

    //QP Fight
    function _quickPlayFight(uint16[] raptorsFighting) internal isTwo(raptorsFighting) returns (uint16 winner){

    }

    //---------------------------QP--------------------------------------//
    //----------------------------Comp-----------------------------------//

    //Comp Start
    function _compStart(uint16[] raptors, uint prizePool) internal returns(bool){

    }

    //Comp End
    function _compEnd(uint16 winner, uint payout, uint communityPayout) internal payable returns(bool){

    }

    //Comp Fight
    function _compFight(uint16[] raptorsFighting) internal isTwo(raptorsFighting) returns (uint16 winner){

    }

    //---------------------------------Comp--------------------------------//
    //-------------------------------DR------------------------------------//

    //DR Start
    function _deathRaceStart(uint16[] raptors, uint prizePool) internal returns(bool){

    }

    //DR End
    function _deathRaceEnd(uint16 winner, uint payout, uint communityPayout) internal payable returns(bool){

    }

    //DR Fight
    function _fightToTheDeath(uint16[] raptorsFighting) internal isTwo(raptorsFighting) returns(bool){

    }

    //DR Kill/BURN RAPTOR
    function _kill(uint16 raptor) internal returns (bool){

    }

    //---------------------------------------DR----------------------------//


}