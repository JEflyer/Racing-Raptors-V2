//SPDF-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./interfaces/IGame.sol";
import "./interfaces/IMinter.sol";

import "./libraries/minterLib.sol";

import "./structs/stats.sol";



import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import "hardhat/console.sol";
// took out the following libraries from inheritance : IERC721Receiver, IERC721Metadata,  Context,
contract Minter is ERC721Enumerable, IMinter {

    event SoldOut(string message);
    event PorscheWinner(address winner);
    event PriceIncrease(uint newPrice);
    event NewGameContract(address gameContract);
    event NewAdmin(address newAdmin);
    event StatsUpdated(uint16 tokenId, Stats stats);
    event Mint(address to, uint16 tokenId);

    address public admin;
    
    bool public active;
    string private baseURI;
    string private CID;
    string private extension;
    string private notRevealed;

    string private soldOutMessage;

    mapping(uint16 => Stats) private raptorStats; //token id => stats

    uint256 private price;
    uint16 private totalMintSupply;
    uint16 private totalLimit;

    bool private revealed;

    address private gameAddress;

    //commented out for testing
    // address[] rewardedAddresses = [
    //     //holders of racing raptors v1 NFTs 

    // ];

    address[] rewardedAddresses;

    uint8[] rewardedAmounts = [
        //amounts held for each holder
        1,2,2
    ];

    address[] public paymentsTo;

    constructor(
        string memory _baseURI,
        string memory _CID,
        string memory _notRevealed,
        string memory _extension,
        uint16 _totalLimit,
        string memory _soldOutMessage,
        address[] memory _rewardedAddresses,
        address[] memory _paymentsTo
        )ERC721("Racing Raptors V2", "RR"){
            require(_rewardedAddresses.length ==3);//just here for testing, the addresses and amounts will be hardcoded into the main contract
            require(_paymentsTo.length == 3);
            rewardedAddresses = _rewardedAddresses;
            baseURI = _baseURI;
            CID = _CID;
            notRevealed = _notRevealed;
            extension = _extension;
            active = true;
            totalMintSupply = 0;
            totalLimit = _totalLimit;
            price = 2 * 10**18;
            admin = _msgSender();
            paymentsTo = _paymentsTo;
            soldOutMessage = _soldOutMessage;
            reward();
    }

    function updateGameAddress(address _gameAddress) public onlyAdmin {
        gameAddress = _gameAddress;
        emit NewGameContract(_gameAddress);
    }

    function updatePaymentTo(address _paymentTo, uint8 index) public onlyAdmin {
        paymentsTo[index] = _paymentTo;
    }

    function getPrice(uint8 _amount) public view override returns(uint256 givenPrice){
        require(_amount <= 10, "Too high of an amount");
        bool answer = minterLib.crossesThreshold(_amount,totalMintSupply);
        if(answer == true){
            (uint8 amountBefore, uint8 amountAfter) = minterLib.getAmounts(_amount,totalMintSupply);
            console.log(amountBefore);
            console.log(amountAfter);
            givenPrice = (price*amountBefore) + (price * 2 * amountAfter);
        } else {
            givenPrice = price * _amount;
        }
    }

    function getTotalMinted() public view override returns (uint16 total){
        total = totalMintSupply;
    }

    modifier onlyAdmin{
        require(_msgSender() == admin, "Only A");
        _;
    }

    modifier onlyGameAddress{
        require(_msgSender() == gameAddress, "only GC");
        _;
    }

    function reveal() onlyAdmin public {
        revealed = true;
    }

    function flipSaleState() public onlyAdmin {
        active = !active;
    }

    function setAdmin(address _admin) public onlyAdmin{
        admin = _admin;
        emit NewAdmin(_admin);
    }

    function tokenURI(uint16 _tokenId) public view virtual override returns(string memory uri){
        require(_exists(_tokenId), "This token does not exist");

        if(!revealed) {uri = string(abi.encodePacked(baseURI, notRevealed));}
        else{uri = string(abi.encodePacked(baseURI, CID, string(abi.encodePacked(_tokenId)), extension));}

    }

    function chooseWinner() internal returns(address) {
        //use chainink to get random number between 1 & 10000
        uint16 tokenId = uint16(minterLib.getRandom(10000));

        //find owner 
        return ownerOf(tokenId);
    }

    //split & send funds
    function splitFunds(uint256 fundsToSplit) public payable {
        require(fundsToSplit >= address(this).balance, "Contract balance is insufficient");
        require(payable(paymentsTo[0]).send(fundsToSplit * 25/100));//for dev
        require(payable(paymentsTo[1]).send(fundsToSplit * 50/100));//for development& floor sweeping
        require(payable(paymentsTo[2]).send(fundsToSplit * 25/100));//for charity & giveaways
    }


    receive() external payable {
        splitFunds(msg.value);
    }

    function mint(uint8 _amount) public payable {
        require(active, "This function is not available right now");

        if(_msgSender() != admin){
            require(msg.value == getPrice(_amount),"Not enough funds sent");
            if(minterLib.crossesThreshold(_amount, totalMintSupply)){ 
                price = minterLib.updatePrice(price);
                emit PriceIncrease(price);
            } 
            splitFunds(msg.value);
        }
        
        require(_amount <= 10, "You are trying to mint too many");
        require(totalMintSupply + _amount <= totalLimit, "You can not mint more than the limit");

        for(uint8 i =0; i< _amount; i++){
            totalMintSupply += 1;
            _mint(_msgSender(), totalMintSupply);
            raptorStats[totalMintSupply] = Stats(1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,false);
            _approve(gameAddress, totalMintSupply);
            emit Mint(_msgSender(), totalMintSupply);
            if(totalMintSupply == totalLimit) {
                emit SoldOut(soldOutMessage);
                address winner = chooseWinner();
                emit PorscheWinner(winner);
            }
        }
    }

    function walletOfOwner(address _wallet) public view override returns(uint16[] memory ids){
        uint16 ownerTokenCount = uint16(balanceOf(_wallet));
        ids = new uint16[](ownerTokenCount);
        for(uint16 i = 0; i< ownerTokenCount; i++){
            ids[i] = uint16(tokenOfOwnerByIndex(_wallet, i));
        }
    }

    function getStats(uint16 _id) public view override returns(Stats memory stats){
        require(_exists(_id), "This token does not exist");
        stats = raptorStats[_id];
    }

    function updateStats(Stats memory _stats, uint16 _id) external override onlyGameAddress returns(bool){
        require(_exists(_id), "This token does not exist");
        raptorStats[_id] = _stats;
        emit StatsUpdated(_id, _stats);
        return true;
    }

    function reward() internal {
        for(uint8 i = 0; i < rewardedAddresses.length; i++){
            for (uint8 j = 0; j < rewardedAmounts[i]; j++){
                totalMintSupply +=1;
                _mint(rewardedAddresses[i], totalMintSupply);
                _approve(gameAddress, totalMintSupply);
                raptorStats[totalMintSupply] = Stats(1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,true);
            }
        }
    }

}