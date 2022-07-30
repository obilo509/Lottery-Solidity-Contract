// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Lottery {
    enum State {
        IDLE,
        BETTING
    }

    address[] public players;
    State public currentState = State.IDLE;
    uint public betCount;
    uint public betSize;
    uint public houseeFee;
    address admin;

    constructor(uint fee) public {
        require(fee > 1 && fee < 99, "fee should be between 1 and 99");
        admin = msg.sender;
        houseeFee = fee;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin");
        _;
    }

    modifier inState(State state)   {
        require(state == currentState, "current state does not allow this");
        _;
    }

    function createBet(uint count, uint size) external onlyAdmin() inState(State.IDLE){
        betCount = count;
        betSize = size;
        currentState = State.BETTING;
    }

    function bet() external payable inState(State.BETTING) {
        require(msg.value == betSize, "can only bet exactly the bet size");
        players.push(msg.sender);
        if(players.length == betCount) {
            uint winner = _randomModule(betCount);
            payable(players[winner]).transfer((betSize * betCount) * (100 - houseeFee) / 100);
            currentState = State.IDLE;
            delete players;
        }
    }

    function _randomModule(uint modulo) view internal returns(uint) {
        return uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % modulo;
    }

    function cancel() external inState(State.BETTING) onlyAdmin() {
        for(uint i = 0; i < players.length; i++) {
            payable(players[i]).transfer(betSize);
        }
        delete players;
        currentState = State.IDLE;
    }
}
