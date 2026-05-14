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
    MandateRegistry registry = MandateRegistry(0x97b66F08Eb857e27A24492D338d3DC484DF63896); 

    address cedars = 0x328735d26e5Ada93610F0006c32abE2278c46211;
    address testAccount1 = vm.addr(vm.envUint("TEST_ACCOUNT_KEY_1"));
    address testAccount2 = vm.addr(vm.envUint("TEST_ACCOUNT_KEY_2"));
    address testAccount3 = vm.addr(vm.envUint("TEST_ACCOUNT_KEY_3"));
    string baseURI = "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafybeibnyrgzok373d4zveasq3jppz62jievfih7yyaiqdgmucwcznhqfa/";
    
    uint256 constitutionLength; 
    address[] targets;
    uint256[] values;
    bytes4[] functionSelectors;
    bytes[] calldatas;
    string[] inputParams;
    string[] dynamicParams;
    uint16 mandateCount;
    address treasury;
    address paymaster; 

    // The mandate version to be used. 
    uint16 constant MAJOR = 0;
    uint16 constant MINOR = 1;
    uint16 constant PATCH = 2;

    uint16 constant PACKAGE_SIZE = 7;  
}

