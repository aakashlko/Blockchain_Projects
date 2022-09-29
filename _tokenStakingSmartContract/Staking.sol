//SPDX-License-Identifier: GPL-3.0
 
pragma solidity >=0.5.0 <0.9.0;

import "./TokenA.sol";
import "./TokenB.sol";
 
contract Staking{

    TokenA public stakingToken;
    TokenB public rewardToken;

    uint public totalStakers;

    address public owner;

    struct stake{
        uint _amount;
        uint _startTS;
        uint _endTS;
        uint _rewardRate;
        uint _claimed;
    }

    event Staked(address indexed from, uint256 amount);
    event Claimed(address indexed from, uint256 amount);

    mapping(address => stake) public stakeInfo;
    mapping(address => bool) public addressStaked;

    constructor(address _stakingToken, address _rewardToken) {
        owner = msg.sender;
        stakingToken = TokenA(_stakingToken);
        rewardToken = TokenB(_rewardToken);
    }

    modifier notOwner(){
        require(msg.sender != owner);
        _;
    }
    
    modifier onlyOwner(){
        require(msg.sender == owner, "Admin Rights Required");
        _;
    }

    function getRewards() external notOwner returns (bool){
        require(addressStaked[msg.sender] == true, "You have not participated");
        require(stakeInfo[msg.sender]._endTS < block.timestamp, "Stake Time is not over yet");
        require(stakeInfo[msg.sender]._claimed == 0, "Already claimed");

        uint256 stakeAmount = stakeInfo[msg.sender]._amount;
        uint256 rewardAmount = stakeAmount * stakeInfo[msg.sender]._rewardRate / 100;
        stakeInfo[msg.sender]._claimed == rewardAmount;
        rewardToken.transfer(msg.sender, rewardAmount);

        emit Claimed(msg.sender, rewardAmount);

        return true;
    }

    function stakeTokens(uint _stakingAmount, uint duration) external payable notOwner{
        require(_stakingAmount > 0, "Invalid Amount");
        require(addressStaked[msg.sender] != true, "You have already Staked");
        require(stakingToken.balanceOf(msg.sender) >= _stakingAmount, "Insufficient Balance");
        require(duration >=1 && duration <=45, "Valid staking duration is 1 to 45 days");

        stakingToken.transferFrom(payable(msg.sender), address(this), _stakingAmount);
        totalStakers++;

        addressStaked[msg.sender] = true;

        uint rr;
        if(duration >= 1 && duration <=15){
            rr = 10;
        }else if(duration >15 && duration <= 30){
            rr = 15;
        }
        else{
            rr = 25;
        }

        stakeInfo[msg.sender] = stake({
            _amount: _stakingAmount,
            _startTS: block.timestamp,
            _endTS: block.timestamp + duration * 24 * 60 * 60,
            _rewardRate: rr,
            _claimed: 0
        });

        emit Staked(msg.sender, _stakingAmount);
    }

    function withdrawStake() public notOwner returns (bool){
       require(stakeInfo[msg.sender]._endTS < block.timestamp, "Tokens are locked");
       require(addressStaked[msg.sender] == true, "First stake some tokens.");
       stakingToken.transfer(msg.sender,stakeInfo[msg.sender]._amount);
       stakeInfo[msg.sender]._amount = 0;
       addressStaked[msg.sender] = false;
       totalStakers--; 
       return true; 
    }
}