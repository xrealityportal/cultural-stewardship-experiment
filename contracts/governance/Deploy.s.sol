// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { Script } from "forge-std/Script.sol";
import { console2 } from "forge-std/console2.sol";
import { Configurations } from "@lib/powers-monorepo/solidity/script/Configurations.s.sol";

import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";
import { SafeProxyFactory } from "@lib/safe-smart-account/contracts/proxies/SafeProxyFactory.sol";
import { Safe } from "@lib/safe-smart-account/contracts/Safe.sol";

import { PowersTypes } from "@lib/powers-monorepo/solidity/src/interfaces/PowersTypes.sol";
import { Powers } from "@lib/powers-monorepo/solidity/src/Powers.sol";
import { IPowers } from "@lib/powers-monorepo/solidity/src/interfaces/IPowers.sol";

import { Soulbound1155 } from "@lib/powers-monorepo/solidity/src/helpers/Soulbound1155.sol";
import { Governed721 } from "@lib/powers-monorepo/solidity/src/helpers/Governed721.sol";
import { Nominees } from "@lib/powers-monorepo/solidity/src/helpers/Nominees.sol";
import { ElectionRegistry } from "@lib/powers-monorepo/solidity/src/helpers/ElectionRegistry.sol";
import { PowersFactory } from "@lib/powers-monorepo/solidity/src/helpers/PowersFactory.sol"; 
import { PowersDeployer } from "@lib/powers-monorepo/solidity/src/helpers/PowersDeployer.sol";
import { PowersPaymaster } from "@lib/powers-monorepo/solidity/src/helpers/PowersPaymaster.sol";

import { Helpers } from "./Helpers.s.sol";
import { Initialise } from "./actions/Initialise.s.sol";
import { PrimaryLayer } from "./PrimaryLayer.s.sol";
import { DigitalLayer } from "./DigitalLayer.s.sol";
import { IdeasLayer } from "./IdeasLayer.s.sol";
import { ConvergenceLayer } from "./ConvergenceLayer.s.sol";

/// @title Cultural Stewards DAO - Deployment Script
/// Note: all days are turned into minutes for testing purposes. These should be changed before production deployment: ctrl-f minutesToBlocks -> daysToBlocks.
contract Deploy is Script {
    PrimaryLayer primaryLayer;
    DigitalLayer digitalLayer;
    IdeasLayer ideasLayerFactory;
    ConvergenceLayer convergenceLayerFactory;
    Helpers helpers; 
    Initialise initialise;

    string[] public ideasLayerNames = ["Seeing", "Making", "Listening", "Telling", "Remembering", "Imagining", "Tending"];
    
    function run() external { 
        // step 1, setup. 
        primaryLayer = new PrimaryLayer();
        digitalLayer = new DigitalLayer();
        ideasLayerFactory = new IdeasLayer();
        convergenceLayerFactory = new ConvergenceLayer();
        helpers = new Helpers();
        initialise = new Initialise();

        uint256[] memory privateKeys = new uint256[](3);
        privateKeys[0] = vm.envUint("TEST_ACCOUNT_KEY_1");
        privateKeys[1] = vm.envUint("TEST_ACCOUNT_KEY_2");
        privateKeys[2] = vm.envUint("TEST_ACCOUNT_KEY_3");

        // step 2, deploying the core Powers and Powers factory instances: 
        primaryLayer.run();
        digitalLayer.run();
        ideasLayerFactory.run();
        convergenceLayerFactory.run();
        helpers.run();

        // step 3, constituting the powers instances and powers factories. 
        primaryLayer.constitutePowers(
            digitalLayer.getAddress(),
            ideasLayerFactory.getAddress(),
            convergenceLayerFactory.getAddress(),
            helpers.getActivityToken(),
            helpers.getElectionRegistry(),
            digitalLayer.getAssignConvergenceLayer()
        );
        digitalLayer.constitutePowers(
            primaryLayer.getAddress(),
            helpers.getElectionRegistry(),
            primaryLayer.requestAllowanceDigitalLayerId()
        );
        ideasLayerFactory.constitutePowers(
            primaryLayer.getAddress(),
            helpers.getElectionRegistry(),
            primaryLayer.getTreasury(),
            primaryLayer.requestParticipantpowersId(),
            primaryLayer.requestNewConvergenceLayerId()
        );
        convergenceLayerFactory.constitutePowers(
            primaryLayer.getAddress(),
            helpers.getGoverned721(),
            helpers.getActivityToken(),
            helpers.getNominees(),
            primaryLayer.mintPoapTokenId(),
            primaryLayer.requestAllowanceConvergenceLayerId()

        );

        // step 4: transfer ownership of factories to Primary Layer.
        vm.startBroadcast();
        console2.log("Transferring ownership of Organisational factories to Primary Layer...");
        Soulbound1155(helpers.getActivityToken()).transferOwnership(primaryLayer.getAddress());
        Governed721(helpers.getGoverned721()).transferOwnership(primaryLayer.getAddress());
        Nominees(helpers.getNominees()).transferOwnership(primaryLayer.getAddress());
        vm.stopBroadcast();
 
        // step 5: run setup on primary and digital layer.
        initialise.runSetupMandate(primaryLayer.getAddress(), block.timestamp);
        initialise.runSetupMandate(digitalLayer.getAddress(), block.timestamp);

        console2.log("Success! All contracts successfully deployed.");
    }
}
