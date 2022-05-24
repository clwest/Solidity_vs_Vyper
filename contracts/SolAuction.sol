// PDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

contract SimpleAuction {

    address payable public beneficiary;
    uint public auctionEndTime;

    // Current state of the auctionEndTime
    address public highestBidder;
    uint public highestBid;

    // Allow withdraw of previous bids
    mapping (address => uint) public pendingReturns;


    // Set to true at the end of auctions dissallow any further bids
    // By default set to false
    bool ended;

    // Events that will be emitted on changes
    event HighestBidIncreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);

    // Errors triple slash comments will be shown to the user if an error occurs

    /// The auction has already ended
    error AuctionAlreadyEnded();

    /// There is already a higher bidder increase bid
    error BidNotHighEnough(uint highestBid);

    /// The auction has not yet ended
    error AuctionNotYetEnded();

    /// The function auctionEnd has already been called
    error AuctionEndAlreadyCalled();

    

    // Create a simple auction with "biddingTiem"

    constructor(uint biddingTime, address payable beneficiaryAddress) {
        beneficiary = beneficiaryAddress;
        auctionEndTime = block.timestamp + biddingTime;
        ended = false;
    }

    // Bid on an item by sending the value
    // The value will only be refunded if the auction is not won

    // Takes no arguments
    function bid() external payable {

        // Revert the call if the bidding is over
        if (block.timestamp > auctionEndTime) {
            revert AuctionAlreadyEnded();
        }

        // If the bid is not high enough will we will send the funds back
        
        if (highestBid != 0) {
            // send the funds back using highestBidder.send(highestBid) is a security risk
            // It is always better to let the user withdraw themselves

            pendingReturns[highestBidder] += highestBid;

        }
        highestBidder = msg.sender;
        highestBid = msg.value;
        emit HighestBidIncreased(msg.sender, msg.value);

    }

    // Withdraw a bid that was outbid

    function withdraw() external returns (bool) {
        uint amount = pendingReturns[msg.sender];
        if (amount > 0) {
            // It is important to set this to zero because the recipient
            // can call this function again as part of the receiving call
            // before `send` returns.
            pendingReturns[msg.sender] = 0;

            // msg.sender is not of type `address payable` and must be
            // explicitly converted using `payable(msg.sender)` in order
            // use the member function `send()`.
            if (!payable(msg.sender).send(amount)) {
                // No need to call throw here, just reset the amount owing
                pendingReturns[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }

    // End the auction and send the highest bid to the beneficiary
    function auctionEnd() external {
        // It is a good guideline to structure functions that interact with  other contracts (i.e. they call functions or send ether)
        // into three pharses
        // 1. checking conditions
        // 2. performing actions
        // 3. interacting with contracts
        // if these phases are mixed up, the other contract could call
        // back into the contract and modify the state o cause effects (ether payout) to be preformed multiple times
        // If functions called internally include interaction with external contracts, they also have to be considered interaction with external contracts


        // 1. The conditions
        if (block.timestamp < auctionEndTime)
            revert AuctionNotYetEnded();
        if (ended)
            revert AuctionEndAlreadyCalled();
        
        // 2. The effects
        ended = true;
        emit AuctionEnded(highestBidder, highestBid);

        // 3. The interaction with other contracts
        beneficiary.transfer(highestBid);
    }

}