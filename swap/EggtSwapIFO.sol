// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "../lib/Context.sol";
import "../lib/Ownable.sol";
import "../lib/SafeMath.sol";
import "../lib/IBEP20.sol";

contract EggtSwapIFO is Ownable {
    using SafeMath for uint256;

    IBEP20 public token;
    uint256 public startBlock;
    uint256 public endBlock;
    address public adminAddress;

    uint256 public miniETH = 10 ether;
    uint256 public maxEth = 10000 ether;

    uint256 public totalIFOBnb = 250000 ether;
    uint256 public totalIFOToken = 5000000 * 10**18;
    uint256 public perETHToken;
    uint256 public totalPoolEth = 0;
    uint256 public hasSellToken = 0;

    mapping (address => UserInfo) public userInfo;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    struct UserInfo {
        uint256 amount;
        bool inBlackList;
        uint256 token;
    }

    constructor(IBEP20 _token, uint256 _startBlock, uint256 _endBlock) public {
        token = _token;
        startBlock = _startBlock;
        endBlock = _endBlock;
        adminAddress = msg.sender;
        perETHToken = totalIFOToken.div(totalIFOBnb);
    }

    function deposit() public payable {
        require(block.number >= startBlock, "not the start block");
        require(block.number <= endBlock, "has end block");

        uint256 msgValue = msg.value;
        require(msgValue >= miniETH, "mini 10 ether");
        require(userInfo[msg.sender].amount.add(msgValue) <= maxEth, "max 10000 ether");

        require(!userInfo[msg.sender].inBlackList, "you are the black user");

        uint256 willGetToken = msgValue.mul(perETHToken);
        hasSellToken = hasSellToken.add(willGetToken);
        require(hasSellToken <= totalIFOToken, "not full token");

        totalPoolEth = totalPoolEth.add(msgValue);
        userInfo[msg.sender].amount = userInfo[msg.sender].amount.add(msgValue);

        userInfo[msg.sender].token = userInfo[msg.sender].token.add(willGetToken);
        address(uint160(adminAddress)).transfer(msgValue);
        emit Deposit(msg.sender, msgValue);
    }

    function withdraw() public {
        require(block.number >= endBlock, "not the end block");

        UserInfo memory user = userInfo[msg.sender];
        require(!user.inBlackList, "you are the black user");

        require(user.token > 0, "has not token withdraw");

        token.transfer(msg.sender, user.token);

        userInfo[msg.sender].token = 0;

        emit Withdraw(msg.sender, user.token);
    }

    function setTotalIfoToken(uint256 _num) public onlyOwner{
        totalIFOToken = _num;
        perETHToken = totalIFOToken.div(totalIFOBnb);
    }

    modifier onlyAdmin() {
        require(msg.sender == adminAddress, "admin: wut?");
        _;
    }

    function withdrawToken(address _holder, uint256 _num) public onlyOwner {
        uint256 txAmount;
        if(_num == 0){
            txAmount = token.balanceOf(address(this));
        }
        require(txAmount > 0, "balance not enough");
        token.transfer(_holder, txAmount);
    }

    // Update admin address by the previous dev.
    function setAdmin(address _adminAddress) public onlyOwner {
        adminAddress = _adminAddress;
    }

    function setBlock(uint256 sBlock, uint256 eBlock) public onlyOwner{
        startBlock = sBlock;
        endBlock = eBlock;
    }

    function currentBlock() public view returns(uint256){
        return block.number;
    }

    function setBlackList(address _blacklistAddress) public onlyAdmin {
        userInfo[_blacklistAddress].inBlackList = true;
    }

    function removeBlackList(address _blacklistAddress) public onlyAdmin {
        userInfo[_blacklistAddress].inBlackList = false;
    }
}