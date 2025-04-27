// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title LotteryGame
 * @dev A simple number guessing game where players can win ETH prizes
 */
contract LotteryGame {
    struct Player {
        uint256 attempts;
        bool active;
    }

    // State variables
    mapping(address => Player) public players;
    address[] public playerAddresses;
    uint256 public totalPrizePool;
    address[] public winners;
    address[] public prevWinners;

    // Events
    event PlayerRegistered(address indexed player, uint256 stake);
    event GuessResult(address indexed player, uint256 guess, bool isCorrect);
    event PrizesDistributed(uint256 winnerCount, uint256 prizePerWinner);

    /**
     * @dev Register to play the game
     * Players must stake exactly 0.02 ETH to participate
     */
    function register() public payable {
        require(msg.value == 0.02 ether, "Must stake exactly 0.02 ETH");
        require(!players[msg.sender].active, "Player already registered");

        players[msg.sender] = Player({attempts: 2, active: true});
        playerAddresses.push(msg.sender);
        totalPrizePool += msg.value;

        emit PlayerRegistered(msg.sender, msg.value);
    }

    /**
     * @dev Make a guess between 1 and 9
     * @param guess The player's guess
     */
    function guessNumber(uint256 guess) public {
        require(guess >= 1 && guess <= 9, "Guess must be between 1 and 9");
        require(players[msg.sender].active, "Player not registered");
        require(players[msg.sender].attempts > 0, "No attempts left");

        uint256 randomNumber = _generateRandomNumber();
        bool isCorrect = (guess == randomNumber);

        players[msg.sender].attempts--;

        if (isCorrect) {
            winners.push(msg.sender);
        }

        emit GuessResult(msg.sender, guess, isCorrect);
    }

    /**
     * @dev Distribute prizes to winners
     */
    function distributePrizes() public {
        require(winners.length > 0, "No winners to distribute prizes");

        uint256 prizePerWinner = totalPrizePool / winners.length;

        for (uint256 i = 0; i < winners.length; i++) {
            address winner = winners[i];
            (bool success, ) = winner.call{value: prizePerWinner}("");
            require(success, "Prize transfer failed");
            prevWinners.push(winner);
        }

        // Reset game state
        for (uint256 i = 0; i < playerAddresses.length; i++) {
            delete players[playerAddresses[i]];
        }
        delete playerAddresses;
        delete winners;
        totalPrizePool = 0;

        emit PrizesDistributed(winners.length, prizePerWinner);
    }

    /**
     * @dev View function to get previous winners
     * @return Array of previous winner addresses
     */
    function getPrevWinners() public view returns (address[] memory) {
        return prevWinners;
    }

    /**
     * @dev Helper function to generate a "random" number
     * @return A uint between 1 and 9
     * NOTE: This is not secure for production use!
     */
    function _generateRandomNumber() internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, msg.sender))) % 9 + 1;
    }
}