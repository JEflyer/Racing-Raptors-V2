//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


import "./simpleOracleLibrary.sol";
import "hardhat/console.sol";

library minterLib {

    function updatePrice(uint _price)internal pure returns(uint price) {
        price = _price << 1;
    }

    function crossesThreshold(uint _amount, uint _totalSupply) internal pure returns (bool){
        if(_totalSupply+_amount < 1000) return false;
        uint remainder = (_totalSupply + _amount) % 1000;
        if(remainder >= 0 && remainder < 10) {
            return true;
        } else {
            return false;
        }
    }

    function getRandom(uint outOf) internal returns(uint){
        return (SimpleOracleLibrary.getRandomNumber() % outOf) + 1;
    }

    function getAmounts(uint _amount, uint _totalSupply) internal pure returns(uint8 amountBefore, uint8 amountAfter){
        for (uint i = 0; i < _amount; i++){
            if (crossesThreshold(i+1,_totalSupply)){
                amountBefore = uint8(i +1);
                amountAfter = uint8(_amount-amountBefore);
                break;
            }
        }
    }
}