// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IZuniswapV2Pair {
    function initialize(address, address) external;

    function getReserve() external returns(uint112, uint112, uint32);

    function mint(address) external returns (uint256);
}
