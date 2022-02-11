//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

library gameLib {


    function calcFee(uint pool, uint8 feePercent) internal view pure returns(uint fee){
        fee = (pool / 100) * feePercent;
    }

}