// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "../src/LotteryGame.sol";

contract LotteryGameTest is Test {
    LotteryGame game;
    address player1 = address(0x1);
    address player2 = address(0x2);
    address player3 = address(0x3);

    function setUp() public {
        game = new LotteryGame();
    }

    function testRegisterWithCorrectStake() public {
        vm.deal(player1, 1 ether);
        vm.prank(player1);
        game.register{value: 0.02 ether}();
        assertEq(game.totalPrizePool(), 0.02 ether);
        assertEq(game.players(player1).active, true);
        assertEq(game.players(player1).attempts, 2);
    }

    function testFailRegisterWithIncorrectStake() public {
        vm.deal(player1, 1 ether);
        vm.prank(player1);
        game.register{value: 0.01 ether}();
    }

    function testFailRegisterAlreadyRegistered() public {
        vm.deal(player1, 1 ether);
        vm.prank(player1);
        game.register{value: 0.02 ether}();
        vm.prank(player1);
        game.register{value: 0.02 ether}();
    }

    function testGuessNumberValid() public {
        vm.deal(player1, 1 ether);
        vm.prank(player1);
        game.register{value: 0.02 ether}();
        vm.prank(player1);
        game.guessNumber(5);
        assertEq(game.players(player1).attempts, 1);
    }

    function testFailGuessNumberInvalidRange() public {
        vm.deal(player1, 1 ether);
        vm.prank(player1);
        game.register{value: 0.02 ether}();
        vm.prank(player1);
        game.guessNumber(10);
    }

    function testFailGuessNumberNotRegistered() public {
        vm.prank(player1);
        game.guessNumber(5);
    }

    function testFailGuessNumberNoAttempts() public {
        vm.deal(player1, 1 ether);
        vm.prank(player1);
        game.register{value: 0.02 ether}();
        vm.prank(player1);
        game.guessNumber(5);
        vm.prank(player1);
        game.guessNumber(5);
        vm.prank(player1);
        game.guessNumber(5);
    }

    function testDistributePrizes() public {
        vm.deal(player1, 1 ether);
        vm.deal(player2, 1 ether);

        // Register players
        vm.prank(player1);
        game.register{value: 0.02 ether}();
        vm.prank(player2);
        game.register{value: 0.02 ether}();

        // Mock random number to ensure winners
        vm.prank(player1);
        game.guessNumber(1);
        vm.prank(player2);
        game.guessNumber(1);

        // Distribute prizes
        uint256 balanceBefore1 = player1.balance;
        uint256 balanceBefore2 = player2.balance;
        game.distributePrizes();

        // Check prize distribution (0.04 ETH total, split between 2 winners)
        assertEq(player1.balance, balanceBefore1 + 0.02 ether);
        assertEq(player2.balance, balanceBefore2 + 0.02 ether);
        assertEq(game.totalPrizePool(), 0);
        assertEq(game.getPrevWinners().length, 2);
    }

    function testFailDistributePrizesNoWinners() public {
        game.distributePrizes();
    }

    function testGetPrevWinners() public {
        vm.deal(player1, 1 ether);
        vm.prank(player1);
        game.register{value: 0.02 ether}();
        vm.prank(player1);
        game.guessNumber(1);
        game.distributePrizes();
        address[] memory prevWinners = game.getPrevWinners();
        assertEq(prevWinners.length, 1);
        assertEq(prevWinners[0], player1);
    }
}