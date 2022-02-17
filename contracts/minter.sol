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
    
    bool private active;
    string private baseURI;
    string private CID;
    string private extension = ".JSON";
    string private notRevealed = "";

    string private soldOutMessage;

    mapping(uint16 => Stats) private raptorStats; //token id => stats

    uint256 private price;
    uint16 private totalMintSupply;
    uint16 private totalLimit;

    bool private revealed;

    address payable private paymentSplitter;
    address private gameAddress;

    //commented out for testing
    // address[] rewardedAddresses = [
    //     //holders of racing raptors v1 NFTs 

    // ];

    address[] rewardedAddresses;

    uint8[] rewardedAmounts = [
        //amounts held for each holder
        1,2,3
    ];

    constructor(
        address _paymentSplitter,
        string memory _baseURI,
        string memory _CID,
        string memory _notRevealed,
        string memory _extension,
        uint16 _totalLimit,
        string memory _soldOutMessage,
        address[] memory _rewardedAddresses
        )ERC721("Racing Raptors V2", "RR"){
            require(_rewardedAddresses.length ==3);
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
            paymentSplitter = payable(_paymentSplitter);
            soldOutMessage = _soldOutMessage;
            reward();
    }

    function updateGameAddress(address _gameAddress) public onlyAdmin {
        gameAddress = _gameAddress;
        emit NewGameContract(_gameAddress);
    }

    function updateSplitter(address _paymentSplitter) public onlyAdmin {
        paymentSplitter = payable(_paymentSplitter);
    }

    function getPrice(uint8 _amount) public view override returns(uint256 givenPrice){
        require(_amount <= 10, "Too high of an amount");
        if(minterLib.crossesThreshold(_amount,totalMintSupply) == true){
            (uint8 amountBefore, uint8 amountAfter) = minterLib.getAmounts(_amount,totalMintSupply);
            givenPrice = (price*amountBefore) + (price * 2 * amountAfter);
        } else {
            givenPrice = price * _amount;
        }
    }

    function getTotalMinted() public view override returns (uint16 total){
        total = totalMintSupply;
    }

    modifier onlyAdmin{
        require(_msgSender() == admin);
        _;
    }

    modifier onlyGameAddress{
        require(_msgSender() == gameAddress, "Only the game contract can call this function");
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


    function mint(uint8 _amount) public payable {
        require(active, "This function is not available right now");

        if(_msgSender() != admin){
            require(msg.value == getPrice(_amount),"Not enough funds sent");
            if(minterLib.crossesThreshold(_amount)){ 
                price = minterLib.updatePrice(price);
                emit PriceIncrease(price);
            } 
        }

        require(_amount <= 10, "You are trying to mint too many");
        require(totalMintSupply + _amount <= totalLimit, "You can not mint more than the limit");

        (bool success,) = paymentSplitter.call{value: msg.value}("");
        require(success, "Sending funds to payment splitter failed");

        for(uint8 i =0; i< _amount; i++){
            totalSupply += 1;
            _mint(_msgSender(), totalMintSupply);
            raptorStats[totalMintSupply] = Stats(1,1,1,0,0,0,0,0,0,false);
            _approve(gameAddress, totalMintSupply);
            emit Mint(_msgSender, totalMintSupply);
            if(totalSupply == totalLimit) {
                emit SoldOut(soldOutMessage);
                address winner = chooseWinner();
                emit PorscheWinner(winner);
            }
        }
    }

    function walletOfOwner(address _wallet) public view override returns(uint16[] memory ids){
        uint16 ownerTokenCount = balanceOf(_wallet);
        ids = new uint16[](ownerTokenCount);
        for(uint16 i = 0; i< ownerTokenCount; i++){
            ids[i] = tokenOfOwnerByIndex(_wallet, i);
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
        for(uint8 i = 0; i < rewardedAddresses.length(); i++){
            for (uint8 j = 0; j < rewardedAmounts[i]; j++){
                totalSupply +=1;
                _mint(rewardedAddresses, totalSupply);
                _approve(gameAddress, totalSupply);
                raptorStats[totalSupply] = Stats(1,1,1,0,0,0,0,0,0,true);
            }
        }
    }

}