// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { Script } from "forge-std/Script.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { console2 } from "forge-std/console2.sol";
import { Configurations } from "@lib/powers-monorepo/solidity/script/Configurations.s.sol";

import { PowersTypes } from "@lib/powers-monorepo/solidity/src/interfaces/PowersTypes.sol";
import { Powers } from "@lib/powers-monorepo/solidity/src/Powers.sol";
import { IPowers } from "@lib/powers-monorepo/solidity/src/interfaces/IPowers.sol";
import { IMandate } from "@lib/powers-monorepo/solidity/src/interfaces/IMandate.sol";

contract ActionHelpers is Script { 
    Configurations helperConfig = new Configurations();

    //////////////////////////////////////////////////////////////////////////////////
    //                             Helper Functions                                 //
    //////////////////////////////////////////////////////////////////////////////////  
    // NB: the name + description needs to exactly match the name + description of the mandate in order to find the correct mandate ID.  
    function findMandateIdInOrg(string memory description, Powers org) public view returns (uint16) {
        uint16 counter = org.mandateCounter();
        for (uint16 i = 1; i < counter; i++) {
            (address mandateAddress, , ) = org.getAdoptedMandate(i);
            string memory mandateDesc = IMandate(mandateAddress).getNameDescription(address(org), i);
            if (Strings.equal(mandateDesc, description)) {
                return i;
            }
        }
        revert(string.concat("Mandate not found: ", description));
    }

    function calculateActionId(uint16 mandateId, bytes memory mandateCalldata, uint256 nonce) public pure returns (uint256) {
        return uint256(keccak256(abi.encode(mandateId, mandateCalldata, nonce)));
    }

    function voteOnProposal(
        address organisation,
        uint16 mandateToVoteOn,
        uint256 actionIdLocal,
        uint256[] memory privateKeys,
        uint256 randomiser,
        uint256 passChance // in percentage
    )
        public
        returns (uint256 roleCountLocal, uint256 againstVoteLocal, uint256 forVoteLocal, uint256 abstainVoteLocal)
    {
        uint256 currentRandomiser;
        for (uint256 i = 0; i < privateKeys.length; i++) {
            // set randomiser..
            if (currentRandomiser < 10) {
                currentRandomiser = randomiser;
            } else {
                currentRandomiser = currentRandomiser / 10;
            } 
            address voter = vm.addr(privateKeys[i]); // msg.sender will also vote, so we add them to the end of the list of private keys.
            // vote
            console2.log("Voter: ", voter);
            if (Powers(payable(organisation)).canCallMandate(voter, mandateToVoteOn)) {
                roleCountLocal++; 
                if (currentRandomiser % 100 >= passChance) {
                    vm.startBroadcast(privateKeys[i]);
                    Powers(payable(organisation)).castVote(actionIdLocal, 0); // = against
                    vm.stopBroadcast();
                    againstVoteLocal++;
                } else if (currentRandomiser % 100 < passChance) {
                    vm.startBroadcast(privateKeys[i]);
                    Powers(payable(organisation)).castVote(actionIdLocal, 1); // = for
                    vm.stopBroadcast();
                    forVoteLocal++;
                } else {
                    vm.startBroadcast(privateKeys[i]);
                    Powers(payable(organisation)).castVote(actionIdLocal, 2); // = abstain
                    vm.stopBroadcast();
                    abstainVoteLocal++;
                } 
            }
        }
        // msg.sender will always vote for, to ensure that the proposal is executed.
        if (Powers(payable(organisation)).canCallMandate(msg.sender, mandateToVoteOn)) {
            roleCountLocal++;
            forVoteLocal++;
        }
        vm.startBroadcast();
        Powers(payable(organisation)).castVote(actionIdLocal, 1); // = for
        vm.stopBroadcast();
    }
}