// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";

error FundMe__NotOwner();

// 699432 gas
// 679292 gas: add constant keyword to MINIMUM_USD
// 655701 gas: add immutable keyword to i_owner
contract FundMe {
    using PriceConverter for uint256;

    address[] public funders;
    mapping(address funder => uint256 amountFunded)
        public addressToAmoundFunded;

    address public immutable i_owner; // declare immutable when assigned later
    uint256 public constant MINIMUM_USD = 5e18; // declare constant when assigned immediately
    // 307 gas: constant
    // 2451 gas: non-constant
    AggregatorV3Interface private s_priceFeed;

    // 444 gas: immutable
    // 2558 gas: non-immutable

    constructor(address priceFeed) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    function fund() public payable {
        // Allow users to send $ (have a minimum $ sent)
        require(
            msg.value.getConversionRate(s_priceFeed) > MINIMUM_USD,
            "Not enough USD sent"
        );
        funders.push(msg.sender);
        addressToAmoundFunded[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmoundFunded[funder] = 0;
        }

        // Reset the array
        funders = new address[](0);

        // Actually withdraw funds

        // // transfer: Reverts if the tx fails (2300 gas cap)
        // payable(msg.sender).transfer(address(this).balance); // msg.sender is of type address; sending native currencies requires a payable address, hence the type casting

        // // send: Doesn't revert by itself, returns a bool (2300 gas cap)
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed"); // Revert if send fails

        // Recommended way to send/receive native currencies (ETH, AVAX, etc.)
        // call: Doesn't revert by itself, returns a bool and a bytes object (unused) (no gas cap)
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed"); // Revert if call fails
    }

    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }

    modifier onlyOwner() {
        // require(msg.sender == i_owner, "Must be owner to perform this action");
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        _; // Order of the underscore matters; determines where the contents of the function with this modifier executes
    }

    // What happens if someone sends this contract ETH without calling the fund() function
    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}
