//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../structs/stats.sol";

interface IMinter {

    function updateGameAddress(address _gameAddress) external;

    function updateSplitter(address _paymentSplitter) external;

    function getPrice(uint8 _amount) external view returns(uint256 givenPrice);

    function getTotalMinted() external view returns (uint16 total);


    function reveal() external;

    function flipSaleState() external;

    function setAdmin(address _admin) external;

    function tokenURI(uint16 _tokenId) external view returns(string memory uri);

    function mint(uint8 _amount) external payable;

    function walletOfOwner(address _wallet) external view returns(uint16[] memory ids);

    function getStats(uint16 _id) external view returns(Stats memory stats);

    function updateStats(Stats memory _stats, uint16 _id) external returns(bool);

    

}