// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./mocks/ERC20Mintable.sol";
import {ZuniswapV2Pair} from "../src/ZuniswapV2Pair.sol";
import "forge-std/Test.sol";
import "../src/libraries/UQ112x112.sol";

contract ZuniswapV2PairTest is Test {
    ERC20Mintable token0;
    ERC20Mintable token1;
    ZuniswapV2Pair pair;
    TestUser testUser;
    // part 1...
    function setUp() public {
        testUser = new TestUser();

        token0 = new ERC20Mintable("Token A", "TKNA");
        token1 = new ERC20Mintable("Token B", "TKNB");

        pair = new ZuniswapV2Pair(address(token0), address(token1));

        token0.mint(10 ether, address(this));
        token1.mint(10 ether, address(this));

        token0.mint(10 ether, address(testUser));
        token1.mint(10 ether, address(testUser));
    }

//    // part 1...
//    function assertReserves(uint112 expectReserve0, uint112 expectReserve1) internal {
//        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
//        assertEq(reserve0, expectReserve0, "unexpected reserve0");
//        assertEq(reserve1, expectReserve1, "unexpected reserve1");
//    }
//
    // part 2..
    function assertCumulativePrices(
        uint256 expectedPrice0,
        uint256 expectedPrice1
    ) internal {
        assertEq(
            pair.price0CumulativeLast(),
            expectedPrice0,
            "unexpected cumulative price 0"
        );

        assertEq(
            pair.price1CumulativeLast(),
            expectedPrice1,
            "unexpected cumulative price 1"
        );
    }

    // part2 ...
    function calculateCurrentPrice() internal returns (uint256 price0, uint256 price1)
    {
        (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();
        console2.log("reserve0 is %s, reserve1 is %s", reserve0, reserve1);
        price0 = reserve0 > 0 ? (reserve1 * uint256(UQ112x112.Q112)) / reserve0 : reserve0;
        price1 = reserve1 > 0 ? (reserve0 * uint256(UQ112x112.Q112)) / reserve1 : reserve1;
    }

    // part2 ...
    function assertBlockTimestampLast(uint32 expected) internal {
        (, , uint32 blockTimestampLast) = pair.getReserves();
        assertEq(blockTimestampLast, expected, "unexpected blockTimestampLast");
    }
//
//    // part 1...
//    function testMintBootstrap() public {
//        token0.transfer(address(pair), 1 ether);
//        token1.transfer(address(pair), 1 ether);
//
//        pair.mint();
//
//        assertEq(pair.balanceOf(address(this)), 1 ether - 1000);
//        assertReserves(1 ether, 1 ether);
//        assertEq(pair.totalSupply(), 1 ether);
//    }
//
//    // part 1...
//    function testMintWhenTheresLiquidity() public {
//        // first liquidity
//        token0.transfer(address(pair), 1 ether);
//        token1.transfer(address(pair), 1 ether);
//        pair.mint();
//        // reserve0: 1 ether, reserve1: 1 ether, amount0: 1 ether, amount1: 1 ether, liquidity: 1 ether - 1000
//
//        // second liquidity
//        token0.transfer(address(pair), 2 ether);
//        token1.transfer(address(pair), 2 ether);
//        pair.mint();
//        // amount0: 2 ether, reserve0 : 3 ether
//        // amount1: 2 ether, reserve1 : 3 ether
//        // liquidity: (2 ether * 1 ether) / 1 ether = 2 ether
//
//        assertEq(pair.balanceOf(address(this)), 3 ether - 1000);
//        assertEq(pair.totalSupply(), 3 ether);
//        assertReserves(3 ether, 3 ether);
//    }
//
//    // part 1...
//    function testMintUnbalanced() public {
//        // first liquidity
//        token0.transfer(address(pair), 1 ether);
//        token1.transfer(address(pair), 1 ether);
//        pair.mint();
//        // reserve0: 1 ether, reserve1: 1 ether, amount0: 1 ether, amount1: 1 ether
//        // liquidity: 1 ether - 1000
//        assertEq(pair.balanceOf(address(this)), 1 ether - 1000);
//        assertEq(pair.totalSupply(), 1 ether);
//        assertReserves(1 ether, 1 ether);
//
//        // second liquidity
//        token0.transfer(address(pair), 2 ether);
//        token1.transfer(address(pair), 1 ether);
//        pair.mint();
//        // amount0: 2 ether, reserve0 : 3 ether
//        // amount1: 1 ether, reserve1 : 2 ether
//        // liquidity: (1 ether * 1 ether) / 1 ether = 1 ether
//        assertEq(pair.balanceOf(address(this)), 2 ether - 1000);
//        assertEq(pair.totalSupply(), 2 ether);
//        assertReserves(3 ether, 2 ether);
//
//    }
//
//    // part 1...
//    function testMintLiquidityUnderflow() public {
//        // 0x11: If an arithmetic operation results in underflow or overflow outside of an unchecked { ... } block.
//        vm.expectRevert(
//            hex"4e487b710000000000000000000000000000000000000000000000000000000000000011"
//        );
//        pair.mint();
//    }
//
//    // part 1...
//    function testMintZeroLiquidity() public {
//        token0.transfer(address(pair), 1000);
//        token1.transfer(address(pair), 1000);
//
//        vm.expectRevert(bytes(hex"d226f9d4")); // InsufficientLiquidityMinted()
//        pair.mint();
//    }
//
//    // part 1...
//    function testBurn() public {
//        token0.transfer(address(pair), 1 ether);
//        token1.transfer(address(pair), 1 ether);
//
//        // reserve0: 1 ether, amount0: 1 ether
//        // reserve1: 1 ether, amount1: 1 ether
//        // liquidity: 1 ether - 1000
//        pair.mint();
//
//        // amount0: (1 ether - 1000) * 1 ether / (1 ether) = 1 ether
//        // amount1: (1 ether - 1000) * 1 ether / (1 ether) = 1 ether
//        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
//        pair.burn();
//
//        assertEq(pair.balanceOf(address(this)), 0);
//        // Only MINIMUM_LIQUIDITY
//        assertReserves(1000, 1000);
//        assertEq(pair.totalSupply(), 1000);
//        assertEq(token0.balanceOf(address(this)), 10 ether - 1000);
//        assertEq(token1.balanceOf(address(this)), 10 ether - 1000);
//    }
//
//    // part 1...
//    function testBurnUnbalanced() public {
//
//        token0.transfer(address(pair), 1 ether);
//        token1.transfer(address(pair), 1 ether);
//        pair.mint();
//        // token0[pair] = 1 ether
//        // token0[pair] = 1 ether
//        // pair[address(this)] = 1 ether - 1000 = 999999999999999000
//        // pair.totalSupply() = 1 ether
//
//        token0.transfer(address(pair), 2 ether);
//        token1.transfer(address(pair), 1 ether);
//
//        pair.mint();
//        // token0[pair] = 3 ether
//        // token1[pair] = 2 ether
//        // pair[address(this)] = 2 ether - 1000 = 1999999999999999000
//        // pair.totalSupply() = 2 ether
//        pair.burn();
//        // amount0 = (3000000000000000000 * 1999999999999999000) / 2000000000000000000 = 2.999999999999999e18
//        // amount1 = (2000000000000000000 * 1999999999999999000) / 2000000000000000000 = 1.999999999999999e18
//
//        assertEq(pair.balanceOf(address(this)), 0);
//        // Only MINIMUM_LIQUIDITY
//        assertReserves(1500, 1000);
//        assertEq(pair.totalSupply(), 1000);
//        assertEq(token0.balanceOf(address(this)), 10 ether - 1500);
//        assertEq(token1.balanceOf(address(this)), 10 ether - 1000);
//    }
//
//    // part 1...
//    function testBurnUnbalancedDifferentUsers() public {
//        testUser.providerLiquidity(
//            address(pair),
//            address(token0),
//            address(token1),
//            uint256(1 ether),
//            uint256(1 ether)
//        );
//
//        assertEq(pair.balanceOf(address(this)), 0);
//        assertEq(pair.balanceOf(address(testUser)), 1 ether - 1000);
//        // pair[user] = 1 ether - 1000
//        assertEq(pair.totalSupply(), 1 ether);
//
//        token0.transfer(address(pair), 2 ether);
//        token1.transfer(address(pair), 1 ether);
//
//        // balance0: 3000000000000000000
//        // balance1: 2000000000000000000
//        // amount0: 2000000000000000000
//        // amount1: 1000000000000000000
//        // pair[this]: 1000000000000000000
//        // totalSupply(): 2000000000000000000
//
//        pair.mint();
//
//        assertEq(pair.balanceOf(address(this)), 1 ether);
//
//        pair.burn();
//
//        assertEq(pair.balanceOf(address(this)), 0);
//        assertReserves(1.5 ether, 1 ether);
//        assertEq(pair.totalSupply(), 1 ether);
//        assertEq(token0.balanceOf(address(this)), 10 ether - 0.5 ether);
//        assertEq(token1.balanceOf(address(this)), 10 ether);
//    }
//
//    // part 1...
//    function testBurnZeroTotalSupply() public {
//        // 0x12; If you divide or modulo by zero.
//        vm.expectRevert(
//            hex"4e487b710000000000000000000000000000000000000000000000000000000000000012"
//        );
//        pair.burn();
//    }
//
//    // part 1...
//    function testBurnZeroLiquidity() public {
//        // Transfer and mint as a normal user.
//        token0.transfer(address(pair), 1 ether);
//        token1.transfer(address(pair), 1 ether);
//        pair.mint();
//
//        // Burn as a user who hasn't provided liquidity.
//        bytes memory prankData = abi.encodeWithSignature("burn()");
//
//        vm.prank(address(0xdeadbeef));
//        vm.expectRevert(bytes(hex"749383ad")); // InsufficientLiquidityBurned()
//        pair.burn();
//    }
//
//    // part 1...
//    function testReservesPacking() public {
//        token0.transfer(address(pair), 1 ether);
//        token1.transfer(address(pair), 2 ether);
//        pair.mint();
//
//        bytes32 val = vm.load(address(pair), bytes32(uint256(8)));
//        assertEq(
//            val,
//            hex"000000000000000000001bc16d674ec800000000000000000de0b6b3a7640000"
//        );
//    }
//
//    // part 2...
//    function testSwapBasicScenario() public {
//        token0.transfer(address(pair), 1 ether);
//        token1.transfer(address(pair), 2 ether);
//        pair.mint();
//        // LP-token: 根号 1 * 1 = 1 ether - 1000
//        // balance0: 1 ether
//        // balance1: 1 ether
//        // reserve0: 1 ether
//        // reserve1: 1 ether
//
//        token0.transfer(address(pair), 0.1 ether);
//        pair.swap(0, 0.18 ether, address(this));
//
//        assertEq(
//            token0.balanceOf(address(this)),
//            10 ether - 1 ether - 0.1 ether,
//            "unexpected token0 balance"
//        );
//
//        assertEq(
//            token1.balanceOf(address(this)),
//            10 ether - 2 ether + 0.18 ether,
//            "unexpected token0 balance"
//        );
//
//        assertReserves(1 ether + 0.1 ether, 2 ether - 0.18 ether);
//    }
//
//    // part 2...
//    function testSwapBasicScenarioReverseDirection() public {
//        token0.transfer(address(pair), 1 ether);
//        token1.transfer(address(pair), 2 ether);
//        pair.mint();
//        // LP-Token: 根号(1000000000000000000 * 2000000000000000000 ) = 1.414213562373095e18 - 1000 = 1.414213562373094e18
//
//        token1.transfer(address(pair), 0.2 ether);
//        pair.swap(0.09 ether, 0, address(this));
//
//        assertEq(
//            token0.balanceOf(address(this)),
//            10 ether - 1 ether + 0.09 ether,
//            "unexpected token0 balance"
//        );
//
//        assertEq(
//            token1.balanceOf(address(this)),
//            10 ether - 2 ether - 0.2 ether,
//            "unexpected token1 balance"
//        );
//
//        assertReserves(1 ether - 0.09 ether, 2 ether + 0.2 ether);
//    }
//
//    // part 2...
//    function testSwapBidirectional() public {
//        token0.transfer(address(pair), 1 ether);
//        token1.transfer(address(pair), 2 ether);
//        pair.mint();
//
//        token0.transfer(address(pair), 0.1 ether);
//        token1.transfer(address(pair), 0.2 ether);
//        pair.swap(0.09 ether, 0.18 ether, address(this));
//
//        assertEq(
//            token0.balanceOf(address(this)),
//            10 ether - 1 ether - 0.1 ether + 0.09 ether,
//            "unexpected token0 balance"
//        );
//
//        assertEq(
//            token1.balanceOf(address(this)),
//            10 ether - 2 ether - 0.2 ether + 0.18 ether,
//            "unexpected token1 balance"
//        );
//
//        assertReserves(1 ether + 0.1 ether, 2 ether + 0.2 ether);
//    }
//
//    // part 2...
//    function testSwapZeroOut() public {
//        token0.transfer(address(pair), 1 ether);
//        token1.transfer(address(pair), 2 ether);
//        pair.mint();
//
//        // InsufficientOutputAmount
//        vm.expectRevert(bytes(hex"42301c23"));
//        pair.swap(0, 0, address(this));
//    }
//
//    // part 2...
//    function testSwapInsufficientLiquidity() public {
//        token0.transfer(address(pair), 1 ether);
//        token1.transfer(address(pair), 2 ether);
//        pair.mint();
//
//        // InsufficientLiquidity
//        vm.expectRevert(bytes(hex"bb55fd27"));
//        pair.swap(0, 2.1 ether, address(this));
//
//        vm.expectRevert(bytes(hex"bb55fd27"));
//        pair.swap(1.1 ether, 0, address(this));
//    }
//
//    // part 2...
//    function testSwapUnderpriced() public {
//        token0.transfer(address(pair), 1 ether);
//        token1.transfer(address(pair), 2 ether);
//        pair.mint();
//
//        token0.transfer(address(pair), 0.1 ether);
//        pair.swap(0, 0.09 ether, address(this));
//
//        assertEq(
//            token0.balanceOf(address(this)),
//            10 ether - 1 ether - 0.1 ether,
//            "unexpected token0 balance"
//        );
//
//        assertEq(
//            token1.balanceOf(address(this)),
//            10 ether - 2 ether + 0.09 ether,
//            "unexpected token1 balance"
//        );
//
//        assertReserves(1 ether + 0.1 ether, 2 ether - 0.9 ether);
//    }
//
//    // part 2...
//    function testSwapOverpriced() {
//        token0.transfer(address(pair), 1 ether);
//        token1.transfer(address(pair), 2 ether);
//        pair.mint();
//
//        token0.transfer(address(pair), 0.1 ether);
//
//        vm.expectRevert(bytes(hex"bd8bc364")); // InsufficientLiquidity ？？？
//        pair.swap(0, 0.36 ether, address(this));
//
//        assertEq(
//            token0.balanceOf(address(this)),
//            10 ether - 1 ether - 0.1 ether,
//            "unexpected token0 balance"
//        );
//        assertEq(
//            token1.balanceOf(address(this)),
//            10 ether - 2 ether,
//            "unexpected token1 balance"
//        );
//        assertReserves(1 ether, 2 ether);
//    }

    // part 2...
    function testCumulativePrices() public{
        uint112 reserve0;
        uint112 reserve1;
        vm.warp(0);
        token0.transfer(address(pair), 1 ether);
        token1.transfer(address(pair), 1 ether);
        pair.mint();
        // LP-token: (1 ether * 1 ether) - 1000

        (
            uint256 initialPrice0,
            uint256 initialPrice1
        ) = calculateCurrentPrice();
        console2.log("initialPrice0: %s, initialPrice1: %s", initialPrice0, initialPrice1);

        // 0 seconds passed.
        pair.sync();
        (reserve0, reserve1, ) = pair.getReserves();
        console2.log("[0 seconds passed] reserve0 %s , reserve1 %s", reserve0, reserve1);
        assertCumulativePrices(0, 0);

        // 1 second passed.
        vm.warp(1);
        pair.sync();
        (reserve0, reserve1, ) = pair.getReserves();
        console2.log("[1 seconds passed] reserve0 %s , reserve1 %s", reserve0, reserve1);
        assertBlockTimestampLast(1);
        assertCumulativePrices(initialPrice0, initialPrice1);

        // 2 seconds passed.
        vm.warp(2);
        pair.sync();
        (reserve0, reserve1, ) = pair.getReserves();
        console2.log("[2 seconds passed] reserve0 %s , reserve1 %s", reserve0, reserve1);
        assertBlockTimestampLast(2);
        assertCumulativePrices(initialPrice0 * 2, initialPrice1 * 2);

        // 3 seconds passed.
        vm.warp(3);
        pair.sync();
        (reserve0, reserve1, ) = pair.getReserves();
        console2.log("[3 seconds passed] reserve0 %s , reserve1 %s", reserve0, reserve1);
        assertBlockTimestampLast(3);
        assertCumulativePrices(initialPrice0 * 3, initialPrice1 * 3);

        // Price changed.
        token0.transfer(address(pair), 2 ether);
        token1.transfer(address(pair), 1 ether);
        // LP-token: 1 ether
        pair.mint();

        (uint256 newPrice0, uint256 newPrice1) = calculateCurrentPrice();
        console2.log("initialPrice0: %s, initialPrice1: %s", initialPrice0, initialPrice1);

        // 0 seconds since last reserves update.
        assertCumulativePrices(initialPrice0 * 3, initialPrice1 * 3);



    }
}

// part 1...
contract TestUser {
    function providerLiquidity(
        address pairAddress_,
        address token0Address_,
        address token1Address_,
        uint256 amount0_,
        uint256 amount1_
    ) public {
        ERC20(token0Address_).transfer(pairAddress_, amount0_);
        ERC20(token1Address_).transfer(pairAddress_, amount1_);

        ZuniswapV2Pair(pairAddress_).mint();
    }

    function withdrawLiquidity(address pairAddress_) public {
        ZuniswapV2Pair(pairAddress_).burn();
    }
}
