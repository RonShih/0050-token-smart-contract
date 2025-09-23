// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/FunctionsClient.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";
import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";

contract PriceOracle0050 is FunctionsClient, ConfirmedOwner {
    using FunctionsRequest for FunctionsRequest.Request;
    
    uint256 private currentPrice;
    uint256 public lastUpdateTime;
    bytes32 public lastRequestId;
    
    // Chainlink Functions 配置
    uint64 public subscriptionId;
    uint32 public gasLimit = 300000;
    bytes32 public donID;
    
    // 事件
    event PriceUpdated(uint256 newPrice, uint256 timestamp);
    event PriceRequested(bytes32 indexed requestId);
    event RequestFailed(bytes32 indexed requestId, bytes error);
    
    // Yahoo Finance API：獲取0050.TW價格
    string private source = 
        "const response = await Functions.makeHttpRequest({"
        "url: 'https://query1.finance.yahoo.com/v8/finance/chart/0050.TW'"
        "});"
        "if (response.error) {"
        "throw Error('Request failed');"
        "}"
        "const result = response.data.chart.result[0];"
        "const price = result.meta.regularMarketPrice;"
        "if (!price) {"
        "throw Error('Price not found');"
        "}"
        "return Functions.encodeUint256(Math.round(price * 1e18));";
    
    constructor() FunctionsClient(0xb83E47C2bC239B3bf370bc41e1459A34b41238D0) ConfirmedOwner(msg.sender) {
        subscriptionId = 5639; // 你的訂閱ID
        donID = 0x66756e2d657468657265756d2d7365706f6c69612d3100000000000000000000; // "fun-ethereum-sepolia-1"
        // 初始價格：20 USD (18位小數)
        currentPrice = 20 * 1e18;
        lastUpdateTime = block.timestamp;
    }
    
    // 獲取最新價格（18位小數）
    function getLatestPrice() external view returns (uint256) {
        return currentPrice;
    }
    
    // 獲取價格（USD整數）
    function getLatestPriceUSD() external view returns (uint256) {
        return currentPrice / 1e18;
    }
    
    // 請求價格更新
    function requestPriceUpdate() external returns (bytes32 requestId) {
        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(source);
        
        requestId = _sendRequest(
            req.encodeCBOR(),
            subscriptionId,
            gasLimit,
            donID
        );
        
        lastRequestId = requestId;
        emit PriceRequested(requestId);
        return requestId;
    }
    
    // Chainlink Functions 回調函數
    function fulfillRequest(
        bytes32 requestId,
        bytes memory response,
        bytes memory err
    ) internal override {
        if (err.length > 0) {
            emit RequestFailed(requestId, err);
            return;
        }
        
        uint256 newPrice = abi.decode(response, (uint256));
        currentPrice = newPrice;
        lastUpdateTime = block.timestamp;
        emit PriceUpdated(newPrice, block.timestamp);
    }
    
    // 手動更新價格（PoC測試用）
    function updatePriceManual(uint256 _newPriceUSD) external onlyOwner {
        require(_newPriceUSD > 0, "Price must be greater than 0");
        currentPrice = _newPriceUSD * 1e18;
        lastUpdateTime = block.timestamp;
        emit PriceUpdated(currentPrice, block.timestamp);
    }
    
    // 管理函數：更新配置
    function updateConfig(
        uint64 _subscriptionId,
        uint32 _gasLimit,
        bytes32 _donID
    ) external onlyOwner {
        subscriptionId = _subscriptionId;
        gasLimit = _gasLimit;
        donID = _donID;
    }
    
    // PoC用途：獲取預言機完整信息
    function getOracleInfo() external view returns (
        uint256 price,
        uint256 priceUSD,
        uint256 lastUpdate,
        uint256 timeSinceUpdate,
        bytes32 lastRequest
    ) {
        return (
            currentPrice,
            currentPrice / 1e18,
            lastUpdateTime,
            block.timestamp - lastUpdateTime,
            lastRequestId
        );
    }
    
    // 檢查價格是否過期（超過1小時）
    function isPriceStale() external view returns (bool) {
        return (block.timestamp - lastUpdateTime) > 3600; // 1小時
    }
}