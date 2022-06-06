// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {

    bool openForWithdrawal = false;
    ExampleExternalContract public exampleExternalContract;
    
    
    uint256 public constant threshold = 1 ether;
    uint256 public deadline = block.timestamp + 100 hours;
    // track individual balances using a mapping:
    mapping ( address => uint256 ) public balances;
    //  balances[msg.sender] += msg.value;

    
    constructor(address exampleExternalContractAddress) {
        exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
    }  
    // A modifier aims to change the behaviour of the function to which it is attached.
    // Automatically checking a condition prior to executing the function (this is mainly what they are used for).
    // You can re-use the same modifier in multiple functions if you are checking for the same condition over your smart contract
    modifier deadlineReached( bool requireReached ) {
        uint256 timeRemaining = timeLeft();
        if( requireReached ) {
        require(timeRemaining == 0, "Deadline is not reached yet");
        } else {
        require(timeRemaining > 0, "Deadline is already reached");
        }
        _;
    }

    modifier notCompleted() {
        bool completed = exampleExternalContract.completed();
        require(!completed, "staking process already completed");
        _;
    } 

    event Stake(address indexed sender, uint256 amount);
    
    // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
    //  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
    function stake() public payable deadlineReached(false) notCompleted {
        
        // update the user's balance
        balances[msg.sender] += msg.value;
        // emit the event to notify the blockchain that we have correctly Staked some fund for the user
        emit Stake(msg.sender, msg.value);
    }

    // After some `deadline` allow anyone to call an `execute()` function
    //  It should either call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value
    
    
    function execute() public notCompleted {

        if (address(this).balance >= threshold && timeLeft() == 0){   
            exampleExternalContract.complete{value: address(this).balance}();  // Does this send money to the other contract?
        } else {
                require(timeLeft() == 0, "Time Still Remaining");
            
        }
        // if the `threshold` was not met, allow everyone to call a `withdraw()` function
        if (address(this).balance < threshold && timeLeft() == 0) {
            openForWithdrawal = true;

        }  
    }

    function withdraw() public {
        require(openForWithdrawal, "Withdrawal not open");

        uint256 userBalance = balances[msg.sender];
        // check if the user has balance to withdraw
        require(userBalance > 0, "You don't have balance to withdraw");

        (bool success, ) = msg.sender.call{value: userBalance}("");  // balances[msg.sender]
        require(success, "Failed to send ETH");
        // reset the balance of the user
        if (success) {
            userBalance = 0;
        } 
        console.log();

    }

    // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
    function timeLeft() public view returns (uint256){
        if (block.timestamp >= deadline){
        return 0;
        }
        else
        {
        return deadline - block.timestamp;
        }
    }

    event Received(address, uint);

    // Add the `receive()` special function that receives eth and calls stake()
    receive() external payable {
        emit Received(msg.sender, msg.value);
        stake();
    }

}