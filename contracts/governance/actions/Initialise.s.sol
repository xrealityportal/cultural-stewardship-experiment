// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
 
import { console2 } from "forge-std/console2.sol";
import { Powers } from "@lib/powers-monorepo/solidity/src/Powers.sol";
import { IPowers } from "@lib/powers-monorepo/solidity/src/interfaces/IPowers.sol";
import { ActionHelpers } from "./ActionHelpers.s.sol"; 

// This script contains a set of modular interactions with the primary layer. They  can be used for testing or setting up up an organisation after deployment. 

contract Initialise is ActionHelpers { 
    uint16[] mandateSlots; 
    uint256[] actionIds; 

    uint256 roleCount; 
    uint256 againstVote; 
    uint256 forVote; 
    uint256 abstainVote;

    function runSetupMandate(address powers, uint256 nonce) public {
        // step 0: reset state variables.
        delete mandateSlots;
        delete actionIds;

        // step 1: identify mandates to run. 
        mandateSlots.push(findMandateIdInOrg("Initial Setup: Assign role labels and revokes itself after execution", Powers(payable(powers))));

        // step 2: check if user has the permissions to run these mandates.
        Powers(payable(powers)).canCallMandate(msg.sender, mandateSlots[0]); // should return true.

        // step 3: execute mandates. 
        vm.startBroadcast();
        IPowers(powers).request(mandateSlots[0], abi.encode(), nonce, "Executing initial setup mandate");
        vm.stopBroadcast();
    }

    function unpackReformPackages(address powers, uint256 nonce) public {
        // step 0: reset state variables.
        delete mandateSlots;
        delete actionIds;

        // step 1: identify mandates to run. 
        // find mandates that have "Reform Package " in their nameDescription.
        for (uint16 i = 1; i < Powers(payable(powers)).mandateCounter(); i++) {
            mandateSlots.push(findMandateIdInOrg(string(abi.encodePacked("Reform Package ", vm.toString(i + 1))), Powers(payable(powers))));
        } 
        // step 2: check if user has the permissions to run these mandates.
        for (uint i = 0; i < mandateSlots.length; i++) {
            Powers(payable(powers)).canCallMandate(msg.sender, mandateSlots[i]); // should return true.
        }
        // step 3: unpack reform packages. 
        for (uint i = 0; i < mandateSlots.length; i++) {
            Powers(payable(powers)).request(mandateSlots[i], abi.encode(), nonce + i, "Unpacking reform package for Ideas Layer");  
        }
    }

    function deployIdeasLayer1(address primaryLayer, uint256 nonce, uint256[] memory privateKeys) public {
        // step 0: reset state variables.
        delete mandateSlots;
        delete actionIds;

        // step 1: identify mandate to run. 
        mandateSlots.push(findMandateIdInOrg("Initiate Ideas Layer: Initiate creation of Ideas Layer", Powers(payable(primaryLayer))));
        mandateSlots.push(findMandateIdInOrg("Create Ideas Layer: Execute Ideas Layer creation", Powers(payable(primaryLayer))));
        mandateSlots.push(findMandateIdInOrg("Assign role Id to layer: Assign role id 4 (Ideas Layer) to the new layer", Powers(payable(primaryLayer))));
        mandateSlots.push(findMandateIdInOrg("Register Ideas Layer to Paymaster: Register the new Ideas Layer to the paymaster as a sponsored target", Powers(payable(primaryLayer))));

        // step 2: check if msg.sender has the permissions to run these mandates.
        for (uint i = 0; i < mandateSlots.length; i++) {
            Powers(payable(primaryLayer)).canCallMandate(msg.sender, mandateSlots[i]); // should return true 

        }

        // step 3a: execute mandate: initiate ideas layer: propose
        vm.startBroadcast();
        actionIds.push(IPowers(primaryLayer).propose(mandateSlots[0], abi.encode(), nonce, string.concat("Initiating create ideas layer")));
        vm.stopBroadcast();

        // voting on proposal.
        (roleCount, againstVote, forVote, abstainVote) = voteOnProposal(
            primaryLayer,
            mandateSlots[0],
            actionIds[0],
            privateKeys,
            nonce, // randomiser
            100 // pass chance in percentage. 
        );

        console2.log("Votes cast for initiating ideas layer proposal: ", forVote);
        console2.log("Votes cast against initiating ideas layer proposal: ", againstVote);
        console2.log("Votes cast abstaining on initiating ideas layer proposal: ", abstainVote);
        console2.log("Total voters: ", roleCount);
    }

    function deployIdeasLayer2(address primaryLayer, uint256 nonce, uint256[] memory privateKeys) public {
        // executing proposal. 
        vm.startBroadcast();
        IPowers(payable(primaryLayer)).request(mandateSlots[0], abi.encode(), nonce, string.concat("Executing create ideas layer"));
        vm.stopBroadcast();

        // step 3b: execute mandate: create ideas layer.
        // creating proposal. 
        vm.startBroadcast();
        actionIds.push(IPowers(primaryLayer).propose(mandateSlots[1], abi.encode(), nonce, string.concat("Creating ideas layer")));
        vm.stopBroadcast();

        // voting on proposal.
        (roleCount, againstVote, forVote, abstainVote) = voteOnProposal(
            primaryLayer,
            mandateSlots[1],
            actionIds[1],
            privateKeys,
            nonce, // randomiser
            100 // pass chance in percentage. 
        );

        console2.log("Votes cast for creating ideas layer proposal: ", forVote);
        console2.log("Votes cast against creating ideas layer proposal: ", againstVote);
        console2.log("Votes cast abstaining on creating ideas layer proposal: ", abstainVote);
        console2.log("Total voters: ", roleCount);
    }

    function deployIdeasLayer3(address primaryLayer, uint256 nonce) public {
        // executing proposal. 
        vm.startBroadcast();
        IPowers(payable(primaryLayer)).request(mandateSlots[1], abi.encode(), nonce, string.concat("Executing create ideas layer"));
        vm.stopBroadcast();

        // step 3c: execute mandate: assign role ID to layer, and register at paymaster. 
        vm.startBroadcast();
        IPowers(primaryLayer).request(mandateSlots[2], abi.encode(), nonce, string.concat("Assigning role ID for ideas layer"));
        IPowers(primaryLayer).request(mandateSlots[3], abi.encode(), nonce, string.concat("Registering ideas layer to paymaster"));
        vm.stopBroadcast();
    }

    function deployConvergenceLayer1(address ideasLayer, address primaryLayer, uint256 nonce, uint256[] memory privateKeys) public {
        // step 0: reset state variables.
        delete mandateSlots;
        delete actionIds;

        // step 1: identify mandate to run. 
        mandateSlots.push(findMandateIdInOrg("Request new Convergence Layer: Participants can initiate the request for creating a new Convergence Layer under the Primary Layer", Powers(payable(ideasLayer))));
        mandateSlots.push(findMandateIdInOrg("Send request: Stewards can send the request to create a new Convergence Layer to the Primary Layer", Powers(payable(ideasLayer))));

        mandateSlots.push(findMandateIdInOrg("Create Convergence Layer: Ideas Layers can create a Convergence Layer", Powers(payable(primaryLayer)))); 
        mandateSlots.push(findMandateIdInOrg("Assign role Id: Assign role Id 3 to Convergence Layer", Powers(payable(primaryLayer))));
        mandateSlots.push(findMandateIdInOrg("Assign Delegate status: Assign delegate status to Convergence Layer", Powers(payable(primaryLayer))));
        mandateSlots.push(findMandateIdInOrg("Register Convergence Layer to Paymaster: Register the new Convergence Layer to the paymaster as a sponsored target, this means gas cost for interacting with the new Convergence Layer can be sponsored by the paymaster", Powers(payable(primaryLayer))));

        // step 2: check if msg.sender has the permissions to run these mandates.
        for (uint i = 0; i < mandateSlots.length; i++) {
            address payable currentOrg = i < 2 ? payable(ideasLayer) : payable(primaryLayer);
            Powers(currentOrg).canCallMandate(msg.sender, mandateSlots[i]); // should return true 
        }

        // step 3a: execute mandate: request new convergence layer. 
        vm.startBroadcast();
        IPowers(ideasLayer).request(mandateSlots[0], abi.encode(), nonce, string.concat("Initiating request new convergence layer"));
        vm.stopBroadcast();

        // step 3b: send request to primary layer:
        // creating proposal. 
        vm.startBroadcast();
        actionIds.push(IPowers(ideasLayer).propose(mandateSlots[1], abi.encode(), nonce, string.concat("Sending request for new convergence layer to primary layer")));
        vm.stopBroadcast();

        // voting on proposal.
        (roleCount, againstVote, forVote, abstainVote) = voteOnProposal(
            ideasLayer,
            mandateSlots[1],
            actionIds[0],
            privateKeys, // note: private keys + msg.sender will vote. 
            nonce, // randomiser
            100 // pass chance in percentage. 
        );

        console2.log("Votes cast for creating convergence layer proposal: ", forVote);
        console2.log("Votes cast against creating convergence layer proposal: ", againstVote);
        console2.log("Votes cast abstaining on creating convergence layer proposal: ", abstainVote);
        console2.log("Total voters: ", roleCount);
    } 

    function deployConvergenceLayer2(address ideasLayer, address primaryLayer, uint256 nonce) public {
        // executing proposal -> request is send to Primary Layer. 
        vm.startBroadcast();
        IPowers(ideasLayer).request(mandateSlots[1], abi.encode(), nonce, string.concat("Executing create convergence layer"));
        vm.stopBroadcast();

        // step 3c: at Primary Layer: assign role ID to convergence layer, assign it a delegate status at Safe & register at paymaster.
        vm.startBroadcast();
        IPowers(primaryLayer).request(mandateSlots[2], abi.encode(), nonce, string.concat("Assigning role ID for convergence layer"));
        IPowers(primaryLayer).request(mandateSlots[3], abi.encode(), nonce, string.concat("Registering convergence layer to paymaster"));
        vm.stopBroadcast(); 
    }
}