// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;
import './CustomLib.sol';

/** @title Custom Token contract. */
contract BdlToken {
    using CustomLib for uint;
    using CustomLib for address;

    /// Declared & Initialised here since we know the values beforehand
    /// and thus we reduce gas consumption
    address internal owner = msg.sender;
    uint public tokenPrice = 1000 wei;

    /// mapping containing addresses and the number of tokens they hodl
    mapping(address => uint) internal balances;
    uint internal totalTokens; /// variable to keep track of existing number of tokens

    event Price(uint price);
    event Purchase(address buyer, uint amount);
    event Transfer(address sender, address receiver, uint amount);
    event Sell(address seller, uint amount);

    /** @dev Updates balance of sender's tokens.
      * @param amount: uint of tokens to buy.
      * @return bool representing whether the transaction 
      * was successful.
      */
    function buyToken(uint amount) payable public returns (bool) { 
        uint totalPrice = amount * tokenPrice;
        require(msg.value >= totalPrice);
        /// update buyer's token balance
        balances[msg.sender] += amount;
        /// update total number of tokens
        totalTokens += amount;
        /// successful purchase hence emit event
        emit Purchase(msg.sender, amount);
        return true;
    }

    /** @dev Sends tokens from caller to a given recipient.
      * @param recipient: address to which the sender transfers the tokens.
      * @param amount: uint of tokens to transfer.
      * @return bool representing whether the transaction 
      * was successful.
      */
    function transfer(address recipient, uint amount) public returns (bool) {
        require(balances[msg.sender] >= amount);
        balances[msg.sender] -= amount;
        balances[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    /** @dev Sells tokens to the smart contract.
      * @param amount: uint of tokens to sell.
      * @return bool representing whether the transaction 
      * was successful.
      */
    function sellToken(uint amount) payable public returns (bool) {
      /// By using customSend we send 1 wei to the owner of customLib
      require(msg.value >= 1 wei);
      /// Without the 1 wei the user would receive tokenPrice wei for each 
      /// sold token - 1 wei paid in customSend. Thus we add 1 wei extra.
      uint amountToPay = amount * tokenPrice + 1;
      /// contract needs to have enough balance to give the corresponding 
      /// tokenPrice amount for each of the sold tokens
      require(balances[msg.sender] >= amount && getContractBalance() >= amountToPay);
      /// subtract tokens so they are "destroyed"
      totalTokens -= amount;
      /// subtract tokens from user's account
      balances[msg.sender] -= amount;
      /// use CustomLib for sending money to the seller
      bool success = amountToPay.customSend(msg.sender);
      emit Sell(msg.sender, amount);
      return success;
    }

    /** @dev Changes tokenPrice if called by the contract's owner and contract 
      * has sufficient funds.
      * @param price: uint of the new price for the token.
      * @return bool representing whether the transaction 
      * was successful.
      */
    function changePrice(uint price) public returns (bool) {
        /// Only the contract's owner can change tokenPrice
        require(msg.sender == owner);
        /// Add require statement so that "contract's fund suffice so that 
        /// all tokens can be sold for the update price"
        require(address(this).balance >= price * totalTokens);
        tokenPrice = price;
        emit Price(price);
        return true;
    }

    /** @dev Returns token balance of sender.
      * @return uint representing the number of tokens. 
      */
    function getBalance() public view returns (uint) {
        return balances[msg.sender];
    }

    /** @dev Returns balance of the smart contract.
      * @return uint representing the number of wei the smart contract has. 
      */
    function getContractBalance() internal view returns (uint) {
        return address(this).balance;
    }

}