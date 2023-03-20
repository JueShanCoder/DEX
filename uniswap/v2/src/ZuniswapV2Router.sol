// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./interfaces/IZuniswapV2Factory.sol";

contract ZuniswapV2Router {
    error InsufficientAAmount();
    error InsufficientBAmount();
    error SafeTransferFailed();

    IZuniswapV2Factory factory;

    constructor(address factoryAddress) {
        factory = IZuniswapV2Factory(factoryAddress);
    }
}
