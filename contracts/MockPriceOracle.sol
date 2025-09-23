// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MockPriceOracle {
    uint256 private price = 57 * 1e18; // 57台幣，18位小數
    
    function getLatestPriceUSD() external view returns (uint256) {
        return price / 1e18; // 返回57
    }
    
    function getLatestPrice() external view returns (uint256) {
        return price; // 返回57 * 1e18
    }
    
    function setPrice(uint256 _price) external {
        price = _price * 1e18;
    }
    
    function isPriceStale() external pure returns (bool) {
        return false;
    }
}