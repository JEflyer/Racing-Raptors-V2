//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


library minterLib {

    event PriceIncrease(uint newPrice);

    function updatePrice(uint _price)internal returns(uint price) {
        price = _price << 1;
        emit PriceIncrease(price);
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

    function getAmounts(uint _amount, uint _totalSupply) internal pure returns(uint8 amountBefore, uint8 amountAfter){
        for (uint i = 0; i < _amount; i++){
            if (crossesThreshold(i+1,_totalSupply)){
                amountBefore = uint8(i +1);
                amountAfter = uint8(_amount-amountBefore);
                break;
            }
        }
    }

    function getPrice(uint8 _amount, uint price, uint16 totalMintSupply) internal pure returns(uint256 givenPrice){
        require(_amount <= 10, "Err: Too high");
        bool answer = crossesThreshold(_amount,totalMintSupply);
        if(answer){
            (uint8 amountBefore, uint8 amountAfter) = getAmounts(_amount,totalMintSupply);
            givenPrice = (price*amountBefore) + (price * 2 * amountAfter);
        } else {
            givenPrice = price * _amount;
        }
    }
}