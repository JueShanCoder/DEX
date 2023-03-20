// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IZuniswapV2Factory {
    function pairs(address, address) external pure returns (address);

    function createPair(address, address) external pure returns (address);
}