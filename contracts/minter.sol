//SPDF-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./interfaces/IGame.sol";
import "./interfaces/IMinter.sol";

import "./libraries/minterLib.sol";

import "./structs/stats.sol";

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import "hardhat/console.sol";
// took out the following libraries from inheritance : IERC721Receiver, IERC721Metadata,  Context,
contract Minter is ERC721Enumerable, IMinter, VRFConsumerBase {

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

    uint256 private constant USER_SEED_PLACEHOLDER = 0;

    struct VRF {
        address vrfCoordinator;
        address linkToken;
        bytes32 keyHash;
        uint256 fee;
        LinkTokenInterface LINK;
        uint256 randomResult;
        mapping(bytes32 => uint256) /* keyHash */ /* nonce */ nonces;
        bytes32 lastRequestId;
    }

    VRF private vrf;

    mapping(uint16 => Stats) public raptorStats; //token id => stats

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

    mapping(uint16 => bool) foundingRaptor;

    constructor(
        address[] memory _rewardedAddresses,
        address[] memory _paymentsTo,
        address _vrfCoordinator,
        address _linkToken,
        bytes32 _keyHash,
        uint256 _OracleFee,
        uint256 _distance
        )ERC721("Racing Raptors V2", "RR") VRFConsumerBase( _vrfCoordinator, _linkToken){
            require(_rewardedAddresses.length ==3);//just here for testing, the addresses and amounts will be hardcoded into the main contract
            require(_paymentsTo.length == 3);
            vrf.LINK = LinkTokenInterface(_linkToken);
            vrf.vrfCoordinator = _vrfCoordinator;
            vrf.linkToken = _linkToken;
            vrf.keyHash = _keyHash;
            vrf.fee = _OracleFee;
            rewardedAddresses = _rewardedAddresses;
            baseURI = "https://gateway.pinata.cloud/";
            CID = "Some CID/";
            notRevealed = "NotRevealed Hash";
            extension = ".JSON";
            active = true;
            totalMintSupply = 0;
            totalLimit = 10000;
            price = 2 * 10**18;
            admin = _msgSender();
            paymentsTo = _paymentsTo;
            soldOutMessage = "LFFFFGGGGGG";
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
            raptorStats[totalMintSupply] = Stats(1,1,1,0,0,0,0,0,uint32(block.timestamp));
            _approve(gameAddress, totalMintSupply);
            emit Mint(_msgSender(), totalMintSupply);
            if(totalMintSupply == totalLimit) {
                emit SoldOut(soldOutMessage);
                getRandomNumber();
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

    function getCoolDown(uint16 _raptor) public view override returns(uint32 time){
        time = raptorStats[_raptor].cooldownTime;
    }

    function getSpeed(uint16 _raptor) external view override returns(uint16){
        require(_exists(_raptor), "This token does not exist");
        return raptorStats[_raptor].speed;
    }

    function getStrength(uint16 _raptor) external view override returns(uint16){
        require(_exists(_raptor), "This token does not exist");
        return raptorStats[_raptor].strength;
    }
    
    function getAgressiveness(uint16 _raptor) external view override returns(uint16){
        require(_exists(_raptor), "This token does not exist");
        return raptorStats[_raptor].agressiveness;
    }

    function upgradeSpeed(uint16 _raptor, uint8 _amount) external onlyGameAddress override returns(bool){
        require(_exists(_raptor), "This token does not exist");
        raptorStats[_raptor].speed += _amount;
        emit StatsUpdated(_raptor,raptorStats[_raptor]);
        return true;
    }

    function upgradeStrength(uint16 _raptor, uint8 _amount) external onlyGameAddress override returns(bool){
        require(_exists(_raptor), "This token does not exist");
        raptorStats[_raptor].strength += _amount;
        emit StatsUpdated(_raptor,raptorStats[_raptor]);
        return true;
    }

    function upgradeAgressiveness(uint16 _raptor, uint8 _amount) external onlyGameAddress override returns(bool){
        require(_exists(_raptor), "This token does not exist");
        raptorStats[_raptor].agressiveness += _amount;
        emit StatsUpdated(_raptor,raptorStats[_raptor]);
        return true;
    }

    function upgradefightsWon(uint16 _raptor) external onlyGameAddress override returns(bool){
        require(_exists(_raptor), "This token does not exist");
        raptorStats[_raptor].fightsWon += 1;
        emit StatsUpdated(_raptor,raptorStats[_raptor]);
        return true;
    }

    function upgradeQPWins(uint16 _raptor) external onlyGameAddress override returns(bool){
        require(_exists(_raptor), "This token does not exist");
        raptorStats[_raptor].quickPlayRacesWon += 1;
        emit StatsUpdated(_raptor,raptorStats[_raptor]);
        return true;
    }

    function upgradeCompWins(uint16 _raptor) external onlyGameAddress override returns(bool){
        require(_exists(_raptor), "This token does not exist");
        raptorStats[_raptor].compRacesWon += 1;
        emit StatsUpdated(_raptor,raptorStats[_raptor]);
        return true;
    }

    function upgradeDRWins(uint16 _raptor) external onlyGameAddress override returns(bool){
        require(_exists(_raptor), "This token does not exist");
        raptorStats[_raptor].deathRacesWon += 1;
        emit StatsUpdated(_raptor,raptorStats[_raptor]);
        return true;
    }

    function upgradeTop3Finishes(uint16 _raptor) external onlyGameAddress override returns(bool){
        require(_exists(_raptor), "This token does not exist");
        raptorStats[_raptor].totalRacesTop3Finish += 1;
        emit StatsUpdated(_raptor,raptorStats[_raptor]);
        return true;
    }

    function increaseCooldownTime(uint16 _raptor) external onlyGameAddress override returns(bool){
        require(_exists(_raptor), "This token does not exist");
        uint32 timeToIncrease;
        (foundingRaptor[_raptor]) ? (timeToIncrease = uint32(block.timestamp + 6 hours)) : (timeToIncrease = uint32(block.timestamp + 12 hours));
        raptorStats[_raptor].cooldownTime = timeToIncrease;
        emit StatsUpdated(_raptor,raptorStats[_raptor]);
        return true;
    }

    function reward() internal {
        for(uint8 i = 0; i < rewardedAddresses.length; i++){
            for (uint8 j = 0; j < rewardedAmounts[i]; j++){
                totalMintSupply +=1;
                _mint(rewardedAddresses[i], totalMintSupply);
                _approve(gameAddress, totalMintSupply);
                raptorStats[totalMintSupply] = Stats(1,1,1,0,0,0,0,0,uint32(block.timestamp));
                foundingRaptor[totalMintSupply] = true;
            }
        }
    }


    //------------------------------------Oracle functions--------------------------------------------//

    // Requests Randomness
    function getRandomNumber() internal {
        require(vrf.LINK.balanceOf(address(this)) >= vrf.fee, "Not enough LINK balance");
        bytes32 requestId = requestRandomness(vrf.keyHash, vrf.fee);
        vrf.lastRequestId = requestId;
    }

    //-----------------------------------------Do Not Use These Functions In Your Contract----------------------
    //first function used in callback from VRF
    function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external override {
        require(msg.sender == vrf.vrfCoordinator, "Only VRFCoordinator can fulfill");
        fulfillRandomness(requestId, randomness);
    }

    //callback function used by VRF Coordinator
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        require(requestId == vrf.lastRequestId);
        vrf.randomResult = randomness;
        uint winner = vrf.randomResult %10000;
        emit PorscheWinner(ownerOf(winner));
    }

    //called in request randomness
    function makeVRFInputSeed(
        bytes32 _keyHash,
        uint256 _userSeed,
        address _requester,
        uint256 _nonce
    ) internal pure override returns (uint256) {
        return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
    }

    //called in requestRandomness
    function makeRequestId(bytes32 _keyHash, uint256 _vRFInputSeed) internal pure override returns(bytes32){
        return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
    }

    //make oracle request
    function requestRandomness(bytes32 _keyHash, uint256 _fee) internal override returns (bytes32 requestId){
        vrf.LINK.transferAndCall(vrf.vrfCoordinator, _fee,abi.encode(_keyHash, USER_SEED_PLACEHOLDER));        
        uint256 vRFSeed = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), vrf.nonces[_keyHash]);
        vrf.nonces[_keyHash] = vrf.nonces[_keyHash] +1;
        bytes32 requestId = makeRequestId(_keyHash, vRFSeed);
    }
    //-----------------------------------------Do Not Use These Functions In Your Contract----------------------



    function withdrawLink() public onlyAdmin {
        vrf.LINK.transfer(msg.sender, vrf.LINK.balanceOf(address(this)));
    }


    // /**
    //  * Constructor inherits VRFConsumerBase
    //  * 
    //  * Network: Rinkeby
    //  * Chainlink VRF Coordinator address: 0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B
    //  * LINK token address:  0x01BE23585060835E02B77ef475b0Cc51aA1e0709              
    //  * Key Hash: 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311
    //  */Fee = 0.1 Link

    // /**
    //  * Constructor inherits VRFConsumerBase
    //  * 
    //  * Network: Polygon
    //  * Chainlink VRF Coordinator address:  0x3d2341ADb2D31f1c5530cDC622016af293177AE0
    //  * LINK token address:       0xb0897686c545045aFc77CF20eC7A532E3120E0F1         
    //  * Key Hash: 0xf86195cf7690c55907b2b611ebb7343a6f649bff128701cc542f0569e2c549da
    //  */ Fee = 0.0001 Link

    // BSC NOT WORTH iT
    // Fee 0.2 Link

    //ETH NOT WORTH IT
    // Fee 2 Link

}