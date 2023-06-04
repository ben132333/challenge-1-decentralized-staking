// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;  //Do not change the solidity version as it negativly impacts submission grading
// Deployer address: 0x6db266e53009346ab50bd8bdddc16ef9f856f206
// Deployed at (goerli): 0xa8228D026B2B343573f7E15aeefA9dfeF4596F5F

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {

  ExampleExternalContract public exampleExternalContract;

  mapping (address => uint256) public balances;
  uint256 public constant threshold = 1 ether;

  uint256 public deadline = block.timestamp + 96 hours;

  modifier deadlinePassed(uint _time) {
      require(_time > deadline, "Deadline not passed");
      _;
  }

  modifier notComplete() {
      require(!exampleExternalContract.completed(), "Contract already completed");
      _;
  }

  bool public openForWithdraw = false;

  constructor(address exampleExternalContractAddress) {
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  event Stake(address staker, uint256 amount);

  // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  // ( Make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
  function stake() public payable notComplete() {
      balances[msg.sender] += msg.value;
      emit Stake(msg.sender, msg.value);
  }

  // After some `deadline` allow anyone to call an `execute()` function
  // If the deadline has passed and the threshold is met, it should call `exampleExternalContract.complete{value: address(this).balance}()`
  function execute() public deadlinePassed(block.timestamp) notComplete() {
      if (address(this).balance >= threshold) {
          openForWithdraw = false;
          exampleExternalContract.complete{value: address(this).balance}();
      } else {
          openForWithdraw = true;
      }
  }

  // If the `threshold` was not met, allow everyone to call a `withdraw()` function to withdraw their balance
  function withdraw() public notComplete() {
      require(openForWithdraw, "Threshold not met");
      uint256 amount = balances[msg.sender];
      balances[msg.sender] = 0;

      payable(msg.sender).transfer(amount);
  }

  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
  function timeLeft() public view returns (uint256) {
    if (block.timestamp >= deadline) {
        return 0;
    } else {
        return deadline - block.timestamp;
    }
  }

  // Add the `receive()` special function that receives eth and calls stake()
  receive() external payable {
    stake();
  }

}
