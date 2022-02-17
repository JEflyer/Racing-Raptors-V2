//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


import "./simpleOracleLibrary.sol";

library minterLib {

    function updatePrice(uint _price)internal returns(uint price) {
        price = _price << 1;
    }

    function crossesThreshold(uint _amount, uint _totalSupply) internal view returns (bool answer){
        uint remainder = (_totalSupply + _amount) % 1000;
        if(remainder >= 0 && remainder < 10) {
            answer = true;
        } else {
            answer = false;
        }
    }

    function getRandom(uint outOf) internal view returns(uint){
        return (SimpleOracleLibrary.getRandomNumber() % outOf) + 1;
    }

    function getAmounts(uint _amount, uint _totalSupply) internal view returns(uint8 amountBefore, uint8 amountAfter){
        for (uint i = 0; i < _amount; i++){
            if (crossesThreshold(i,_totalSupply)){
                amountBefore = uint8(i +1);
                amountAfter = uint8(_amount-amountBefore);
            }
        }
    }
}