# @version ^0.3.1

# Auction params
# Beneficiary receives money from the highest bidder

beneficiary: public(address)
auctionStart: public(uint256)
auctionEnd: public(uint256)

# Current state of the Auction

highestBidder: public(address)
highestBid: public(uint256)

# Set to true at the end, disallows changes
ended: public(bool)

# Keep track of refunded bids so we can follow the withdraw pattern
pendingReturns: public(HashMap[address, uint256])


# Create a simply auction
@external
def __init__(_beneficiary: address, _auction_start: uint256, _bidding_time: uint256):
    self.beneficiary = _beneficiary
    self.auctionStart = _auction_start # auction start can be in the past, present or future
    self.auctionEnd = self.auctionStart + _bidding_time
    assert block.timestamp < self.auctionEnd # auction end time should be in the future

# Bid on the auction with the value sent, the funds will only be refunded if the auction is not won
@external
@payable
def bid():
    # Checkk if bidding period is started
    assert block.timestamp >=self.auctionStart
    # Check if auction is ended
    assert block.timestamp < self.auctionEnd
    # Check if the bid is higher than the current highest bid
    assert msg.value > self.highestBid
    # track the refund for the previous highest bidder
    self.pendingReturns[self.highestBidder] += self.highestBid
    # Track the new highest bidder
    self.highestBidder = msg.sender
    self.highestBid = msg.value

# Withdraw the previously refunded bid. The withdraw pattern
# useed here to avoid security issues
@external
def withdraw():
    pending_amount: uint256 = self.pendingReturns[msg.sender]
    self.pendingReturns[msg.sender] = 0
    send(msg.sender, pending_amount)

# End the auction and send the highest bid to the beneficiary
@external
def endAuction():
# It is a good guideline to structure functions that interact
# with other contracts (i.e. they call functions or send Ether)
# into three phases:
# 1. checking conditions
# 2. performing actions (potentially changing conditions)
# 3. interacting with other contracts
# If these phases are mixed up, the other contract could call
# back into the current contract and modify the state or cause
# effects (Ether payout) to be performed multiple times.
# If functions called internally include interaction with external
# contracts, they also have to be considered interaction with
# external contracts.

    # 1. Condition
    assert block.timestamp >= self.auctionEnd
    # Check if the fuction is already called
    assert not self.ended

    # 2. effects
    self.ended = True

    # 3. transaction
    send(self.beneficiary, self.highestBid)

