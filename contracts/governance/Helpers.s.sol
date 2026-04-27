// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { Script } from "forge-std/Script.sol";
import { console2 } from "forge-std/console2.sol";
import { Configurations } from "@lib/powers-monorepo/solidity/script/Configurations.s.sol";
import { Safe } from "@lib/safe-smart-account/contracts/Safe.sol";
import { ModuleManager } from "@lib/safe-smart-account/contracts/base/ModuleManager.sol";
import { ZKPassportHelper } from "@lib/circuits/src/solidity/src/ZKPassportHelper.sol";
import { PowersTypes } from "@lib/powers-monorepo/solidity/src/interfaces/PowersTypes.sol";
import { Powers } from "@lib/powers-monorepo/solidity/src/Powers.sol";
import { IPowers } from "@lib/powers-monorepo/solidity/src/interfaces/IPowers.sol";
import { Soulbound1155, Soulbound1155Factory } from "@lib/powers-monorepo/solidity/src/helpers/Soulbound1155.sol";
import { PowersFactory } from "@lib/powers-monorepo/solidity/src/helpers/PowersFactory.sol"; 
import { ElectionRegistry } from "@lib/powers-monorepo/solidity/src/helpers/ElectionRegistry.sol";
import { DeploySetup } from "./DeploySetup.s.sol";
import { Governed721 } from "@lib/powers-monorepo/solidity/src/helpers/Governed721.sol";
import { Nominees } from "@lib/powers-monorepo/solidity/src/helpers/Nominees.sol";

// CONINUE HERE // 

contract Helpers is Script {
    Soulbound1155 actvityToken;
    Soulbound1155 meritBadges;
    Governed721 governed721;
    Nominees nominees;
    ElectionRegistry electionRegistry;

    function run() public {
        console2.log("Deploying Organisation's Helper contracts...");
        vm.startBroadcast();
        actvityToken = new Soulbound1155(
            "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafkreighx6axdemwbjara3xhhfn5yaiktidgljykzx3vsrqtymicxxtgvi"
        );
        meritBadges = new Soulbound1155(
            "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafkreighx6axdemwbjara3xhhfn5yaiktidgljykzx3vsrqtymicxxtgvi"
        );
        nominees = new Nominees();
        electionRegistry = new ElectionRegistry();
        governed721 = new Governed721();
        vm.stopBroadcast();
    }

    function getActivityToken() public view returns (address) {
        return address(actvityToken);
    }

    function getMeritBadges() public view returns (address) {
        return address(meritBadges);
    }

    function getNominees() public view returns (address) {
        return address(nominees);
    }

    function getElectionRegistry() public view returns (address) {
        return address(electionRegistry);
    }

    function getGoverned721() public view returns (address) {
        return address(governed721);
    }
 
} 