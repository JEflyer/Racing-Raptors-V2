//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

library gameLib {


    function calcFee(uint pool, uint8 feePercent) internal view pure returns(uint fee){
        fee = (pool / 100) * feePercent;
    }

    //stat upgrade functions
    function upgradeAggressiveness(uint16 raptor) internal returns (bool){

    }

    function upgradeHealth(uint16 raptor) internal returns (bool){

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

    function addCooldownPeriod(uint16 raptor) internal returns(bool){

    }

}