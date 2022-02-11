//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface Minter {

    function updateGameAddress(address _gameAddress) external onlyAdmin;

    function updateSplitter(address _paymentSplitter) external onlyAdmin;

    function getPrice(uint8 _amount) external view returns(uint256 givenPrice);

    function getTotalMinted() external view returns (uint16 total);


    function reveal() onlyAdmin external;

    function flipSaleState() external onlyAdmin;

    function setAdmin(address _admin) external onlyAdmin;

    function tokenURI(uint16 _tokenId) external view virtual override returns(string memory uri);

    function mint(uint8 _amount) external payable;

    function walletOfOwner(address _wallet) external view pure returns(uint16[] memory ids);

    function getStats(uint16 _id) external view pure returns(Stats stats);

    function updateStats(Stats _stats, uint16 _id) external onlyGameAddress returns(bool);

    

}