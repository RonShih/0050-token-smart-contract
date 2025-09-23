// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// 價格預言機接口
interface IPriceOracle {
    function getLatestPriceUSD() external view returns (uint256);
}

contract Token0050t is ERC20, Ownable {
    IPriceOracle public priceOracle;
    
    constructor(address _priceOracle) 
        ERC20("Taiwan 50 Token", "0050t") 
        Ownable(msg.sender) 
    {
        require(_priceOracle != address(0), "Invalid oracle address");
        priceOracle = IPriceOracle(_priceOracle);
        // 初始發行10000股
        _mint(msg.sender, 10000);
    }
    
    // 無小數位數：1股 = 1顆代幣
    function decimals() public pure override returns (uint8) {
        return 0; // 整數股票，1股 = 1 token
    }
    
    // 獲取當前價格（美分為單位，避免小數點問題）
    function getCurrentPrice() external view returns (uint256) {
        return priceOracle.getLatestPriceUSD();
    }
    
    // 計算指定股數的總價值（美分）
    function calculateValue(uint256 shares) external view returns (uint256) {
        require(shares > 0, "Shares must be greater than 0");
        return shares * priceOracle.getLatestPriceUSD();
    }
    
    // 根據金額計算可購買的股數
    function calculateShares(uint256 amount) external view returns (uint256) {
        require(amount > 0, "Amount must be greater than 0");
        uint256 price = priceOracle.getLatestPriceUSD();
        require(price > 0, "Invalid price");
        return amount / price;
    }
    
    // 鑄造代幣（申購用）
    function mint(address to, uint256 shares) external onlyOwner {
        require(to != address(0), "Cannot mint to zero address");
        require(shares > 0, "Shares must be greater than 0");
        _mint(to, shares);
    }
    
    // 銷毀代幣（贖回用）
    function burn(address from, uint256 shares) external onlyOwner {
        require(from != address(0), "Cannot burn from zero address");
        require(shares > 0, "Shares must be greater than 0");
        _burn(from, shares);
    }
    
    // 更新價格預言機
    function setPriceOracle(address _newOracle) external onlyOwner {
        require(_newOracle != address(0), "Invalid oracle address");
        priceOracle = IPriceOracle(_newOracle);
    }
    
    // 獲取總供應量（股數）
    function getTotalShares() external view returns (uint256) {
        return totalSupply();
    }
    
    // 獲取用戶持股數量
    function getSharesOf(address account) external view returns (uint256) {
        return balanceOf(account);
    }
}