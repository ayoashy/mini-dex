// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Exchange is ERC20 {
address public tokenAddress;

constructor(address token) ERC20("liquidity Token", "lpToken"){
 require(token != address(0), "token address cannot be empty");
 tokenAddress = token;
}

function getReserve() public view returns(uint256){
 return ERC20(tokenAddress).balanceOf(address(this));
}

function addLiquidity(uint256 tokenAmount) public payable returns (uint256){
 uint256 lpTokenToMint;
 uint256 tokenReserveBalance = getReserve();
 uint256 ethReserveBalance = address(this).balance;

 ERC20 token = ERC20(tokenAddress);

 if(tokenReserveBalance == 0){
  token.transferFrom(msg.sender, address(this), tokenAmount);
  lpTokenToMint = ethReserveBalance;
  _mint(msg.sender, lpTokenToMint);
  return lpTokenToMint;
 }

uint256 ethReservePriorToFunctionCall = ethReserveBalance - msg.value;
uint256 minTokenAmountRequired = (msg.value * tokenReserveBalance ) / ethReservePriorToFunctionCall;
require(tokenAmount >= minTokenAmountRequired, "tokenAmount too small!");
token.transferFrom(msg.sender, address(this), minTokenAmountRequired);
lpTokenToMint = (totalSupply() * msg.value) / ethReservePriorToFunctionCall;
_mint(msg.sender, lpTokenToMint);
return lpTokenToMint;
}

function removeLiquidity(uint256 lpTokenAmount) public returns(uint256, uint256) {
 require(lpTokenAmount > 0, "lpTokenAmount must be greater than 0");

 uint256 ethReserveBalance = address(this).balance;
 uint256 liquidityTokenSupply = totalSupply();


 uint256 ethToReturn = (ethReserveBalance * lpTokenAmount) / liquidityTokenSupply;
 uint256 tokenToReturn = (getReserve() * lpTokenAmount) / liquidityTokenSupply;

_burn(msg.sender, lpTokenAmount);
payable(msg.sender).transfer(ethToReturn);
ERC20(tokenAddress).transfer(msg.sender, tokenToReturn);

return(ethToReturn,tokenToReturn);
}

function getOutputAmount(uint256 inputAmount, uint256 inputReserve, uint256 outputReserve) public view returns(uint256) {
 require(inputReserve > 0 && outputReserve > 0, "reserves must be more than zero" );
 uint256 inputAmountWithFee = inputAmount * 99;
 uint256 numerator = inputAmountWithFee * outputReserve;
 uint256 denominator = inputAmountWithFee + (inputReserve * 100);
 return numerator / denominator;
}

function EthToTokenSwap(uint256 minTokenToRecieve) public payable {
 uint256 tokenReserveBalance = getReserve();
 uint256 tokenToRecieve = getOutputAmount(msg.value, address(this).balance - msg.value, getReserve());

 require(tokenToRecieve > minTokenToRecieve, "not expected token");

 ERC20(tokenAddress).transfer(msg.sender, tokenToRecieve);

}

function tokenToEthSwap(uint256 tokenToSwap, uint256 minEthToRecieve) public {
 uint256 ethToRecieve = getOutputAmount(tokenToSwap, getReserve(), address(this).balance);
 require(ethToRecieve > minEthToRecieve, "not up to minimum eth to recieve");
 ERC20(tokenAddress).transferFrom(msg.sender, address(this), tokenToSwap);
 payable(msg.sender).transfer( ethToRecieve);
}
}