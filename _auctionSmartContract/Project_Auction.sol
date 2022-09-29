//SPDX-License-Identifier: GPL-3.0
 
pragma solidity >=0.5.0 <0.9.0;


contract auctionCreater{
    Auction[] public auctions;

    function createAuction() public{
        Auction newAuction = new Auction(payable(msg.sender));
        auctions.push(newAuction);
    }
}
 
contract Auction{
    address payable public owner;
    uint public startBlock;
    uint public endBlock;
    string public ipfsHash;

    address payable[] public bidderList;

    address payable public winningBidder;
    uint public soldAmount;

    enum State {Started, Running, Ended, Canceled}
    State public auctionState;

    address payable public bidder;
    mapping(address => uint) public biddingAmount;

    //the owner can finalize the auction and get the highestBindingBid only once
    bool public ownerFinalized = false;

    constructor(address payable eoa){
        owner = eoa;
        auctionState = State.Running;
        
        startBlock = block.number;
        endBlock = startBlock + 100;
      
        ipfsHash = "";
    }

    //declaring function modifiers
    modifier notOwner(){
        require(msg.sender != owner);
        _;
    }
    
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }
    
    modifier afterStart(){
        require(block.number >= startBlock);
        _;
    }
    
    modifier beforeEnd(){
        require(block.number <= endBlock);
        _;
    }


    // only the owner can cancel the Auction before the Auction has ended
    function cancelAuction() public beforeEnd onlyOwner{
        auctionState = State.Canceled;
    }

    //the main function call to plcae a bid
    function placeBid() public payable notOwner afterStart beforeEnd {
        require(auctionState == State.Running);
        bidderList.push(payable(msg.sender));
        //if a bidder want to increase current bid the new value will be added to his previous bid
        biddingAmount[msg.sender] += msg.value; 
    }

    //only owner can call this function to select a winner of his/her choice
    function selectWinner(address payable winnerAddress) public onlyOwner afterStart beforeEnd {
        winningBidder = winnerAddress;
        soldAmount = biddingAmount[winningBidder];
        auctionState =  State.Ended;
    }

    function finalizeAuction() public{
       // the auction has been Canceled or Ended
       require(auctionState != State.Running || block.number > endBlock); 
       
       // only a bidder can finalize the auction
       require(biddingAmount[msg.sender] > 0);
       
       // the recipient will get the value
       address payable recipient;
       uint value;
       
       if(auctionState == State.Canceled){ // auction canceled, not ended
           recipient = payable(msg.sender);
           value = biddingAmount[msg.sender];
       }else{// auction ended, not canceled
           if(msg.sender == owner && ownerFinalized == false){ //the owner finalizes the auction
               recipient = owner;
               value = soldAmount;
               
               //the owner can finalize the auction and get the highestBindingBid only once
               ownerFinalized = true; 
           }else{// another user (not the owner) finalizes the auction
               if (msg.sender == winningBidder){
                   recipient = winningBidder;
                   value = 0;
               }else{ //this is neither the owner nor the highest bidder (it's a regular bidder)
                   recipient = payable(msg.sender);
                   value = biddingAmount[msg.sender];
               }
           }
       }
       
       // resetting the bids of the recipient to avoid multiple transfers to the same recipient
       biddingAmount[recipient] = 0;
       
       //sends value to the recipient
       recipient.transfer(value);
    } 
}
