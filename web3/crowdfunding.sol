// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Crowdfunding {
    struct Campaign {
        address payable creator;
        string title;
        string description;
        uint goalAmount;
        uint currentAmount;
        uint deadline;
        bool isOpen;
    }

    Campaign[] public campaigns;
    mapping(uint => mapping(address => uint)) public contributions;

    function createCampaign(string memory title, string memory description, uint goalAmount, uint durationInDays) public {
        uint deadline = block.timestamp + (durationInDays * 1 days);
        campaigns.push(Campaign({
            creator: payable(msg.sender),
            title: title,
            description: description,
            goalAmount: goalAmount,
            currentAmount: 0,
            deadline: deadline,
            isOpen: true
        }));
    }

    function contribute(uint campaignId) public payable {
        Campaign storage campaign = campaigns[campaignId];
        require(campaign.isOpen, "Campaign is not open.");
        require(block.timestamp < campaign.deadline, "Campaign has ended.");
        require(msg.value > 0, "Contribution must be more than 0.");

        campaign.currentAmount += msg.value;
        contributions[campaignId][msg.sender] += msg.value;
    }

    function checkIfGoalReached(uint campaignId) public {
        Campaign storage campaign = campaigns[campaignId];
        require(block.timestamp >= campaign.deadline, "Campaign is still running.");
        require(campaign.isOpen, "Campaign is not open.");

        if (campaign.currentAmount >= campaign.goalAmount) {
            campaign.isOpen = false;
            campaign.creator.transfer(campaign.currentAmount);
        } else {
            refundAll(campaignId);
        }
    }

    function refundAll(uint campaignId) private {
        Campaign storage campaign = campaigns[campaignId];
        for (uint i = 0; i < campaigns.length; i++) {
            address contributor = payable(campaigns[i].creator);
            uint amount = contributions[campaignId][contributor];
            if (amount > 0) {
                (bool sent, ) = contributor.call{value: amount}("");
                require(sent, "Failed to send Ether");
                contributions[campaignId][contributor] = 0;
            }
        }
        campaign.isOpen = false;
    }
}
