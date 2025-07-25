// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "../test/LinkToken.sol";
import {console2} from "forge-std/console2.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";
import {console2} from "forge-std/console2.sol";

contract CreateSubscription is Script {
    function createSubscriptionUsingConfig() public returns (uint256, address) {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        address account = helperConfig.getConfig().account;
        (uint256 subId, ) = createSubscription(vrfCoordinator, account);
        return (subId, vrfCoordinator);
    }

    function createSubscription(
        address vrfCoordinator,
        address account
    ) public returns (uint256, address) {
        console2.log("Creating subscription on chainId: ", block.chainid);
        vm.startBroadcast(account);
        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinator)
            .createSubscription();
        vm.stopBroadcast();
        console.log("Your subscription Id is: ", subId);
        console.log("Please update the subscriptionId in HelperConfig.s.sol");
        return (subId, vrfCoordinator);
    }

    function run() external returns (uint256, address) {
        createSubscriptionUsingConfig();
    }
}

contract FundSub is Script {
    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        uint256 subId = helperConfig.getConfig().subscriptionId;
        address vrfCoordinatorV2_5 = helperConfig.getConfig().vrfCoordinator;
        address link = helperConfig.getConfig().link;
        address account = helperConfig.getConfig().account;
        if (subId == 0) {
            CreateSubscription createSub = new CreateSubscription();
            (uint256 updatedSubId, address updatedVRFv2) = createSub.run();
            subId = updatedSubId;
            vrfCoordinatorV2_5 = updatedVRFv2;
            console.log(
                "New SubId Created! ",
                subId,
                "VRF Address: ",
                vrfCoordinatorV2_5
            );
        }

        fundSub(vrfCoordinatorV2_5, subId, link, account);
    }
    function fundSub(
        address vrfCoordinator,
        uint256 subId,
        address linkToken,
        address account
    ) public {
        console2.log("Funding subscription: ", subId);
        console2.log("Using vrfCoordinator: ", vrfCoordinator);
        console2.log("On ChainID: ", block.chainid);
        if (block.chainid == 31337) {
            vm.startBroadcast(account);
            LinkToken(linkToken).transfer(vrfCoordinator, 3000 ether);
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(
                subId,
                3000 ether
            );

            vm.stopBroadcast();
        } else {
            console.log("Funding on chain:");
            console.log("Funding Subscription on chain ID:", block.chainid);
            console.log("Subscription ID:", subId);
            console.log("VRF Coordinator Address:", vrfCoordinator);
            console.log("Link Token Address:", linkToken);
            vm.startBroadcast(account);
            LinkToken(linkToken).transferAndCall(
                vrfCoordinator,
                1 ether,
                abi.encode(subId)
            );
        }
    }

    function run() public {
        fundSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script {
    function addConsumer(
        address contractToAddToVrf,
        address vrfCoordinator,
        uint256 subId,
        address account
    ) public {
        console.log("Adding consumer contract : ", contractToAddToVrf);
        console.log("Using vrfCoordinator: ", vrfCoordinator);
        console.log("On ChainID: ", block.chainid);
        vm.startBroadcast(account);
        VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(
            subId,
            contractToAddToVrf
        );
        vm.stopBroadcast();
    }

    function addConsumerUsingConfig(address mostRecentlyDeployed) public {
        HelperConfig helperConfig = new HelperConfig();
        uint256 subId = helperConfig.getConfig().subscriptionId;
        address vrfCoordinatorV2_5 = helperConfig.getConfig().vrfCoordinator;
        address account = helperConfig.getConfig().account;
        addConsumer(mostRecentlyDeployed, vrfCoordinatorV2_5, subId, account);
    }

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment(
            "Raffle",
            block.chainid
        );
        addConsumerUsingConfig(mostRecentlyDeployed);
    }
}
