//SPDF-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./interfaces/IMinter.sol";

import "./libraries/minterLib.sol";

import "./structs/stats.sol";

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract MinterV3 is ERC721Enumerable, VRFConsumerBase{

    event PorscheWinner(address winner);

    address private admin;
    
    bool private active;
    string private baseURI = "https://gateway.pinata.cloud/";
    string private CID = "Some CID/";
    string private extension = ".JSON";
    string private notRevealed = "NotRevealed Hash";

    bytes32 private lastRequestId;
    bytes32 private keyHash;
    uint256 private fee;

    mapping(uint16 => Stats) public raptorStats;

    uint256 private price = 2 * 10**18;
    uint16 private totalMintSupply = 0;
    uint16 private totalLimit = 10000;

    bool private revealed;

    address private gameAddress;
    address private cooldownContract;

    //commented out for testing
    // address[] rewardedAddresses = [
    //     //holders of racing raptors v1 NFTs 

    // ];

    address[] private rewardedAddresses;

    uint8[] private rewardedAmounts = [
        1,1,1,1,1,1,1,1
    ];

    address[] private paymentsTo;

    mapping(uint16 => bool) private foundingRaptor;

    constructor(
        address[] memory _rewardedAddresses,
        address[] memory _paymentsTo,
        address _vrfCoordinator,
        address _linkToken,
        bytes32 _keyHash,
        uint256 _OracleFee
        )ERC721("Racing Raptors V2", "RR") VRFConsumerBase( _vrfCoordinator, _linkToken){
            keyHash = _keyHash;
            fee = _OracleFee;
            rewardedAddresses = _rewardedAddresses;
            active = true;
            admin = _msgSender();
            paymentsTo = _paymentsTo;
            reward();
    }

    function updateGameAddress(address _gameAddress) public onlyAdmin {
        setApprovalForAll(gameAddress, false);
        gameAddress = _gameAddress;
        setApprovalForAll(gameAddress, true);
    }

    function updateCooldownAddress(address _coolDown) public onlyAdmin {
        cooldownContract = _coolDown;
    }

    function updatePaymentTo(address _paymentTo, uint8 index) public onlyAdmin {
        paymentsTo[index] = _paymentTo;
    }

    function getPrice(uint8 _amount) public view  returns(uint256){
        return minterLib.getPrice(_amount, price, totalMintSupply);
    }

    modifier onlyAdmin{
        require(_msgSender() == admin);
        _;
    }

    modifier onlyGameAddress{
        require(_msgSender() == gameAddress);
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
    }

    function tokenURI(uint16 _tokenId) public view virtual returns(string memory uri){
        require(_exists(_tokenId));

        if(!revealed) {uri = string(abi.encodePacked(baseURI, notRevealed));}
        else{uri = string(abi.encodePacked(baseURI, CID, string(abi.encodePacked(_tokenId)), extension));}

    }

    function splitFunds(uint256 fundsToSplit) public payable {
        require(payable(paymentsTo[0]).send(fundsToSplit * 25/100));
        require(payable(paymentsTo[1]).send(fundsToSplit * 50/100));
        require(payable(paymentsTo[2]).send(fundsToSplit * 25/100));
    }

    receive() external payable {
        splitFunds(msg.value);
    }

    function mint(uint8 _amount) public payable {
        require(active);

        if(_msgSender() != admin){
            require(msg.value == getPrice(_amount));
            if(minterLib.crossesThreshold(_amount, totalMintSupply)){ 
                price = minterLib.updatePrice(price);
            } 
            splitFunds(msg.value);
        }

        require(_amount <= 10);
        require(totalMintSupply + _amount <= totalLimit);
        
        for(uint8 i =0; i< _amount; i++){
            totalMintSupply += 1;
            _mint(_msgSender(), totalMintSupply);
            approve(gameAddress, totalMintSupply);
            raptorStats[totalMintSupply] = Stats(1,1,0,0,0,0,0,uint32(block.timestamp));
            if(totalMintSupply == totalLimit) {
                getRandomNumber();
            }
        }
    }

    function walletOfOwner(address _wallet) public view  returns(uint16[] memory ids){
        uint16 ownerTokenCount = uint16(balanceOf(_wallet));
        ids = new uint16[](ownerTokenCount);
        for(uint16 i = 0; i< ownerTokenCount; i++){
            ids[i] = uint16(tokenOfOwnerByIndex(_wallet, i));
        }
    }

    function isFoundingRaptor(uint16 raptor) external view returns(bool){
        return foundingRaptor[raptor];
    }

    function getCoolDown(uint16 _raptor) external view  returns(uint32){
        return raptorStats[_raptor].cooldownTime;
    }

    function getSpeed(uint16 _raptor) external view  returns(uint16){
        return raptorStats[_raptor].speed;
    }

    function getStrength(uint16 _raptor) external view  returns(uint16){
        return raptorStats[_raptor].strength;
    }

    function upgradeSpeed(uint16 _raptor, uint8 _amount) external onlyGameAddress  returns(bool){
        raptorStats[_raptor].speed += _amount;
        return true;
    }

    function upgradeStrength(uint16 _raptor, uint8 _amount) external onlyGameAddress  returns(bool){
        raptorStats[_raptor].strength += _amount;
        return true;
    }

    function upgradeFightsWon(uint16 _raptor) external onlyGameAddress  returns(bool){
        raptorStats[_raptor].fightsWon += 1;
        return true;
    }

    function upgradeQPWins(uint16 _raptor) external onlyGameAddress  returns(bool){
        raptorStats[_raptor].quickPlayRacesWon += 1;
        return true;
    }

    function upgradeCompWins(uint16 _raptor) external onlyGameAddress  returns(bool){
        raptorStats[_raptor].compRacesWon += 1;
        return true;
    }

    function upgradeDRWins(uint16 _raptor) external onlyGameAddress  returns(bool){
        raptorStats[_raptor].deathRacesWon += 1;
        return true;
    }

    function upgradeTop3Finishes(uint16 _raptor) external onlyGameAddress  returns(bool){
        raptorStats[_raptor].totalRacesTop3Finish += 1;
        return true;
    }

    function increaseCooldownTime(uint16 _raptor, uint32 newTime) external onlyGameAddress  returns(bool){
        raptorStats[_raptor].cooldownTime = uint32(block.timestamp) + newTime;
        return true;
    }

    function resetCooldown(uint16 _raptor) external returns (bool) {
        require(msg.sender == cooldownContract);
        raptorStats[_raptor].cooldownTime = uint32(block.timestamp);
        return true;
    }

    function reward() internal {
        for(uint8 i = 0; i < rewardedAddresses.length; i++){
            for (uint8 j = 0; j < rewardedAmounts[i]; j++){
                totalMintSupply +=1;
                _mint(rewardedAddresses[i], totalMintSupply);
                _approve(gameAddress, totalMintSupply);
                raptorStats[totalMintSupply] = Stats(1,1,0,0,0,0,0,uint32(block.timestamp));
                foundingRaptor[totalMintSupply] = true;
            }
        }
    }

    //Oracle functions
    function getRandomNumber() internal {
        require(LINK.balanceOf(address(this)) >= fee);
        requestRandomness(keyHash, fee);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        emit PorscheWinner(ownerOf(randomness %10000));
    }
    //Oracle Functions

    function burn(uint256 tokenId) public virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId));
        _burn(tokenId);
    }

}