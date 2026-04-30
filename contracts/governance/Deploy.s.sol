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

import { Soulbound1155 } from "@lib/powers-monorepo/solidity/src/helpers/Soulbound1155.sol";
import { Governed721 } from "@lib/powers-monorepo/solidity/src/helpers/Governed721.sol";
import { Nominees } from "@lib/powers-monorepo/solidity/src/helpers/Nominees.sol";
import { ElectionRegistry } from "@lib/powers-monorepo/solidity/src/helpers/ElectionRegistry.sol";
import { PowersFactory } from "@lib/powers-monorepo/solidity/src/helpers/PowersFactory.sol"; 
import { PowersDeployer } from "@lib/powers-monorepo/solidity/src/helpers/PowersDeployer.sol";

import { Helpers } from "./Helpers.s.sol";
import { PrimaryLayer } from "./PrimaryLayer.s.sol";
import { DigitalLayer } from "./DigitalLayer.s.sol";
import { IdeasLayer } from "./IdeasLayer.s.sol";
import { PhysicalLayer } from "./PhysicalLayer.s.sol";

/// @title Cultural Stewards DAO - Deployment Script
/// Note: all days are turned into minutes for testing purposes. These should be changed before production deployment: ctrl-f minutesToBlocks -> daysToBlocks.
contract Deploy is Script {
    PrimaryLayer primaryLayer;
    DigitalLayer digitalLayer;
    IdeasLayer ideasLayerFactory;
    PhysicalLayer physicalLayerFactory;
    Helpers helpers; 
    
    function run() external { 
        // step 0, setup. 
        primaryLayer = new PrimaryLayer();
        digitalLayer = new DigitalLayer();
        ideasLayerFactory = new IdeasLayer();
        physicalLayerFactory = new PhysicalLayer();
        helpers = new Helpers();

        // deploying the core Powers and Powers factory instances: 
        primaryLayer.run();
        digitalLayer.run();
        ideasLayerFactory.run();
        physicalLayerFactory.run();
        helpers.run();

        // constituting the powers instances and powers factories. 
        primaryLayer.constitutePowers(
            digitalLayer.getAddress(),
            ideasLayerFactory.getAddress(),
            physicalLayerFactory.getAddress(),
            helpers.getActivityToken(),
            helpers.getElectionRegistry()
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
            primaryLayer.requestNewPhysicalLayerId()
        );
        physicalLayerFactory.constitutePowers(
            primaryLayer.getAddress(),
            helpers.getGoverned721(),
            helpers.getActivityToken(),
            helpers.getNominees(),
            primaryLayer.mintPoapTokenId(),
            primaryLayer.requestAllowancePhysicalLayerId()

        );

        // step 5: transfer ownership of factories to primary DAO.
        vm.startBroadcast();
        console2.log("Transferring ownership of DAO factories to Primary Layer...");
        Soulbound1155(helpers.getActivityToken()).transferOwnership(primaryLayer.getAddress());
        Governed721(helpers.getGoverned721()).transferOwnership(primaryLayer.getAddress());
        Nominees(helpers.getNominees()).transferOwnership(primaryLayer.getAddress());
        
        vm.stopBroadcast();

        console2.log("Success! All contracts successfully deployed, unpacked and configured.");
    }
}
