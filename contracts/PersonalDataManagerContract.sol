pragma solidity ^0.8.0;

import "hardhat/console.sol";

contract PersonalDataManagerContract
{
    mapping(address => Balance) public balances;
    mapping(address => bool) private verifiers;
    mapping(address => PersonalData) private personalData;
    address[] dataOwners;
    mapping(address => mapping(address => bool)) private personalDataAccess;
    uint256 minimumBalanceForWithdraw;
    uint256 weiPerBalance;

    struct Balance
    {
        uint256 amount;
        bool isActivated;
    }

    struct PersonalData
    {
        address owner;
        bool verified;
        uint256 price;
        string fullName;
        string emailAddresses;
        string phoneNumbers;
        string socialLinks;
    }

    struct FullPersonalData
    {
        Balance balance;
        PersonalData personalData;
    }

    constructor() payable {
        console.log("This is a simple personal data manager. Data owners can add their personal data for free. They get points in exchange for queries for their data");
        minimumBalanceForWithdraw = 20;
        weiPerBalance = 0.00001 ether;
    }

    event PersonalDataAdded(address indexed owner);
    event BalanceChanged(address indexed owner, Balance balance);

    function addPersonalData(uint256 price, string memory fullName, string memory emailAddresses, string memory phoneNumbers, string memory socialLinks)
    public
    {
        // activate default balance
        _activateDefaultInitialBalance(msg.sender);

        // add personal data
        personalData[msg.sender] = PersonalData({
        owner : msg.sender,
        verified : false,
        price : price,
        fullName : fullName,
        emailAddresses : emailAddresses,
        phoneNumbers : phoneNumbers,
        socialLinks : socialLinks
        });
        dataOwners.push(msg.sender);

        // data owners can view their own data
        personalDataAccess[msg.sender][msg.sender] = true;

        // emit event
        console.log("%s has listed their personal data for %s points", msg.sender, price);
        emit PersonalDataAdded(msg.sender);
    }

    function getPersonalDataAccess(address dataOwner)
    public
    {
        console.log('%s is exchanging points for personal data of %s', msg.sender, dataOwner);
        _activateDefaultInitialBalance(msg.sender);
        PersonalData memory data = personalData[dataOwner];

        require(balances[msg.sender].amount >= data.price, 'You have insufficient points to get this data');
        require(data.owner == dataOwner, 'The address has not added any data');

        _creditBalance(dataOwner, data.price);
        _debitBalance(msg.sender, data.price);

        console.log("Credited data owner %s with %s points. New balance is %s points", dataOwner, data.price, balances[dataOwner].amount);
        console.log("Debited query maker %s by %s points. New balance is %s points", msg.sender, data.price, balances[msg.sender].amount);

        personalDataAccess[dataOwner][msg.sender] = true;
    }

    function withdraw10()
    public
    {
        console.log('withdrawing 10 points');
        require(balances[msg.sender].amount >= minimumBalanceForWithdraw, 'Insufficient Balance to withdraw');
        uint256 amountToWithdraw = 10;
        uint256 amountToTransfer = amountToWithdraw * weiPerBalance;
        _debitBalance(msg.sender, amountToWithdraw);

        require(address(this).balance >= amountToTransfer, 'Contract balance too low');
        (bool sent,) = msg.sender.call{value : amountToTransfer}("");
        require(sent, "Failed to withdraw money from contract");
    }

    function deposit()
    public payable
    {
        uint256 amountToCredit = msg.value / weiPerBalance;
        require(amountToCredit > 0, 'Invalid deposit amount');
        console.log('Depositing %s wei in exchange for %s points', msg.value, amountToCredit);
        _creditBalance(msg.sender, amountToCredit);
    }

    function getFullPersonalData(address owner)
    public view
    returns (FullPersonalData memory)
    {
        console.log('%s is requesting for the personal data of %s', msg.sender, owner);
        require(personalDataAccess[owner][msg.sender], 'You do not have access to the requested personal data');
        return FullPersonalData({balance : balances[msg.sender], personalData : personalData[owner]});
    }

    function getDataPrice(address dataOwner)
    public view
    returns (uint256)
    {
        console.log("%s is querying the price of %s's personal data", msg.sender, dataOwner);
        console.log("%s costs %s points", dataOwner, personalData[dataOwner].price);
        require(personalData[dataOwner].owner == dataOwner, 'The address has not added any data');
        return personalData[dataOwner].price;
    }

    function getPointsBalance()
    public view
    returns (uint256)
    {
        console.log("%s is querying their balance", msg.sender);
        console.log("%s has %s points", msg.sender, balances[msg.sender].amount);
        return balances[msg.sender].amount;
    }

    function _activateDefaultInitialBalance(address owner)
    private
    {
        if (!balances[owner].isActivated)
        {
            balances[owner] = Balance({amount : 10, isActivated : true});
            emit BalanceChanged(owner, balances[owner]);
            console.log("Activated default initial balance for %s", owner);
        }
    }

    function _debitBalance(address owner, uint256 debitAmount)
    private
    {
        require(balances[owner].amount >= debitAmount, 'Insufficient Balance');
        balances[owner].amount -= debitAmount;
        emit BalanceChanged(owner, balances[owner]);
    }

    function _creditBalance(address owner, uint256 creditAmount)
    private
    {
        balances[owner].amount += creditAmount;
        emit BalanceChanged(owner, balances[owner]);
    }
}
