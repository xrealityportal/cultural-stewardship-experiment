// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { Script } from "forge-std/Script.sol";
import { console2 } from "forge-std/console2.sol";  

import { PowersTypes } from "@lib/powers-monorepo/solidity/src/interfaces/PowersTypes.sol";
import { Powers } from "@lib/powers-monorepo/solidity/src/Powers.sol";
import { PowersFactory } from "@lib/powers-monorepo/solidity/src/helpers/PowersFactory.sol";  
import { DeployHelpers } from "@lib/powers-monorepo/solidity/governance/DeployHelpers.s.sol";
import { Configurations } from "@lib/powers-monorepo/solidity/script/Configurations.s.sol";

import { ElectionRegistry } from "@lib/powers-monorepo/solidity/src/helpers/ElectionRegistry.sol";
import { Soulbound1155 } from "@lib/powers-monorepo/solidity/src/helpers/Soulbound1155.sol";
import { MandateRegistry } from "@lib/powers-monorepo/solidity/src/helpers/MandateRegistry.sol";

abstract contract DeploySetup is DeployHelpers {
    Configurations helperConfig = new Configurations();
    MandateRegistry registry = MandateRegistry(helperConfig.getMandateRegistry(block.chainid)); 

    address cedars = 0x328735d26e5Ada93610F0006c32abE2278c46211;
    address testAccount1 = 0xEA223f81D7E74321370a77f1e44067bE8738B627;
    address testAccount2 = 0x1bFdB91B283d7Ec24012d7ff5A5B29005140D09a;
    address testAccount3 = 0x49fCf1DD685F6b5F88d9b0a972Dbf80Ee8846234;
    string baseURI = "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafybeic2riafj6r6zzbrhewhe6q4l7jpw7u5mj32q55xcvfxwxyupgjffu/";
    
    uint256 constitutionLength; 
    address[] targets;
    uint256[] values;
    bytes4[] functionSelectors;
    bytes[] calldatas;
    string[] inputParams;
    string[] dynamicParams;
    uint16 mandateCount;
    address treasury;

    // The mandate version to be used. 
    uint16 constant MAJOR = 0;
    uint16 constant MINOR = 6;
    uint16 constant PATCH = 2;
    bool constant IS_STRICT = false;

    uint16 constant PACKAGE_SIZE = 15; // for packaging constitution proposals into multiple mandates if they exceed the block gas limit. This is a temporary solution and should be replaced with a more robust solution before production deployment.
}

