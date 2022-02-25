//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../structs/stats.sol";

interface IMinter {

    function getPrice(uint8 _amount) external view returns(uint256 givenPrice);

    function getTotalMinted() external view returns (uint16 total);

    function isFoundingRaptor(uint16 raptor) external returns(bool);

    function tokenURI(uint16 _tokenId) external view returns(string memory uri);

    function walletOfOwner(address _wallet) external view returns(uint16[] memory ids);


    function getStats(uint16 _raptor) external view returns(Stats memory stats);

    function getSpeed(uint16 _raptor) external view returns(uint16);

    function getStrength(uint16 _raptor) external view returns(uint16);

    function getCoolDown(uint16 _raptor) external view returns(uint32 time);

    function getAgressiveness(uint16 _raptor) external view returns(uint16);


    function upgradeSpeed(uint16 _raptor, uint8 _amount) external returns(bool);

    function upgradeStrength(uint16 _raptor, uint8 _amount) external returns(bool);

    function upgradeAgressiveness(uint16 _raptor, uint8 _amount) external returns(bool);

    function upgradefightsWon(uint16 _raptor) external returns(bool);

    function upgradeQPWins(uint16 _raptor) external returns(bool);

    function upgradeCompWins(uint16 _raptor) external returns(bool);

    function upgradeDRWins(uint16 _raptor) external returns(bool);

    function upgradeTop3Finishes(uint16 _raptor) external returns(bool);

    function increaseCooldownTime(uint16 _raptor) external returns(bool);


    

}