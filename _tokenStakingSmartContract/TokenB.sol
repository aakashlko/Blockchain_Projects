//SPDX-License-Identifier: GPL-3.0
 
pragma solidity >=0.5.0 <0.9.0;

import "./TokenA.sol";

contract TokenB is IERC20 {

    string public constant name = "TokenB";
    string public constant symbol = "_B";
    uint8 public constant decimals = 18;

    using SafeMath for uint256;

    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;

    uint256 totalSupply_ = 10 ether;


   constructor() {
    balances[msg.sender] = totalSupply_;
    }

    function totalSupply() public override view returns (uint256) {
    return totalSupply_;
    }

    function balanceOf(address tokenOwner) public override view returns (uint256) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender]-numTokens;
        balances[receiver] = balances[receiver]+numTokens;
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint256 numTokens) public override returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public override view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);

        balances[owner] = balances[owner]-numTokens;
        allowed[owner][msg.sender] = allowed[owner][msg.sender]-numTokens;
        balances[buyer] = balances[buyer]+numTokens;
        emit Transfer(owner, buyer, numTokens);
        return true;
    }

    function mintNewTokens(uint increasedAmount) public returns(bool){
    require(increasedAmount > 0);
    balances[msg.sender] = balances[msg.sender].add(increasedAmount);
    totalSupply_ = totalSupply_.add(increasedAmount);
    emit Transfer(address(0), msg.sender, increasedAmount);
    return true;
}
    function decreaseSupply (uint burnAmount) public returns(bool){
    require(burnAmount <= balances[msg.sender]);  
    require(burnAmount > 0);
    balances[msg.sender] = balances[msg.sender].sub(burnAmount);
    totalSupply_ = totalSupply_.sub(burnAmount);
    emit Transfer(msg.sender,address(0), burnAmount);
    return true;
}
}