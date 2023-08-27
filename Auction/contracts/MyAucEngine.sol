// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


contract Ownership {
    address owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "YOU ARE NOT AN OWNER");
        _;
    }
}

contract AucEngine is Ownership {
    uint duration = 2 days;
    uint constant FEE = 10;

    struct Auction {
        address payable seller;
        uint startPrice;
        uint finalPrice;
        uint startTime;
        uint endTime;
        string item;
        uint discountRate;
        bool stopped;
    }

    Auction[] auctions;

    // в параметрах ивента не пишем memory или calldata - потому что это будет просто информация записанная в журнал
    event AuctionCreated(uint index, string itemName, uint startingPrice, uint duration); // перепрочитать про ивенты
    event AuctionEnded(uint index, uint finalPrice, address winner);

    function createAuction(uint _startPrice, uint _discountRate, string memory _item, uint _duration) external {
        uint currentDuration = _duration == 0 || _duration > duration ? duration : _duration;
        bool checkValid = _startPrice >= currentDuration * _discountRate;
        require(checkValid, "IN THIS CASE PRICE CAN BE LOWER THAN ZERO");

        Auction memory newAuction = Auction({
            seller: payable(msg.sender),
            startPrice: _startPrice,
            finalPrice: _startPrice,
            startTime: block.timestamp,
            endTime: block.timestamp + currentDuration,
            item: _item,
            discountRate: _discountRate,
            stopped: false
        });

        auctions.push(newAuction);

        emit AuctionCreated(auctions.length - 1, _item, _startPrice, currentDuration);
    }

    function withdraw() external onlyOwner {
        address payable _to = payable(owner);
        _to.transfer(address(this).balance);
    }

    function getPriceFor(uint aucIndex) public view returns(uint) {
        require(aucIndex <= auctions.length - 1, "There is no auction with this index");
        Auction memory currentAuction = auctions[aucIndex];
        require(!currentAuction.stopped, "THIS ACUTION WAS STOPPED");
        require(block.timestamp < currentAuction.endTime, "THIS ACUTION WAS ENDED");
        return currentAuction.startPrice - currentAuction.discountRate * (block.timestamp - currentAuction.startTime);
    }

    function buy(uint aucIndex) external payable {
        require(aucIndex <= auctions.length - 1, "There is no auction with this index");

        uint fixTimeToBuy = block.timestamp;

        Auction storage currentAuction = auctions[aucIndex];
        require(!currentAuction.stopped, "THIS ACUTION WAS STOPPED");
        require(fixTimeToBuy < currentAuction.endTime, "THIS ACUTION WAS ENDED");
        uint finalPrice = currentAuction.startPrice - currentAuction.discountRate * (fixTimeToBuy - currentAuction.startTime);

        require(msg.value >= finalPrice, "YOU SENT NOT ENOUGH MONEY TO MAKE TRANSACTION");
        currentAuction.finalPrice = finalPrice;
        currentAuction.stopped = true;

        // send money to seller and fee to owner of auction
        uint refund = msg.value - finalPrice;
        if (refund != 0) {
            payable(msg.sender).transfer(refund);
        }

        uint fee = (finalPrice * FEE) / 100;
        currentAuction.seller.transfer(finalPrice - fee);

        emit AuctionEnded(aucIndex, finalPrice, msg.sender);
    }

}