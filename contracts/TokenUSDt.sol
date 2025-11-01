// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract USDt is ERC20, Ownable {
    
    constructor() ERC20("USD Token", "USDt") Ownable(msg.sender) {
        // 初始發行 1,000,000 USDt (錢包顯示 1,000,000.00)
        _mint(msg.sender, 1000000 * 1000000);
    }
    
    // 2位小數：錢包顯示 XX.XX 格式
    function decimals() public pure override returns (uint8) {
        return 6;
    }
    
    // 鑄造 USDt（輸入美元數量）
    function mint(address to, uint256 dollarAmount) external onlyOwner {
        _mint(to, dollarAmount * 1000000);
    }
    
    // 銷毀 USDt
    function burn(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
    }
    
    // 轉帳美元（輸入美元數量，自動轉換）
    function transferUSD(address to, uint256 dollarAmount) external returns (bool) {
        return transfer(to, dollarAmount * 1000000);
    }
    
    // 授權美元
    function approveUSD(address spender, uint256 dollarAmount) external returns (bool) {
        return approve(spender, dollarAmount * 1000000);
    }
    
    // 獲取美元餘額（去除小數）
    function balanceUSD(address account) external view returns (uint256) {
        return balanceOf(account) / 1000000;
    }
    
    // 獲取總供應量（美元）
    function totalSupplyUSD() external view returns (uint256) {
        return totalSupply() / 1000000;
    }
}