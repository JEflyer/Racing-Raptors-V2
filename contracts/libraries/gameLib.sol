//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

library gameLib {


    //-------------------------Helpers-------------------------------//

    function calcFee(uint pool, uint8 feePercent) internal view pure returns(uint fee){
        fee = (pool / 100) * feePercent;
    }

    //-------------------------Helpers--------------------------------//

    //------------------------Stat-Changes------------------------------//
                       // -------  +1 ----------//
    function upgradeAggressiveness(uint16 raptor) internal returns (bool){

    }

    function upgradeStrength(uint16 raptor) internal returns (bool){

    }

    function upgradeSpeed(uint16 raptor) internal returns (bool){

    }

    function increaseQPWins(uint16 raptor) internal returns(bool){

    }

    function increaseQPLosses(uint16 raptor) internal returns(bool){

    }

    function increaseCompWins(uint16 raptor) internal returns(bool){

    }

    function increaseCompLosses(uint16 raptor) internal returns(bool){

    }

    function increaseDeathRaceWins(uint16 raptor) internal returns(bool){

    }

    function increaseDeathRaceLosses(uint16 raptor) internal returns (bool){

    }

    function increaseDeathRacesSurvived(uint16 raptor) internal returns (bool){

    }

    function increaseTop3RaceFinishes(uint16 raptor) internal returns(bool){

    }
                       // -------  +1 ----------//

         // -----  +12 Hours/ Unless Founding Raptor 6 Hours -----//
    
    function addCooldownPeriod(uint16 raptor) internal returns(bool){

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