// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./mocks/ERC20Mintable.sol";
import {ZuniswapV2Pair} from "../src/ZuniswapV2Pair.sol";
import "forge-std/Test.sol";

contract ZuniswapV2PairTest is Test {
    ERC20Mintable token0;
    ERC20Mintable token1;
    ZuniswapV2Pair pair;

    function setUp() public {
        token0 = new ERC20Mintable("Token A", "TKNA");
        token1 = new ERC20Mintable("Token B", "TKNB");

        pair = new ZuniswapV2Pair(address(token0), address(token1));

        token0.mint(10 ether, address(this));
        token1.mint(10 ether, address(this));
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
        console2.log("liquidity: %s", pair.balanceOf(address(this)));
        console2.log("balance0: %s", token0.balanceOf(address(pair)));
        console2.log("balance1: %s", token1.balanceOf(address(pair)));
        console2.log("totalSupply: %s", pair.totalSupply());
        console2.log("amount0: %s", (pair.balanceOf(address(this)) * token0.balanceOf(address(pair))) / pair.totalSupply());
        console2.log("amount0 token0 before %s", token0.balanceOf(address(this)));
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
        console2.log("reserve0: %s, reserve1: %s", reserve0, reserve1);
        pair.burn();

        assertEq(pair.balanceOf(address(this)), 0);
        // Only MINIMUM_LIQUIDITY
        assertReserves(1000, 1000);
        assertEq(pair.totalSupply(), 1000);
        assertEq(token0.balanceOf(address(this)), 10 ether - 1000);
        assertEq(token1.balanceOf(address(this)), 10 ether - 1000);
    }

    function testUnbalanced() public {
        token0.transfer(address(pair), 1 ether);
        token1.transfer(address(pair), 1 ether);
        // reserve0: 1 ether, amount0: 1 ether
        // reserve1: 1 ether, amount1: 1 ether
        // liquidity: 1 ether - 1000
        pair.mint();

        token0.transfer(address(pair), 2 ether);
        token1.transfer(address(pair), 1 ether);
        // reserve0: 3 ether, amount0: 2 ether
        // reserve1: 2 ether, amount1: 1 ether
        // liquidity: 1 ether * 1 ether - 1000 / 1 ether = 1 ether - 1000
        pair.mint();

        // liquidity:
        // amount0: (2 ether - 2000) * 3 ether / 2 ether - 1000 =
        // amount1: (2 ether - 2000) * 2 ether / 2 ether - 1000 = 4 ether - 4000 / 2 ether - 100 = 3.999999999999996e18 / 1.999999999999999e18 = 1.999999999999999
        pair.burn();
        // emit log(string(token0.balanceOf(address(pair))));

        assertEq(pair.balanceOf(address(this)), 0);
        // Only MINIMUM_LIQUIDITY
        assertReserves(1500, 1000);
        assertEq(pair.totalSupply(), 1000);
        assertEq(token0.balanceOf(address(this)), 10 ether - 1500);
        assertEq(token1.balanceOf(address(this)), 10 ether - 1000);
    }
}
