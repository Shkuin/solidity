// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Payments {
    struct Payment {
        uint amount; // количество денег в wei
        uint timestamp; // временная метка
        address from; // от кого
        string message; // сообщение
    }

    struct Balance {
        uint totalPayments; // количество совершенных платежей
        mapping(uint => Payment) payments; // мапа всех платежей индекс платежа и сам платеж
    }

    mapping(address => Balance) public balances; // балансы адрессов совершающих платежи

    function currentBalance(address currentAdress) public view returns(uint) {
        return currentAdress.balance; // возвращает текущее значение баланса контракта через встроенный метод
    }

    function contractCurrentBalance() public view returns(uint) {
        return currentBalance(address(this));
    }

    function getPayment(address _addr, uint _index) public view returns(Payment memory) {
        return balances[_addr].payments[_index];
    }

    function pay(string memory message) public payable returns(uint) {
        uint paymentNum = balances[msg.sender].totalPayments;
        balances[msg.sender].totalPayments++;

        Payment memory newPayment = Payment(
            msg.value, // отправляем введеное значение
            block.timestamp, // через ключевое слово и метод ставим временную метку
            msg.sender, // добавляем адресс от кого
            message // ну и сообщение - параметр ф-ии
        );

        balances[msg.sender].payments[paymentNum] = newPayment; // добавляем новый платеж для данного адресса

        return msg.value;
    }
}