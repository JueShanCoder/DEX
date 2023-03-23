// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/ZuniswapV2Factory.sol";
import "../src/ZuniswapV2Pair.sol";
import "../src/ZuniswapV2Router.sol";
import "./mocks/ERC20Mintable.sol";

contract ZuniswapV2RouterTest is Test {
    ZuniswapV2Factory factory;
    ZuniswapV2Router router;

    ERC20Mintable tokenA;
    ERC20Mintable tokenB;

    function setUp() public {
        factory = new ZuniswapV2Factory();
        router = new ZuniswapV2Router(address(factory));

        tokenA = new ERC20Mintable("Token A", "TKNA");
        tokenB = new ERC20Mintable("Token B", "TKNB");

        tokenA.mint(20 ether, address(this));
        tokenB.mint(20 ether, address(this));
    }

    function encodeError(string memory error)
    internal
    pure
    returns (bytes memory encoded)
    {
        encoded = abi.encodeWithSignature(error);
    }

    function testAddLiquidityCreatesPair() public {
        tokenA.approve(address(router), 1 ether);
        tokenB.approve(address(router), 1 ether);
        router.addLiquidity(
            address(tokenA),
            address(tokenB),
            1 ether,
            1 ether,
            1 ether,
            1 ether,
            address(this)
        );

        address pairAddress = factory.pairs(address(tokenA), address(tokenB));
        console2.log("pairAddress: %s", pairAddress);
        assertEq(pairAddress, 0x48e287Fa1b142e9c9E104cA821ebE53835877E6D);
    }

    function testAddLiquidityNoPair() public {
        tokenA.approve(address(router), 1 ether);
        tokenB.approve(address(router), 1 ether);
        router.addLiquidity(
            address(tokenA),
            address(tokenB),
            1 ether,
            1 ether,
            1 ether,
            1 ether,
            address(this)
        );

        address pairAddress = factory.pairs(address(tokenA), address(tokenB));
        console2.log("pairAddress: %s", pairAddress);
        assertEq(pairAddress, 0x48e287Fa1b142e9c9E104cA821ebE53835877E6D);
    }
}
