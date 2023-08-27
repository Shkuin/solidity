// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract AucEngine {
    address public owner;
    uint constant DURATION = 2 days; // 2 * 24 * 60 * 60
    uint constant FEE = 10; // 10%
    // immutable - оттичается от constant тем что он будет неизменяемый, но задать его можно позже
    // constant надо сразу определять при объявлении
    struct Auction {
        address payable seller; // кто продает
        uint startingPrice; // стартовая цена - максимальная цена
        uint finalPrice; // конечная цена
        uint startAt; // время начала
        uint endsAt; // время конца
        uint discountRate; // на какую сумму снижается цена за одну итерацию снижается цена
        string item; // вещь
        bool stopped;

    }

    Auction[] public auctions;

    // в параметрах ивента не пишем memory или calldata - потому что это будет просто информация записанная в журнал
    event AuctionCreated(uint index, string itemName, uint startingPrice, uint duration); // перепрочитать про ивенты
    event AuctionEnded(uint index, uint finalPrice, address winner);

    constructor() {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require();
        _;
    }
    function withdraw() external onlyOwner {
        //...
    }

    function createAuction(uint _startingPrice, uint _discountRate, string memory _item, uint _duration) external {
        uint duration = _duration == 0 ? DURATION : _duration;

        require(_startingPrice >= _discountRate * duration, "incorrect starting price");

        Auction memory newAuction = Auction({
            seller: payable(msg.sender),
            startingPrice: _startingPrice,
            finalPrice: _startingPrice,
            discountRate: _discountRate,
            startAt: block.timestamp, // now
            endsAt: block.timestamp + duration,
            item: _item,
            stopped: false
        });

        auctions.push(newAuction);

        emit AuctionCreated(auctions.length - 1, _item, _startingPrice, duration);
    }

    function getPriceFor(uint index) public view returns(uint) {
        // пишем memory если не хотим изменять объект в блокчейне или не хотим чтобы изменения записывались
        Auction memory cAuction = auctions[index];
        require(!cAuction.stopped, "stopped!");
        uint elapsed = block.timestamp - cAuction.startAt;
        uint discount = cAuction.discountRate * elapsed;
        return cAuction.startingPrice - discount;
    }

    function buy(uint index) external payable {
        // storage аналогично ссылке, те указываем когда изменить 
        Auction storage cAuction = auctions[index];
        require(!cAuction.stopped, "stopped!");
        require(block.timestamp < cAuction.endsAt, "ended!");
        uint cPrice = getPriceFor(index);
        require(msg.value >= cPrice, "not enough funds!");
        cAuction.stopped = true;
        cAuction.finalPrice = cPrice;
        uint refund = msg.value - cPrice;
        if(refund > 0) {
            payable(msg.sender).transfer(refund);
        }
        cAuction.seller.transfer(
            cPrice - ((cPrice * FEE) / 100)
        ); // 500
        // 500 - ((500 * 10) / 100) = 500 - 50 = 450
        // Math.floor --> JS
        emit AuctionEnded(index, cPrice, msg.sender);
    }
}