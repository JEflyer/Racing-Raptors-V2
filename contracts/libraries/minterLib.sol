//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

library minterLib {

    function updatePrice(uint _price)internal returns(uint price) {
        price = _price << 1;
    }

    function crossesThreshold(uint _amount, uint _totalSupply) internal view pure returns (bool answer){
        uint memory remainder = (_totalSupply + _amount) % 1000;
        if(remainder >= 0 && remainder < 10) {
            answer = true;
        } else {
            answer = false;
        }
    }

    function getAmounts(uint _amount, uint _totalSupply) internal pure view returns(uint amountBefore, uint amountAfter){
        for (uint i = 0; i < _amount; i++){
            if (crossesThreshold(_totalSupply + i)){
                amountBefore = i +1;
                amountAfter = _amount-amountBefore;
            }
        }
    }
}