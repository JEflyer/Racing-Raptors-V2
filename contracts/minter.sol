//SPDF-License-Identifier: MIT
pragma solidity ^0.8.7;

//using library to reduce the amount of gas used in function calls
import "./libraries/minterLib.sol";

//struct used in multiple contracts
import "./structs/stats.sol";

//oracle import
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

//this allows us to use functions like walletOfOwner which is a great tool 
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract MinterV3 is ERC721Enumerable, VRFConsumerBase{

    //winner declared upon full mint completion
    event PorscheWinner(address winner);

    //stored here to make sure library event is recorded in explorer correctly
    event PriceIncrease(uint newPrice);

    //wallet used to control the contract
    address private admin;
    
    //bool used to keep track of if sale is active or not
    bool private active;

    //metadata URI vars
    string private baseURI = "https://gateway.pinata.cloud/";
    string private ciD = "Some CID/";
    string private extension = ".JSON";
    string private notRevealed = "NotRevealed Hash";

    //oracle vars
    bytes32 private lastRequestId;
    bytes32 private keyHash;
    uint256 private fee;

    //used to keep track of each tokens individual stats
    mapping(uint16 => Stats) private raptorStats;

    //instantiates price to 2 matic
    uint256 private price = 2 * 10**18;

    //current minted amount
    uint16 private totalMintSupply = 0;
    
    //max amount allowed to be minted
    uint16 private totalLimit = 10000;

    //keeps track if NFT images are revealed or not
    bool private revealed;

    //keeps track of the current game address
    address private gameAddress;

    //keeps track of the contract that controls if a raptors cooldown can be reset
    address private cooldownContract;

    //commented out for testing
    //V1 holders rewarded with a V2 raptor
    // address[] rewardedAddresses = [
    //     //holders of racing raptors v1 NFTs 

    // ];

    address[] private rewardedAddresses;

    //currently filled with false values
    //V1 holder amounts
    uint8[] private rewardedAmounts = [
        1,1,1,1,1,1,1,1
    ];

    //wallets that will funds will be automatically split between
    address[] private paymentsTo;
    uint16[] private shares;

    //checks if the raptor is a raptor that was rewarded to a V1 holder
    mapping(uint16 => bool) private foundingRaptor;

    constructor(
        address[] memory _rewardedAddresses,
        address[] memory _paymentsTo,
        uint16[] memory _shares,
        address _vrfCoordinator,
        address _linkToken,
        bytes32 _keyHash,
        uint256 _oracleFee
        )ERC721("Racing Raptors V2", "RR") VRFConsumerBase( _vrfCoordinator, _linkToken){
            require(_paymentsTo.length == _shares.length);
            keyHash = _keyHash;
            fee = _oracleFee;
            rewardedAddresses = _rewardedAddresses;
            active = true;
            admin = _msgSender();
            paymentsTo = _paymentsTo;
            reward();
    }

    //removes approvale for old game contract
    //sets new game contract
    //approves control of all NFTs for the new game contract - this is used for death race burning
    //only accessible by admin
    function updateGameAddress(address _gameAddress) public onlyAdmin {
        setApprovalForAll(gameAddress, false);
        gameAddress = _gameAddress;
        setApprovalForAll(gameAddress, true);
    }

    //returns struct of stats fora  given raptor
    function getStats(uint16 raptor) public returns(Stats) {
        return raptorStats[raptor];
    }

    //updates the contract address that controls the cooldown reset
    //only accessible by admin
    function updateCooldownAddress(address _coolDown) public onlyAdmin {
        cooldownContract = _coolDown;
    }

    //updates a payment wallet at a certain index
    //only accessible by admin
    function updatePaymentTo(address _paymentTo, uint8 index) public onlyAdmin {
        paymentsTo[index] = _paymentTo;
    }

    //calculates the wei price for an amount of raptors since the mint price doubles every 1k mints
    function getPrice(uint8 _amount) public view  returns(uint256){
        return minterLib.getPrice(_amount, price, totalMintSupply);
    }

    //sets the IPFS hash for the API link to the image
    //only accessible by admin
    function setCID(string memory _ciD) public onlyAdmin {
        ciD = _ciD;
    }
    
    //sets the IPFS hash for the API link to the unrevealed NFT image
    //only accessible by admin
    function setNotRevealed(string memory _not) public onlyAdmin {
        notRevealed = _not;
    } 

    //sets the start of the API link- either IPFS or pinata
    //only accessible by admin
    function setBase(string memory _base) public onlyAdmin {
        baseURI = _base;
    }

    modifier onlyAdmin{
        require(_msgSender() == admin);
        _;
    }

    modifier onlyGameAddress{
        require(_msgSender() == gameAddress);
        _;
    }

    //unreveals all NFT image API links
    //only accessible by admin
    function reveal() public onlyAdmin {
        revealed = true;
    }

    //turns the sale on & off
    //only accessible by admin
    //this is kept in incase of any unforseen security problems - not expected to happen but it doesn't hurt
    function flipSaleState() public onlyAdmin {
        active = !active;
    }

    function updateSplit(address[] memory _paymentsTo, uint16[] memory _shares) public onlyAdmin {
        require(_paymentsTo.length == _shares.length);
        paymentsTo = _paymentsTo;
        shares = _shares;
    }

    //sets the admin wallet that controls the contract
    //only accessible by admin
    function setAdmin(address _admin) public onlyAdmin{
        admin = _admin;
    }

    //checks if token exists
    //if unrevealed returns unrevealed NFT API link
    //otherwise converts tokenId to string & concatenates all parts together
    function tokenURI(uint16 _tokenId) public view virtual returns(string memory uri){
        require(_exists(_tokenId));

        if(!revealed) {uri = string(abi.encodePacked(baseURI, notRevealed));}
        else{uri = string(abi.encodePacked(baseURI, ciD, string(abi.encodePacked(_tokenId)), extension));}

    }

    //automatically splits funds between designated wallets
    function splitFunds(uint256 fundsToSplit) public payable {
        uint16 totalShares = minterLib.totalShares(shares);

        for(uint i=0; i<shares.length; i++){
            require(payable(paymentsTo[i]).transfer(fundsToSplit * shares[i]/totalShares));
        }
    }

    //passed the msg.value to the above function
    receive() external payable {
        splitFunds(msg.value);
    }

    //mints upto 10 NFTs
    //updates the price if the amount + current minted amount passes over a thousand 
    //sets stats for new NFT
    //approves usage for game contract
    //if totallimit is reached random number requested in order to choose the Porsche winner
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

    //returns an array of tokens held by a wallet
    function walletOfOwner(address _wallet) public view  returns(uint16[] memory ids){
        uint16 ownerTokenCount = uint16(balanceOf(_wallet));
        ids = new uint16[](ownerTokenCount);
        for(uint16 i = 0; i< ownerTokenCount; i++){
            ids[i] = uint16(tokenOfOwnerByIndex(_wallet, i));
        }
    }

    //checks if a tokenID is a rewarded NFT for V1 holders
    //Founding raptors have only 6 hour cooldown instead of the normal 12 hour cooldown
    function isFoundingRaptor(uint16 raptor) external view returns(bool){
        return foundingRaptor[raptor];
    }

    //returns the cooldown period for a given tokenID
    function getCoolDown(uint16 _raptor) external view  returns(uint32){
        return raptorStats[_raptor].cooldownTime;
    }

    //returns the speed stat for a given tokenID
    function getSpeed(uint16 _raptor) external view  returns(uint16){
        return raptorStats[_raptor].speed;
    }

    //returns the strength stat for a given tokenID
    function getStrength(uint16 _raptor) external view  returns(uint16){
        return raptorStats[_raptor].strength;
    }

    //upgrades the speed by an amount
    //only callabable by the game contract
    function upgradeSpeed(uint16 _raptor, uint8 _amount) external onlyGameAddress  returns(bool){
        raptorStats[_raptor].speed += _amount;
        return true;
    }

    //upgrades the strength by an amount
    //only callabable by the game contract
    function upgradeStrength(uint16 _raptor, uint8 _amount) external onlyGameAddress  returns(bool){
        raptorStats[_raptor].strength += _amount;
        return true;
    }

    //increases the total fights won for a tokenID
    //only callabable by the game contract
    function upgradeFightsWon(uint16 _raptor) external onlyGameAddress  returns(bool){
        raptorStats[_raptor].fightsWon += 1;
        return true;
    }

    //increases the total quick play wins for a tokenID
    //only callabable by the game contract
    function upgradeQPWins(uint16 _raptor) external onlyGameAddress  returns(bool){
        raptorStats[_raptor].quickPlayRacesWon += 1;
        return true;
    }

    //increases the total comp wins for a tokenID
    //only callabable by the game contract
    function upgradeCompWins(uint16 _raptor) external onlyGameAddress  returns(bool){
        raptorStats[_raptor].compRacesWon += 1;
        return true;
    }

    //increases the total death race wins for a tokenID
    //only callabable by the game contract
    function upgradeDRWins(uint16 _raptor) external onlyGameAddress  returns(bool){
        raptorStats[_raptor].deathRacesWon += 1;
        return true;
    }

    //increases the total top3 finishes for a tokenID
    //only callabable by the game contract
    function upgradeTop3Finishes(uint16 _raptor) external onlyGameAddress  returns(bool){
        raptorStats[_raptor].totalRacesTop3Finish += 1;
        return true;
    }

    //increases cooldown time for a tokenID that lost a fight
    //only callabable by the game contract
    function increaseCooldownTime(uint16 _raptor, uint32 newTime) external onlyGameAddress  returns(bool){
        raptorStats[_raptor].cooldownTime = uint32(block.timestamp) + newTime;
        return true;
    }

    //resets cooldown period for a tokenID
    //only callabable by the cooldown contract
    //this will cost x amount of raptor coin
    function resetCooldown(uint16 _raptor) external returns (bool) {
        require(msg.sender == cooldownContract);
        raptorStats[_raptor].cooldownTime = uint32(block.timestamp);
        return true;
    }

    //reward function for V1 holders
    //approves the tokenIDs for usage by game contract
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

    //finds the owner of a tokenID between 1-10000
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        emit PorscheWinner(ownerOf((randomness %10000)+1));
    }
    //Oracle Functions

    //allows the burning of tokenIDs
    //unlikely to be used by a user directly
    //if a tokenID loses a fight in death race it is burned
    function burn(uint256 tokenId) public virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId));
        _burn(tokenId);
    }

}