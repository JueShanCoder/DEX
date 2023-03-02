// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./mocks/ERC20Mintable.sol";
import {ZuniswapV2Pair} from "../src/ZuniswapV2Pair.sol";
import "forge-std/Test.sol";

contract ZuniswapV2PairTest is Test {
    ERC20Mintable token0;
    ERC20Mintable token1;
    ZuniswapV2Pair pair;
    TestUser testUser;

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

    function assertReserves(uint112 expectReserve0, uint112 expectReserve1) internal {
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
        assertEq(reserve0, expectReserve0, "unexpected reserve0");
        assertEq(reserve1, expectReserve1, "unexpected reserve1");
    }

    function testMintBootstrap() public {
        token0.transfer(address(pair), 1 ether);
        token1.transfer(address(pair), 1 ether);

        pair.mint();

        assertEq(pair.balanceOf(address(this)), 1 ether - 1000);
        assertReserves(1 ether, 1 ether);
        assertEq(pair.totalSupply(), 1 ether);
    }

    function testMintWhenTheresLiquidity() public {
        // first liquidity
        token0.transfer(address(pair), 1 ether);
        token1.transfer(address(pair), 1 ether);
        pair.mint();
        // reserve0: 1 ether, reserve1: 1 ether, amount0: 1 ether, amount1: 1 ether, liquidity: 1 ether - 1000

        // second liquidity
        token0.transfer(address(pair), 2 ether);
        token1.transfer(address(pair), 2 ether);
        pair.mint();
        // amount0: 2 ether, reserve0 : 3 ether
        // amount1: 2 ether, reserve1 : 3 ether
        // liquidity: (2 ether * 1 ether) / 1 ether = 2 ether

        assertEq(pair.balanceOf(address(this)), 3 ether - 1000);
        assertEq(pair.totalSupply(), 3 ether);
        assertReserves(3 ether, 3 ether);
    }

    function testMintUnbalanced() public {
        // first liquidity
        token0.transfer(address(pair), 1 ether);
        token1.transfer(address(pair), 1 ether);
        pair.mint();
        // reserve0: 1 ether, reserve1: 1 ether, amount0: 1 ether, amount1: 1 ether
        // liquidity: 1 ether - 1000
        assertEq(pair.balanceOf(address(this)), 1 ether - 1000);
        assertEq(pair.totalSupply(), 1 ether);
        assertReserves(1 ether, 1 ether);

        // second liquidity
        token0.transfer(address(pair), 2 ether);
        token1.transfer(address(pair), 1 ether);
        pair.mint();
        // amount0: 2 ether, reserve0 : 3 ether
        // amount1: 1 ether, reserve1 : 2 ether
        // liquidity: (1 ether * 1 ether) / 1 ether = 1 ether
        assertEq(pair.balanceOf(address(this)), 2 ether - 1000);
        assertEq(pair.totalSupply(), 2 ether);
        assertReserves(3 ether, 2 ether);

    }

    function testBurn() public {
        token0.transfer(address(pair), 1 ether);
        token1.transfer(address(pair), 1 ether);

        // reserve0: 1 ether, amount0: 1 ether
        // reserve1: 1 ether, amount1: 1 ether
        // liquidity: 1 ether - 1000
        pair.mint();

        // amount0: (1 ether - 1000) * 1 ether / (1 ether) = 1 ether
        // amount1: (1 ether - 1000) * 1 ether / (1 ether) = 1 ether
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
        pair.burn();

        assertEq(pair.balanceOf(address(this)), 0);
        // Only MINIMUM_LIQUIDITY
        assertReserves(1000, 1000);
        assertEq(pair.totalSupply(), 1000);
        assertEq(token0.balanceOf(address(this)), 10 ether - 1000);
        assertEq(token1.balanceOf(address(this)), 10 ether - 1000);
    }

    function testBurnUnbalanced() public {

        token0.transfer(address(pair), 1 ether);
        token1.transfer(address(pair), 1 ether);
        pair.mint();
        // token0[pair] = 1 ether
        // token0[pair] = 1 ether
        // pair[address(this)] = 1 ether - 1000 = 999999999999999000
        // pair.totalSupply() = 1 ether

        token0.transfer(address(pair), 2 ether);
        token1.transfer(address(pair), 1 ether);

        pair.mint();
        // token0[pair] = 3 ether
        // token1[pair] = 2 ether
        // pair[address(this)] = 2 ether - 1000 = 1999999999999999000
        // pair.totalSupply() = 2 ether
        pair.burn();
        // amount0 = (3000000000000000000 * 1999999999999999000) / 2000000000000000000 = 2.999999999999999e18
        // amount1 = (2000000000000000000 * 1999999999999999000) / 2000000000000000000 = 1.999999999999999e18

        assertEq(pair.balanceOf(address(this)), 0);
        // Only MINIMUM_LIQUIDITY
        assertReserves(1500, 1000);
        assertEq(pair.totalSupply(), 1000);
        assertEq(token0.balanceOf(address(this)), 10 ether - 1500);
        assertEq(token1.balanceOf(address(this)), 10 ether - 1000);
    }

    function testBurnUnbalancedDifferentUsers() public {
        testUser.providerLiquidity(
            address(pair),
            address(token0),
            address(token1),
            uint256(1 ether),
            uint256(1 ether)
        );

        assertEq(pair.balanceOf(address(this)), 0);
        assertEq(pair.balanceOf(address(testUser)), 1 ether - 1000);
        // pair[user] = 1 ether - 1000
        assertEq(pair.totalSupply(), 1 ether);

        token0.transfer(address(pair), 2 ether);
        token1.transfer(address(pair), 1 ether);

        // balance0: 3000000000000000000
        // balance1: 2000000000000000000
        // amount0: 2000000000000000000
        // amount1: 1000000000000000000
        // pair[this]: 1000000000000000000
        // totalSupply(): 2000000000000000000

        pair.mint();

        assertEq(pair.balanceOf(address(this)), 1 ether);

        pair.burn();

        assertEq(pair.balanceOf(address(this)), 0);
        assertReserves(1.5 ether, 1 ether);
        assertEq(pair.totalSupply(), 1 ether);
        assertEq(token0.balanceOf(address(this)), 10 ether - 0.5 ether);
        assertEq(token1.balanceOf(address(this)), 10 ether);
    }
}

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
