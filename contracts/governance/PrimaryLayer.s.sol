// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { Script } from "forge-std/Script.sol";
import { console2 } from "forge-std/console2.sol";
import { Configurations } from "@lib/powers-monorepo/solidity/script/Configurations.s.sol";
import { Safe } from "@lib/safe-smart-account/contracts/Safe.sol";
import { ModuleManager } from "@lib/safe-smart-account/contracts/base/ModuleManager.sol";
import { PowersTypes } from "@lib/powers-monorepo/solidity/src/interfaces/PowersTypes.sol";
import { Powers } from "@lib/powers-monorepo/solidity/src/Powers.sol";
import { IPowers } from "@lib/powers-monorepo/solidity/src/interfaces/IPowers.sol";
import { Soulbound1155, Soulbound1155Factory } from "@lib/powers-monorepo/solidity/src/helpers/Soulbound1155.sol";
import { PowersFactory } from "@lib/powers-monorepo/solidity/src/helpers/PowersFactory.sol"; 
import { ElectionRegistry } from "@lib/powers-monorepo/solidity/src/helpers/ElectionRegistry.sol";
import { DeploySetup } from "./DeploySetup.s.sol";
import { SafeProxyFactory } from "@lib/safe-smart-account/contracts/proxies/SafeProxyFactory.sol";
import { PowersPaymaster } from "@lib/powers-monorepo/solidity/src/helpers/PowersPaymaster.sol";
import { IEntryPoint } from "@lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";

contract PrimaryLayer is DeploySetup {
    PowersTypes.Conditions conditions;
    PowersTypes.Flow[] flows;

    PowersTypes.MandateInitData[] constitution; 
    Powers powers; 

    uint16 public requestNewConvergenceLayerId;
    uint16 public requestAllowanceConvergenceLayerId;
    uint16 public requestAllowanceDigitalLayerId;
    uint16 public mintPoapTokenId;
    uint16 public requestParticipantpowersId;

    uint256 i; 
    uint256 j; 
    uint256 packageLength;
    bytes signature;

    //////////////////////////////////////////////////////////////////////
    //                        INITIALISATION                            //
    //////////////////////////////////////////////////////////////////////
    function run() public {
        console2.log("Deploying Primary Layer...");
        vm.startBroadcast();
            powers = new Powers(
                "Primary Layer", // name
                string.concat(baseURI, "primaryLayer.json"), // uri
                helperConfig.getMaxCallDataLength(block.chainid), // max call data length
                helperConfig.getMaxReturnDataLength(block.chainid), // max return data length
                helperConfig.getMaxExecutionsLength(block.chainid) // max executions length
            );
        vm.stopBroadcast();

        console2.log("Primary Layer deployed at:", address(powers));

        // setup Safe treasury.
        address[] memory owners = new address[](1);
        owners[0] = address(powers);

        vm.startBroadcast();
        treasury = address(
            SafeProxyFactory(helperConfig.getSafeProxyFactory(block.chainid))
                .createProxyWithNonce(
                    helperConfig.getSafeL2Canonical(block.chainid),
                    abi.encodeWithSelector(
                        Safe.setup.selector,
                        owners,
                        1, // threshold
                        address(0), // to
                        "", // data
                        address(0), // fallbackHandler
                        address(0), // paymentToken
                        0, // payment
                        address(0) // paymentReceiver
                    ),
                    1 // = nonce
                )
        );
        vm.stopBroadcast();
        console2.log("Safe treasury deployed at:", treasury);

        // deploy paymaster 
        vm.startBroadcast();
        paymaster = address(new PowersPaymaster(
            IEntryPoint(0x0000000071727De22E5E9d8BAf0edAc6f37da032),  // for now hard coded, should be taken from config file later on. 
            address(powers))); 
        vm.stopBroadcast();
        console2.log("Paymaster deployed at:", paymaster);
    }

    //////////////////////////////////////////////////////////////////////
    //                          CONSTITUTE                              //
    //////////////////////////////////////////////////////////////////////
    function constitutePowers(
        address digitalLayer, 
        address ideasLayerFactory, 
        address convergenceLayerFactory, 
        address activityToken,
        address electionRegistry, 
        uint16 assignConvergenceLayerMandateId
        ) public { // add here dependencies. 
        _createConstitution(digitalLayer, ideasLayerFactory, convergenceLayerFactory, activityToken, electionRegistry, assignConvergenceLayerMandateId);
         
        for (i = 0; i < constitution.length; i += PACKAGE_SIZE) {
            packageLength = constitution.length - i < PACKAGE_SIZE ? constitution.length - i : PACKAGE_SIZE;
            PowersTypes.MandateInitData[] memory constitutionPart = new PowersTypes.MandateInitData[](packageLength);
            for (j = 0; j < constitutionPart.length; j++) {
                constitutionPart[j] = constitution[i + j];
            }
            vm.startBroadcast();
            powers.constitute(constitutionPart);
            vm.stopBroadcast();
        } 
        vm.startBroadcast();
        powers.closeConstitute(cedars, flows); // set msg.sender as admin);
        vm.stopBroadcast();        
    }

    //////////////////////////////////////////////////////////////////////
    //                            GETTERS                               //
    //////////////////////////////////////////////////////////////////////
    function getAddress() public view returns (address) {
        return address(powers);
    }

    function getTreasury() public view returns (address) {
        return treasury;
    }

    //////////////////////////////////////////////////////////////////////
    //                        CONSTITUTION                              //
    //////////////////////////////////////////////////////////////////////
    function _createConstitution(
        address digitalLayer, 
        address ideasLayerFactory, 
        address convergenceLayerFactory, 
        address activityToken,
        address electionRegistry, 
        uint16 assignConvergenceLayerMandateId
        ) internal {
        mandateCount = 0;
        
        //////////////////////////////////////////////////////////////////////
        //                              SETUP                               //
        //////////////////////////////////////////////////////////////////////
        // setup calls //
        // signature for Safe module enabling call
        signature = abi.encodePacked(
            uint256(uint160(address(powers))), // r = address of the signer (powers contract)
            uint256(0), // s = 0
            uint8(1) // v = 1 This is a type 1 call. See Safe.sol for details.
        );

        targets = new address[](19);
        values = new uint256[](19);
        calldatas = new bytes[](19);

        for (i = 0; i < 19; i++) {
            targets[i] = address(powers); // all calls have value 0 in this mandate. To transfer Eth, use a different mandate.
        }
        targets[14] = treasury; // override target for treasury setup call.
        targets[15] = treasury; // override target for allowance module setup call.
        targets[16] = paymaster; // override target for paymaster sponsored target setup call.
        targets[17] = paymaster; // override target for paymaster sponsored target setup call.

        calldatas[0] = abi.encodeWithSelector(IPowers.labelRole.selector, 0, "Setup Initiators", "");  
        calldatas[1] = abi.encodeWithSelector(IPowers.labelRole.selector, type(uint256).max, "Public", ""); 
        calldatas[2] = abi.encodeWithSelector(IPowers.labelRole.selector, 1, "Participants", "");
        calldatas[3] = abi.encodeWithSelector(IPowers.labelRole.selector, 2, "Stewards", "");
        calldatas[4] = abi.encodeWithSelector(IPowers.labelRole.selector, 3, "Convergence Layers", "");
        calldatas[5] = abi.encodeWithSelector(IPowers.labelRole.selector, 4, "Ideas Layers", "");
        calldatas[6] = abi.encodeWithSelector(IPowers.labelRole.selector, 5, "Digital Layers", "");
        calldatas[7] = abi.encodeWithSelector(IPowers.assignRole.selector, 1, cedars);
        calldatas[8] = abi.encodeWithSelector(IPowers.assignRole.selector, 1, testAccount1);
        calldatas[9] = abi.encodeWithSelector(IPowers.assignRole.selector, 1, testAccount2);
        // calldatas[8] = abi.encodeWithSelector(IPowers.assignRole.selector, 1, testAccount3);
        calldatas[10] = abi.encodeWithSelector(IPowers.assignRole.selector, 2, cedars);
        calldatas[11] = abi.encodeWithSelector(IPowers.assignRole.selector, 5, digitalLayer);
        calldatas[12] = abi.encodeWithSelector(IPowers.setTreasury.selector, treasury);
        calldatas[13] = abi.encodeWithSelector(IPowers.setPaymaster.selector, paymaster);
        calldatas[14] = abi.encodeWithSelector( // cal to set allowance module to the Safe treasury.
            Safe.execTransaction.selector,
            treasury, // The internal transaction's destination
            0, // The internal transaction's value in this mandate is always 0. To transfer Eth use a different mandate.
            abi.encodeWithSelector( // the call to be executed by the Safe: enabling the module.
                ModuleManager.enableModule.selector,
                helperConfig.getSafeAllowanceModule(block.chainid)
            ),
            0, // operation = Call
            0, // safeTxGas
            0, // baseGas
            0, // gasPrice
            address(0), // gasToken
            address(0), // refundReceiver
            signature // the signature constructed above
        );
        calldatas[15] = abi.encodeWithSelector( // call to set Digital Layer as delegate to the Safe treasury.
            Safe.execTransaction.selector,
            helperConfig.getSafeAllowanceModule(block.chainid), // The internal transaction's destination: the Allowance Module.
            0, // The internal transaction's value in this mandate is always 0. To transfer Eth use a different mandate.
            abi.encodeWithSignature(
                "addDelegate(address)", // == AllowanceModule.addDelegate.selector,  (because the contracts are compiled with different solidity versions we cannot reference the contract directly here)
                digitalLayer
            ),
            0, // operation = Call
            0, // safeTxGas
            0, // baseGas
            0, // gasPrice
            address(0), // gasToken
            address(0), // refundReceiver
            signature // the signature constructed above
        );
        // addSponsoredTarget 
        calldatas[16] = abi.encodeWithSignature("addSponsoredTarget(address)", address(powers));  
        calldatas[17] = abi.encodeWithSignature("addSponsoredTarget(address)", digitalLayer);
        calldatas[18] = abi.encodeWithSelector(IPowers.revokeMandate.selector, mandateCount + 1); // revoke mandate after use.

        mandateCount++;
        conditions.allowedRole = type(uint256).max; // = public.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Initial Setup: Assign role labels and revokes itself after execution",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "PresetActions"),
                config: abi.encode(
                    targets,
                    values,
                    calldatas
                    ),
                conditions: conditions
            })
        );
        delete conditions;

        //////////////////////////////////////////////////////////////////////
        //                      EXECUTIVE MANDATES                          //
        //////////////////////////////////////////////////////////////////////
        // CREATE IDEAS LAYER //
        uint16[] memory mandateIds = new uint16[](7);
        mandateIds[0] = mandateCount + 1;
        mandateIds[1] = mandateCount + 2;
        mandateIds[2] = mandateCount + 3; 
        mandateIds[3] = mandateCount + 4;
        mandateIds[4] = mandateCount + 5;
        mandateIds[5] = mandateCount + 6;
        mandateIds[6] = mandateCount + 7;

        flows.push(PowersTypes.Flow({
            nameDescription: "Create and Revoke Ideas Layers: This flow includes the initiation and execution of the Ideas Layer creation, as well as the assigning of the role id to the new layer. This flow can be triggered by any Participant. It also includes the revoking of an Ideas layer.",
            mandateIds: mandateIds
        }));

        // Participants: Initiate Ideas Layer creation
        mandateCount++;
        conditions.allowedRole = 1; // = Participants
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid)); // = 5 minutes / days
        conditions.succeedAt = 51; // = 51% majority
        conditions.quorum = 5; // = 5% quorum. Note: very low quorum to encourage experimentation.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Initiate Ideas Layer: Initiate creation of Ideas Layer",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "StatementOfIntent"),
                config: abi.encode(),
                conditions: conditions
            })
        );
        delete conditions;

        // Primary Steward: Execute Ideas Layer creation
        mandateCount++;  
        conditions.allowedRole = 2; // = Primary Steward
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid)); // = 5 minutes / days
        conditions.succeedAt = 66; // = 2/3 majority
        conditions.quorum = 66; // = 66% quorum
        conditions.needFulfilled = mandateCount - 1; // need the previous mandate to be fulfilled.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Create Ideas Layer: Execute Ideas Layer creation",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "BespokeAction_Simple"),
                config: abi.encode(
                    address(ideasLayerFactory), // calling the ideas factory
                    bytes4(keccak256("createPowers()")),
                    abi.encode()  
                ),
                conditions: conditions
            })
        );
        delete conditions;

        // Primary Steward: Assign role Id to Ideas Layer //
        mandateCount++;
        conditions.allowedRole = 2; // = Any Steward
        conditions.needFulfilled = mandateCount - 1; // need the previous mandate to be fulfilled.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Assign role Id to layer: Assign role id 4 (Ideas Layer) to the new layer",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "BespokeAction_OnReturnValue"),
                config: abi.encode(
                    address(powers), // target contract
                    IPowers.assignRole.selector, // function selector to call
                    abi.encode(4), // params before (role id 4 = Ideas Layers)
                    abi.encode(), // dynamic params (the input params of the parent mandate)
                    mandateCount - 1, // parent mandate id (the create Ideas Layer mandate)
                    abi.encode() // no params after
                ),
                conditions: conditions
            })
        );
        delete conditions;

        // Primary Steward: Register Ideas layer to paymaster //
        mandateCount++;
        conditions.allowedRole = 2; // = Primary Steward
        conditions.needFulfilled = mandateCount - 2; // Need ideas layer to have been deployed.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Register Ideas Layer to Paymaster: Register the new Ideas Layer to the paymaster as a sponsored target",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "BespokeAction_OnReturnValue"),
                config: abi.encode(
                    paymaster, // target contract
                    bytes4(keccak256("addSponsoredTarget(address)")), // function selector to call
                    abi.encode(), // params before (role id 4 = Ideas Layers)
                    abi.encode(), // dynamic params (the input params of the parent mandate)
                    mandateCount - 2, // parent mandate id (the create Ideas Layer mandate)
                    abi.encode() // no params after
                ),
                conditions: conditions
            })
        );
        delete conditions;

        // REVOKE IDEAS LAYER //
        inputParams = new string[](1);
        inputParams[0] = "address IdeasSubLayer";

        // Participants: Veto Revoke Ideas Layer creation mandate //
        mandateCount++;
        conditions.allowedRole = 1; // = Participants
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid)); // = 5 minutes / days
        conditions.succeedAt = 51; // = 51% majority
        conditions.quorum = 77; // = Note: high threshold.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Veto revoke Ideas Layer: Veto the revoking of an Ideas Layer from Cultural Stewards",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "StatementOfIntent"),
                config: abi.encode(
                    inputParams
                    ),
                conditions: conditions
            })
        );
        delete conditions;

        // Primary Steward: Revoke Ideas Layer (revoke role Id) //
        mandateCount++;
        conditions.allowedRole = 2;
        conditions.quorum = 66;
        conditions.succeedAt = 51;
        conditions.timelock = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid));
        conditions.needNotFulfilled = mandateCount - 1; // need the veto to have NOT been fulfilled.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Revoke role Id: Revoke role id 4 (Ideas Layer) from the layer",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "BespokeAction_Advanced"),
                config: abi.encode(
                    address(powers), // target contract
                    IPowers.revokeRole.selector, // function selector to call
                    abi.encode(4), // params before (role id 4 = Ideas Layers) // the static params
                    inputParams, // the dynamic params (the input params of the parent mandate)
                    abi.encode() // no args after
                ),
                conditions: conditions
            })
        );
        delete conditions;

        // Primary Steward: Revoke Ideas layer from paymaster //
        mandateCount++;
        conditions.allowedRole = 2; // = Primary Steward
        conditions.needFulfilled = mandateCount - 1; // Need ideas layer to have been revoked.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Revoke Ideas Layer from Paymaster: Remove the Ideas Layer from the paymaster's sponsored targets.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "BespokeAction_Advanced"),
                config: abi.encode(
                    paymaster, // target contract
                    bytes4(keccak256("removeSponsoredTarget(address)")), // function selector to call
                    abi.encode(), // params before (role id 4 = Ideas Layers)
                    inputParams, // dynamic params (the input params of the parent mandate)
                    abi.encode() // no params after
                ),
                conditions: conditions
            })
        );
        delete conditions;

        // CREATE CONVERGENCE LAYER // 
        mandateIds = new uint16[](6);
        mandateIds[0] = mandateCount + 1;
        mandateIds[1] = mandateCount + 2;
        mandateIds[2] = mandateCount + 3;
        mandateIds[3] = mandateCount + 4;
        mandateIds[4] = mandateCount + 5;
        mandateIds[5] = mandateCount + 6;

        flows.push(PowersTypes.Flow({
            nameDescription: "Create a Convergence Layer: This flow includes the initiation and execution of the Convergence Layer creation, as well as the assigning of the role id to the new layer and the assigning of delegate status to the new layer for the Safe treasury. This flow can only be triggered by an Ideas Layer.",
            mandateIds: mandateIds
        }));

        // note: an allowance is set when LAYER is created.
        inputParams = new string[](1); 
        inputParams[0] = "address Initiator"; // the address of the admin of the new LAYER

        // Primary Stewards: Veto creation of Convergence Layer.
        mandateCount++;
        conditions.allowedRole = 2; // = Primary Stewards
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid)); // = 5 minutes / days
        conditions.succeedAt = 66; // = 2/3 majority
        conditions.quorum = 66; // = 66% quorum
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Veto creation Convergence Layer: Stewards can veto the creation of a Convergence Layer from an Ideas Layer",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "StatementOfIntent"),
                config: abi.encode(
                    inputParams
                ),
                conditions: conditions
            })
        );
        delete conditions;
        requestNewConvergenceLayerId = mandateCount; // needed for call from ideas layer

        // Ideas Layer: Create Convergence Layer
        mandateCount++; 
        conditions.allowedRole = 4; // = (a single) Ideas Layer
        conditions.timelock = minutesToBlocks(10, helperConfig.getBlocksPerHour(block.chainid)); // = 10 minutes / days. Note: timelock allows for veto to be cast. 
        conditions.needNotFulfilled = mandateCount - 1; // need the previous mandate NOT to be fulfilled.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Create Convergence Layer: Ideas Layers can create a Convergence Layer",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "BespokeAction_Simple"),
                config: abi.encode(
                    address(convergenceLayerFactory), // calling the Convergence factory 
                    bytes4(keccak256("createPowers(address)")), // function selector for createPowers (because the contracts are compiled with different solidity versions we cannot reference the contract directly here)
                    inputParams // address as input param 
                ),
                conditions: conditions
            })
        );
        delete conditions;

        // Primary Steward: Assign role Id to Convergence Layer //
        mandateCount++;
        conditions.allowedRole = 2; // = Any Steward
        conditions.needFulfilled = mandateCount - 1; // need the previous mandate to be fulfilled.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Assign role Id: Assign role Id 3 to Convergence Layer",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "BespokeAction_OnReturnValue"),
                config: abi.encode(
                    address(powers), // target contract
                    IPowers.assignRole.selector, // function selector to call
                    abi.encode(uint16(3)), // params before (role id 4 = Ideas Layers)
                    inputParams, // dynamic params (the input params of the parent mandate)
                    mandateCount - 1, // parent mandate id (the create Ideas Layer mandate)
                    abi.encode() // no params after
                ),
                conditions: conditions
            })
        );
        delete conditions;

        // Primary Steward: Assign Delegate status to Convergence Layer //
        mandateCount++;
        conditions.allowedRole = 2; // = Any Steward
        conditions.needFulfilled = mandateCount - 2; // need the Convergence Layer to have been created.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Assign Delegate status: Assign delegate status at Safe treasury to the Convergence Layer",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "Safe_ExecTransaction_OnReturnValue"),
                config: abi.encode(
                    helperConfig.getSafeAllowanceModule(block.chainid), // target contract
                    bytes4(0xe71bdf41), // == AllowanceModule.addDelegate.selector (because the contracts are compiled with different solidity versions we cannot reference the contract directly here)
                    abi.encode(), // params before (role id 4 = Ideas Layers)
                    inputParams, // dynamic params (the input params of the parent mandate)
                    mandateCount - 2, // parent mandate id (the create Convergence Layer mandate)
                    abi.encode() // no params after
                ),
                conditions: conditions
            })
        );
        delete conditions;

        // Primary Steward: Register Convergence layer to paymaster //
        mandateCount++;
        conditions.allowedRole = 2; // = Primary Steward
        conditions.needFulfilled = mandateCount - 3; // Need convergence layer to have been deployed.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Register Convergence Layer to Paymaster: Register the new Convergence Layer to the paymaster as a sponsored target, this means gas cost for interacting with the new Convergence Layer can be sponsored by the paymaster",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "BespokeAction_OnReturnValue"),
                config: abi.encode(
                    paymaster, // target contract
                    bytes4(keccak256("addSponsoredTarget(address)")), // function selector to call
                    abi.encode(), // params before  
                    inputParams, // dynamic params (the input params of the parent mandate)
                    mandateCount - 3, // parent mandate id (the create Convergence Layer mandate)
                    abi.encode() // no params after
                ),
                conditions: conditions
            })
        );
        delete conditions;

        // Primary Steward: assign convergence role ID to new layer at digital layer.   //
        mandateCount++;
        conditions.allowedRole = 2; // = Primary Steward
        conditions.needFulfilled = mandateCount - 3; // Need convergence layer to have been deployed.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Assign Convergence Layer to Digital Layer: Assign the new Convergence Layer as a sponsored target to the Digital Layer, this means that the Convergence Layer can call functions on the Digital Layer with the paymaster sponsoring the gas cost.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "BespokeAction_OnReturnValue"),
                config: abi.encode(
                    digitalLayer, // target contract
                    bytes4(keccak256("request(uint16,bytes,uint256,string)")), // function selector to call
                    abi.encode(assignConvergenceLayerMandateId), // params before  
                    inputParams, // dynamic params (the input params of the parent mandate)
                    mandateCount - 4, // parent mandate id (the create Convergence Layer mandate)
                    abi.encode(
                        1234, // nonce. 
                        "Assigning new Convergence Layer as a sponsored target to the Digital Layer"
                    ) // params after
                ),
                conditions: conditions
            })
        );
        delete conditions;

        // 

        // REVOKE CONVERGENCE LAYER //
        mandateIds = new uint16[](4);
        mandateIds[0] = mandateCount + 1;
        mandateIds[1] = mandateCount + 2;
        mandateIds[2] = mandateCount + 3;
        mandateIds[3] = mandateCount + 4;

        flows.push(PowersTypes.Flow({
            nameDescription: "Revoke Convergence Layer: This flow includes the vetoing and revoking of a Convergence Layer. The revoking is done by revoking the role id of the Convergence Layer, and revoking the delegate status at the Safe treasury. This flow can be triggered by any Steward, but the veto can only be triggered by Participants.",
            mandateIds: mandateIds
        }));

        // Participants veto revoking convergence LAYER
        inputParams = new string[](2);
        inputParams[0] = "address ConvergenceSubLayer";
        inputParams[1] = "bool removeAllowance";

        mandateCount++;
        conditions.allowedRole = 1; // = Participants
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid)); // = 5 minutes / days
        conditions.succeedAt = 51; // = 51% majority
        conditions.quorum = 77; // = Note: high threshold.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Veto revoke Convergence Layer: Veto the revoking of an Convergence Layer from Cultural Stewards",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "StatementOfIntent"),
                config: abi.encode(inputParams),
                conditions: conditions
            })
        );
        delete conditions;

        // Primary Steward: Revoke Convergence Layer (Revoke Role ID) //
        mandateCount++;
        conditions.allowedRole = 2; // = Primary Steward
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid)); // = 5 minutes / days
        conditions.succeedAt = 51; // = 51% majority
        conditions.quorum = 77; // = Note: high threshold.
        conditions.timelock = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid)); // = 10 minutes timelock before execution.
        conditions.needNotFulfilled = mandateCount - 1; // need the veto to have NOT been fulfilled.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Revoke Role Id: Revoke role Id 3 from Convergence Layer",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "BespokeAction_Advanced"),
                config: abi.encode(
                    address(powers), // target contract
                    IPowers.revokeRole.selector, // function selector to call
                    abi.encode(3), // params before (role id 3 = Convergence Layers) // the static params
                    inputParams, // the dynamic params (the input params of the parent mandate)
                    abi.encode() // no args after
                ),
                conditions: conditions
            })
        );
        delete conditions;

        // Primary Steward: Revoke Convergence Layer (Revoke Delegate status) //
        mandateCount++;
        conditions.allowedRole = 2; // = Primary Steward
        conditions.needFulfilled = mandateCount - 1; // need the assign role to have been fulfilled.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Revoke Delegate status: Revoke delegate status Convergence Layer at the Safe treasury",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "Safe_ExecTransaction"),
                config: abi.encode(
                    inputParams,
                    bytes4(0xdd43a79f), // == AllowanceModule.removeDelegate.selector (because the contracts are compiled with different solidity versions we cannot reference the contract directly
                    helperConfig.getSafeAllowanceModule(block.chainid) // target contract
                ),
                conditions: conditions
            })
        );
        delete conditions;

        // Primary Steward: Revoke Convergence layer from paymaster //
        mandateCount++;
        conditions.allowedRole = 2; // = Primary Steward
        conditions.needFulfilled = mandateCount - 2; // Need convergence layer to have been revoked.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Revoke Convergence Layer from Paymaster: Remove the Convergence Layer from the paymaster's sponsored targets.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "BespokeAction_Advanced"),
                config: abi.encode(
                    paymaster, // target contract
                    bytes4(keccak256("removeSponsoredTarget(address)")), // function selector to call
                    abi.encode(), // params before (role id 4 = Ideas Layers)
                    inputParams, // dynamic params (the input params of the parent mandate)
                    abi.encode() // no params after
                ),
                conditions: conditions
            })
        );
        delete conditions;


        // ASSIGN LEGAL REPRESENTATIVE ROLE TO CONVERGENCE SUB-LAYER //
        mandateIds = new uint16[](4);
        mandateIds[0] = mandateCount + 1;
        mandateIds[1] = mandateCount + 2;
        mandateIds[2] = mandateCount + 3;
        mandateIds[3] = mandateCount + 4;

        flows.push(PowersTypes.Flow({
            nameDescription: "Assign legal representative role to Convergence Layer: This flow includes the proposal and assigning of the legal representative role for the Convergence Layer. To propose a legal representative, an address needs to pass two ZKP checks (age and issuing country of passport) and be proposed by an Ideas Layer. The legal representative can then be assigned by any Steward. This flow can be triggered by any Ideas Layer, but requires the execution of mandates by the Primary Steward, so effectively the Primary Steward have the final say.",
            mandateIds: mandateIds
        }));

        inputParams = new string[](2);
        inputParams[0] = "address ConvergenceSubLayer"; // the address of the Convergence Layer for which the legal representative is being proposed. This is needed to link the mandate to the correct chain, and to be able to reference the LAYER in the next mandate.
        inputParams[1] = "uint16 assignRepMandateId"; // the mandate id of the next mandate (assigning the legal representative role) to link the mandates together.
    
        // anybody: do ZKP check: age > 18 
        mandateCount++;
        conditions.allowedRole = type(uint256).max; // = public. anyone can pass the ZKP check to propose a legal representative for the Convergence Layer.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "ZK-Passport Check Age: Anyone over the age of 18 can propose to be a legal representative for the Convergence Layer",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "ZKPassport_Check"),
                config: abi.encode(
                    inputParams,
                    helperConfig.getZkPassportRootRegistry(block.chainid), // the address of the ZK-Passport root registry contract, which is needed to verify the ZKPs. This is set in the helper config for each chain.
                    60 * 60 * 24 * 90, // the time window in which the ZKP proof needs to have been created. This is three months.  
                    false, // no facematch needed for now 
                    bytes4(keccak256("isAgeAboveOrEqual(uint8)")),  
                    abi.encode(18) // the input for the zkp check (age > 18) 
                    ),
                conditions: conditions
            })
        );
        delete conditions;

        // anybody: do ZKP check: Issuing country passport check: GBR
        mandateCount++;
        conditions.allowedRole = type(uint256).max; // = public. anyone can pass the ZKP check to propose a legal representative for the Convergence Layer.
        conditions.needFulfilled = mandateCount - 1; // need the age check to have been fulfilled.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "ZK-Passport Check Issuing Country: Anyone with a GBR passport can propose to be a legal representative for the Convergence Layer",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "ZKPassport_Check"),
                config: abi.encode(
                    inputParams,
                    helperConfig.getZkPassportRootRegistry(block.chainid), // the address of the ZK-Passport root registry contract, which is needed to verify the ZKPs. This is set in the helper config for each chain.
                    60 * 60 * 24 * 90, // the time window in which the ZKP proof needs to have been created. This is three months.  
                    false, // no facematch needed for now
                    bytes4(keccak256("isIssuingCountryIn(string[])")),
                    abi.encode(["GBR"]) // the input for the zkp check (issuing country = GBR) 
                    ),
                conditions: conditions
            })
        );
        delete conditions;
        
        // Ideas SubLAYER: select one of the people that passed the ZKP check. Note that this can be any of Ideas Layers
        inputParams = new string[](3);
        inputParams[0] = "address ConvergenceSubLayer"; // the address of the Convergence Layer for which the legal representative is being proposed. This is needed to link the mandate to the correct chain, and to be able to reference the LAYER in the next mandate.
        inputParams[1] = "uint16 assignRepMandateId"; // the mandate id of the next mandate (assigning the legal representative role) to link the mandates together.
        inputParams[2] = "address ProposedLegalRep"; // the address proposed as legal
        
        mandateCount++;
        conditions.allowedRole = 4; // = Proposed by a Ideas Layer. can propose a legal representative for the Convergence Layer.
        conditions.needFulfilled = mandateCount - 1; // need both ZKP checks to have been fulfilled.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Propose Legal Representative: Propose an address as legal representative for the Convergence Layer",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "StatementOfIntent"),
                config: abi.encode(inputParams),
                conditions: conditions
            })
        );
        delete conditions;

        // Primary Steward: assign legal rep role at convergence layer. 
        inputParams = new string[](1);
        inputParams[0] = "address ProposedLegalRep"; // the address proposed as legal

        mandateCount++;
        conditions.allowedRole = 2; // = Primary Steward. Any Steward can assign the legal representative role for the Convergence Layer.
        conditions.needFulfilled = mandateCount - 1; // need the proposal of the legal representative to have been fulfilled.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Assign Legal Representative Role: Assign the legal representative role at the Convergence Layer to the proposed address",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "ExternalAction_Flexible"),
                config: abi.encode(inputParams),
                conditions: conditions
            })
        );
        delete conditions;

        // ASSIGN ADDITIONAL ALLOWANCE TO CONVERGENCE LAYER //
        mandateIds = new uint16[](3);
        mandateIds[0] = mandateCount + 1;
        mandateIds[1] = mandateCount + 2;
        mandateIds[2] = mandateCount + 3;

        flows.push(PowersTypes.Flow({
            nameDescription: " Assign additional allowance to a convergence layer: This flow includes the proposal, veto and execution of assigning an additional allowance. Any layer can propose to assign an additional allowance to either layer, but only the Primary Steward can execute it, and only the Participants can veto it.",
            mandateIds: mandateIds
        }));

        // Setting input params for allowance mandates
        inputParams = new string[](5);
        inputParams[0] = "address Sub-Layer";
        inputParams[1] = "address Token";
        inputParams[2] = "uint96 allowanceAmount";
        inputParams[3] = "uint16 resetTimeMin";
        inputParams[4] = "uint32 resetBaseMin";

        // Convergence Layer: Veto additional allowance
        mandateCount++;
        conditions.allowedRole = 3; // = Convergence Layers
        conditions.quorum = 66; // = 66% quorum needed
        conditions.succeedAt = 66; // = 66% majority needed for veto.
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid)); // = number of blocks
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Veto allowance: Veto setting an allowance to a Convergence Layer.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "StatementOfIntent"),
                config: abi.encode(inputParams),
                conditions: conditions
            })
        );
        delete conditions;

        // Convergence Layer: Request additional allowance
        mandateCount++;
        conditions.allowedRole = 3; // = Convergence Layers.
        conditions.needNotFulfilled = mandateCount - 1; // = the veto mandate.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Request additional allowance: Any Convergence Layer can request an allowance from the Safe Treasury.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "StatementOfIntent"),
                config: abi.encode(inputParams),
                conditions: conditions
            })
        );
        delete conditions;
        requestAllowanceConvergenceLayerId = mandateCount; // store the mandate id for Digital Layer allowance veto.

        // Primary Steward: Grant Allowance to Convergence Layer
        mandateCount++;
        conditions.allowedRole = 2; // = Primary Steward.
        conditions.quorum = 30; // = 30% quorum needed
        conditions.succeedAt = 51; // = 51% simple majority needed for assigning and revoking Participants.
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid)); // = number of blocks
        conditions.needFulfilled = mandateCount - 1; // = the proposal mandate.
        conditions.needNotFulfilled = mandateCount - 2; // = the veto mandate.
        conditions.timelock = minutesToBlocks(10, helperConfig.getBlocksPerHour(block.chainid)); // = 10 minutes timelock before execution.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Set Allowance: Execute and set allowance for a Convergence Layer.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "SafeAllowance_Action"),
                config: abi.encode(
                    inputParams,
                    bytes4(0xbeaeb388), // == AllowanceModule.setAllowance.selector (because the contracts are compiled with different solidity versions we cannot reference the contract directly here)
                    helperConfig.getSafeAllowanceModule(block.chainid)
                ),
                conditions: conditions // everythign zero == Only admin can call directly
            })
        );
        delete conditions;

        // ASSIGN ADDITIONAL ALLOWANCE TO DIGITAL LAYER //
        mandateIds = new uint16[](3);
        mandateIds[0] = mandateCount + 1;
        mandateIds[1] = mandateCount + 2;
        mandateIds[2] = mandateCount + 3;

        flows.push(PowersTypes.Flow({
            nameDescription: "Assign additional allowance to a Digital Layer: This flow includes the proposal, veto and execution of assigning an additional allowance. Any layer can propose to assign an additional allowance to either layer, but only the Primary Steward can execute it, and only the Participants can veto it.",
            mandateIds: mandateIds
        }));

        // Convergence Layer: Veto additional allowance
        mandateCount++;
        conditions.allowedRole = 3; // = Convergence Layers
        conditions.quorum = 66; // = 66% quorum needed
        conditions.succeedAt = 66; // = 66% majority needed for veto.
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid)); // = number of blocks
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Veto allowance: Veto setting an allowance to the digital layer.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "StatementOfIntent"),
                config: abi.encode(inputParams),
                conditions: conditions
            })
        );
        delete conditions;

        // Digital Layer: Request additional allowance
        mandateCount++;
        conditions.allowedRole = 5; // = Digital Layer.
        conditions.needNotFulfilled = mandateCount - 1; // = the veto mandate.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Request additional allowance: The Digital Layer can request an allowance from the Safe Treasury.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "StatementOfIntent"),
                config: abi.encode(inputParams),
                conditions: conditions
            })
        );
        delete conditions;
        requestAllowanceDigitalLayerId = mandateCount; // store the mandate id for Convergence Layer allowance veto.

        // Primary Steward: Grant Allowance to Digital Layer
        mandateCount++;
        conditions.allowedRole = 2; // = Primary Steward.
        conditions.quorum = 30; // = 30% quorum needed
        conditions.succeedAt = 51; // = 51% simple majority needed for assigning and revoking Participants.
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid)); // = number of blocks
        conditions.needFulfilled = mandateCount - 1; // = the proposal mandate.
        conditions.needNotFulfilled = mandateCount - 2; // = the veto mandate.
        conditions.timelock = minutesToBlocks(10, helperConfig.getBlocksPerHour(block.chainid)); // = 10 minutes timelock before execution.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Set Allowance: Execute and set allowance for the Digital Layer.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "SafeAllowance_Action"),
                config: abi.encode(
                    inputParams,
                    bytes4(0xbeaeb388), // == AllowanceModule.setAllowance.selector (because the contracts are compiled with different solidity versions we cannot reference the contract directly here)
                    helperConfig.getSafeAllowanceModule(block.chainid)
                ),
                conditions: conditions // everythign zero == Only admin can call directly
            })
        );
        delete conditions;

        // UPDATE URI //
        mandateIds = new uint16[](2);
        mandateIds[0] = mandateCount + 1;
        mandateIds[1] = mandateCount + 2;

        flows.push(PowersTypes.Flow({
            nameDescription: "Update Primary Layer URI: This flow includes the veto and execution of updating the Primary Layer URI. Only Participants can veto, but any Steward can execute the update.",
            mandateIds: mandateIds
        }));


        inputParams = new string[](1);
        inputParams[0] = "string newUri";

        // Participants: Veto update URI
        mandateCount++;
        conditions.allowedRole = 1; // = Participants
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid)); // = 5 minutes / days
        conditions.succeedAt = 51; // = 51% majority
        conditions.quorum = 77; // = Note: high threshold.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Veto update URI: Participants can veto updating the Primary Layer URI",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "StatementOfIntent"),
                config: abi.encode(inputParams),
                conditions: conditions
            })
        );
        delete conditions;

        // Primary Steward: Update URI
        mandateCount++;
        conditions.allowedRole = 2; // = Primary Steward
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid)); // = 5 minutes / days
        conditions.succeedAt = 66; // = 2/3 majority
        conditions.quorum = 66; // = 66% quorum
        conditions.needNotFulfilled = mandateCount - 1; // the previous VETO mandate should not have been fulfilled.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Update URI: Set allowed token for Cultural Stewards",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "BespokeAction_Simple"),
                config: abi.encode(
                    address(powers), // calling the allowed tokens contract
                    IPowers.setUri.selector, // function selector to call
                    inputParams
                ),
                conditions: conditions
            })
        );
        delete conditions;

       
        //////////////////////////////////////////////////////////////////////
        //                      ELECTORAL MANDATES                          //
        //////////////////////////////////////////////////////////////////////

        // CLAIM Participant PRIMARY LAYER // -- on the basis of request at ideas LAYER and POAP ownership.
        mandateIds = new uint16[](4);
        mandateIds[0] = mandateCount + 1;
        mandateIds[1] = mandateCount + 2;
        mandateIds[2] = mandateCount + 3;
        mandateIds[3] = mandateCount + 4; 

        flows.push(PowersTypes.Flow({
            nameDescription: "Claim  and revoke Participant Primary Layer: This flow includes the claiming and revoking of the Participant role at the Primary Layer. To claim the Participant role, an address needs to first express their intent at an Ideas Layer and own a specific POAP that is issued for example during an event organized by the community. The revoking of the Participant role can only be done by the Primary Steward, but it requires a veto from the Participants.",
            mandateIds: mandateIds
        }));

        // Ideas LAYER: request Participant - statement of intent.
        inputParams = new string[](1);
        inputParams[0] = "uint256[] TokenIds";

        mandateCount++;
        conditions.allowedRole = 4; // = ideas layer
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Request Participant Step 1: A forwarded quest to become Participant from an Ideas Layer",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "StatementOfIntent"),
                config: abi.encode( inputParams ),
                conditions: conditions
            })
        );
        delete conditions;
        requestParticipantpowersId = mandateCount;

        mandateCount++;
        conditions.allowedRole = type(uint256).max; // = public
        conditions.needFulfilled = mandateCount - 1; // need the previous mandate to be fulfilled.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Request Participant Step 2: 1 POAP from convergence layer is needed that is not older than 6 months.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "GovernedToken_GatedAccess"),
                config: abi.encode(
                    address(activityToken), // soulbound token contract
                    1, // Participant role Id
                    3, // checks if token is from address that is an Convergence Layer
                    daysToBlocks(180, helperConfig.getBlocksPerHour(block.chainid)), // look back period in blocks = 180 days.
                    1 // number of tokens required
                ),
                conditions: conditions
            })
        );
        delete conditions;

        inputParams = new string[](1);
        inputParams[0] = "address ParticipantAddress";

        // Participants: veto Revoke Participant
        mandateCount++;
        conditions.allowedRole = 1; // = Participants
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid)); // = 5 minutes / days
        conditions.succeedAt = 51; // = 51% majority
        conditions.quorum = 77; // = Note: high threshold.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Veto Revoke Participant: Participants can veto revoking Participant from other Participants.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "StatementOfIntent"),
                config: abi.encode(inputParams),
                conditions: conditions
            })
        );
        delete conditions;

        // Primary Steward: Revoke Participant
        mandateCount++;
        conditions.allowedRole = 2; // = Primary Steward
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid)); // = 5 minutes / days
        conditions.succeedAt = 51; // = 51% majority
        conditions.quorum = 77; // = Note: high threshold.
        conditions.timelock = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid)); // = 10 minutes timelock before execution.
        conditions.needNotFulfilled = mandateCount - 1; // need the veto to have NOT been fulfilled.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Revoke Participant: Primary Steward can revoke Participant from Participants.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "BespokeAction_Advanced"),
                config: abi.encode(
                    address(powers), // target contract
                    IPowers.revokeRole.selector, // function selector to call
                    abi.encode(1), // params before (role id 1 = Participants) // the static params
                    inputParams, // the dynamic params (the input params of the parent mandate)
                    abi.encode() // no args after
                ),
                conditions: conditions
            })
        );
        delete conditions;

        // ELECT PRIMARY STEWARD //
        mandateIds = new uint16[](6);
        mandateIds[0] = mandateCount + 1;
        mandateIds[1] = mandateCount + 2;
        mandateIds[2] = mandateCount + 3;
        mandateIds[3] = mandateCount + 4; 
        mandateIds[4] = mandateCount + 5;
        mandateIds[5] = mandateCount + 6;

        flows.push(PowersTypes.Flow({
            nameDescription: "Elect Primary Steward: This flow includes the creation of an Steward election, opening the vote, tallying the results and cleaning up after the election. Any Participant can trigger this flow, but it requires multiple steps that need to be executed by different roles, so effectively it requires the coordination of both Participants and Primary Steward to successfully elect new Primary Steward.",
            mandateIds: mandateIds
        }));

        // set inputparams for election mandates
        inputParams = new string[](1);
        inputParams[0] = "string Title"; 

        // Participants: create election
        mandateCount++;
        conditions.allowedRole = 1; // = Participants 
        conditions.throttleExecution = minutesToBlocks(7, helperConfig.getBlocksPerHour(block.chainid)); // = once every 7 minutes
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Create an Steward election: an election for the Steward role can be initiated be any Participant. After the election is created, participants have 5 minutes to nominate themselves.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "BespokeAction_Simple"),
                config: abi.encode(
                    electionRegistry, // election list contract
                    ElectionRegistry.createElection.selector, // selector
                    inputParams
                ),
                conditions: conditions
            })
        );
        delete conditions;

        // Participants: Open Vote for election
        mandateCount++;
        conditions.allowedRole = 1; // = Participants
        conditions.needFulfilled = mandateCount - 1; // = Create election
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Open voting for Steward election: After five minutes of initiating an election, participants can open the vote. This will create a dedicated vote mandate. The vote will stay open for five minutes.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "ElectionRegistry_CreateVoteMandate"),
                config: abi.encode(
                    electionRegistry, // election list contract
                    registry.getMandateAddress(MAJOR, MINOR, PATCH, "ElectionRegistry_Vote"), // the vote mandate address
                    1, // the max number of votes a voter can cast
                    1 // the role Id allowed to vote (Participants)
                ),
                conditions: conditions
            })
        );
        delete conditions;

        // Participants: Tally election
        mandateCount++;
        conditions.allowedRole = 1;
        conditions.needFulfilled = mandateCount - 1; // = Open Vote election
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Tally Steward elections: After five minutes of opening the vote, tally the results and assign the Steward role to the winners.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "ElectionRegistry_Tally"),
                config: abi.encode(
                    electionRegistry,
                    2, // RoleId for Primary Steward
                    5 // Max role holders
                ),
                conditions: conditions
            })
        );
        delete conditions;

        // Participants: clean up election
        mandateCount++;
        conditions.allowedRole = 1;
        conditions.needFulfilled = mandateCount - 1; // = Tally Steward election
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Clean up Steward election: After an Steward election has finished, clean up related mandates.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "BespokeAction_OnReturnValue"),
                config: abi.encode(
                    address(powers), // target contract
                    IPowers.revokeMandate.selector, // function selector to call
                    abi.encode(), // params before
                    inputParams, // dynamic params (the input params of the parent mandate)
                    mandateCount - 2, // parent mandate id (the open vote  mandate)
                    abi.encode() // no params after
                ),
                conditions: conditions
            })
        );
        delete conditions; 

        // Participants: Nominate for Steward election
        mandateCount++;
        conditions.allowedRole = 1; // = Participants
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Nominate for election: any Participant can nominate for an election.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "ElectionRegistry_Nominate"),
                config: abi.encode(
                    electionRegistry, // election list contract
                    true // nominate as candidate
                ),
                conditions: conditions
            })
        );
        delete conditions;

        // Participants revoke nomination for Steward election.
        mandateCount++;
        conditions.allowedRole = 1; // = Participants 
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Revoke nomination for election: any Participant can revoke their nomination for an election.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "ElectionRegistry_Nominate"),
                config: abi.encode(
                    electionRegistry, // election list contract
                    false // revoke nomination
                ),
                conditions: conditions
            })
        );
        delete conditions;

        //////////////////////////////////////////////////////////////////////
        //                        REFORM MANDATES                           //
        //////////////////////////////////////////////////////////////////////

        // ADOPT MANDATE //
        mandateIds = new uint16[](9);
        mandateIds[0] = mandateCount + 1;
        mandateIds[1] = mandateCount + 2;
        mandateIds[2] = mandateCount + 3;
        mandateIds[3] = mandateCount + 4;
        mandateIds[4] = mandateCount + 5;
        mandateIds[5] = mandateCount + 6;
        mandateIds[6] = mandateCount + 7;
        mandateIds[7] = mandateCount + 8;
        mandateIds[8] = mandateCount + 9;

        flows.push(PowersTypes.Flow({
            nameDescription: " Adopt Mandate: This flow includes the proposal, veto and execution of adopting a new mandate into the constitution. Any layer can propose to adopt a new mandate into the constitution, but only the Primary Steward can execute it, and the Participants and all layers have veto power over it.",
            mandateIds: mandateIds
        }));

        string[] memory adoptMandatesParams = new string[](2);
        adoptMandatesParams[0] = "address[] mandates";
        adoptMandatesParams[1] = "uint256[] roleIds";

        // Primary Steward: Propose Adopting Mandates
        mandateCount++;
        conditions.allowedRole = 2; // Primary Steward
        // Note: voting time is longer than the voting time for the 
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Initiate mandate adoption: Any Steward can propose adopting new mandates into the organization.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "StatementOfIntent"),
                config: abi.encode(adoptMandatesParams),
                conditions: conditions
            })
        );
        delete conditions;

        uint16 initiateReformId = mandateCount; // Store the ID of the initiate mandate

        // Participants: Veto Adopting Mandates
        mandateCount++;
        conditions.allowedRole = 1; // Participants
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid));
        conditions.succeedAt = 66;
        conditions.quorum = 77;
        conditions.needFulfilled = initiateReformId;
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Veto Adopting Mandates: Participants can veto proposals to adopt new mandates",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "StatementOfIntent"),
                config: abi.encode(adoptMandatesParams),
                conditions: conditions
            })
        );
        delete conditions;
        uint16 vetoParticipantsId = mandateCount;

        // Digital Layer: Veto Adopting Mandates
        mandateCount++;
        conditions.allowedRole = 5; // Digital Layer
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid));
        conditions.succeedAt = 51;
        conditions.quorum = 10;
        conditions.needFulfilled = initiateReformId;
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Veto Adopting Mandates: Digital Layer can veto proposals to adopt new mandates",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "StatementOfIntent"),
                config: abi.encode(adoptMandatesParams),
                conditions: conditions
            })
        );
        delete conditions;
        uint16 vetoDigitalId = mandateCount;

        // Ideas Layers: Veto Adopting Mandates
        mandateCount++;
        conditions.allowedRole = 4; // Ideas Layer
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid));
        conditions.succeedAt = 51;
        conditions.quorum = 10;
        conditions.needFulfilled = initiateReformId;
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Veto Adopting Mandates: Ideas Layer can veto proposals to adopt new mandates",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "StatementOfIntent"),
                config: abi.encode(adoptMandatesParams),
                conditions: conditions
            })
        );
        delete conditions;
        uint16 vetoIdeasId = mandateCount;

        // Convergence Layers: Veto Adopting Mandates
        mandateCount++;
        conditions.allowedRole = 3; // Convergence Layer
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid));
        conditions.succeedAt = 51;
        conditions.quorum = 10;
        conditions.needFulfilled = initiateReformId;
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Veto Adopting Mandates: Convergence Layer can veto proposals to adopt new mandates",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "StatementOfIntent"),
                config: abi.encode(adoptMandatesParams),
                conditions: conditions
            })
        );
        delete conditions;
        uint16 vetoConvergenceId = mandateCount;

        // Checkpoint 1: Primary Steward confirm Participants Veto passed (or timed out without veto)
        mandateCount++;
        conditions.allowedRole = 2; // Primary Steward
        conditions.needFulfilled = initiateReformId;
        conditions.needNotFulfilled = vetoParticipantsId;
        conditions.timelock = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid)); // Match voting period
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Reform Checkpoint 1: Primary Steward confirm Participants did not veto.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "StatementOfIntent"),
                config: abi.encode(adoptMandatesParams),
                conditions: conditions
            })
        );
        delete conditions;
        uint16 checkpoint1Id = mandateCount;

        // Checkpoint 2: Primary Steward confirm Digital Veto passed
        mandateCount++;  
        conditions.allowedRole = 2; // Primary Steward
        conditions.needFulfilled = checkpoint1Id;
        conditions.needNotFulfilled = vetoDigitalId;
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Reform Checkpoint 2: Primary Steward confirm Digital Layer did not veto.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "StatementOfIntent"),
                config: abi.encode(adoptMandatesParams),
                conditions: conditions
            })
        );
        delete conditions;
        uint16 checkpoint2Id = mandateCount;

        // Checkpoint 3: Primary Steward confirm Ideas Veto passed
        mandateCount++;
        conditions.allowedRole = 2; // Primary Steward
        conditions.needFulfilled = checkpoint2Id;
        conditions.needNotFulfilled = vetoIdeasId;
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Reform Checkpoint 3: Primary Steward confirm Ideas Layer did not veto.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "StatementOfIntent"),
                config: abi.encode(adoptMandatesParams),
                conditions: conditions
            })
        );
        delete conditions;
        uint16 checkpoint3Id = mandateCount;

        // Primary Steward: Adopt Mandates (Final Step)
        mandateCount++;
        conditions.allowedRole = 2; // Primary Steward
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid)); 
        conditions.timelock = minutesToBlocks(10, helperConfig.getBlocksPerHour(block.chainid)); // timelock after voting before execution to give organisations the time to veto.
        conditions.succeedAt = 66;
        conditions.quorum = 80;
        conditions.needFulfilled = checkpoint3Id;
        conditions.needNotFulfilled = vetoConvergenceId;
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Adopt new Mandates: Primary Steward can adopt new mandates into the organization",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "Adopt_Mandates"),
                config: abi.encode(),
                conditions: conditions
            })
        );
        delete conditions;

        // MISCELLANEOUS //
        // EXECUTE VETO ON MANDATE ADOPTION AT OTHER SUB-layer //
        inputParams = new string[](2);
        inputParams[0] = "uint16[] MandateId";
        inputParams[1] = "uint256[] roleIds";

        // Executioners: Veto call to Powers instance and mandateIds in other layers
        mandateCount++;
        conditions.allowedRole = 2; // = executioners
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid)); // = 5 minutes / days
        conditions.succeedAt = 51; // = 51% majority
        conditions.quorum = 77; // = Note: high threshold.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Veto Call to sub-layers: Executioners can veto updating the Primary Layer URI",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "ExternalAction_Flexible"),
                config: abi.encode(inputParams),
                conditions: conditions
            })
        );
        delete conditions;

        // MINT NFTs FOR CONVERGENCE SUB-LAYER // 
        mandateCount++;
        conditions.allowedRole = 3; // = Convergence Layers
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Mint token Convergence Layer: Any Convergence Layer can mint new NFTs",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "GovernedToken_MintEncodedToken"),
                config: abi.encode(address(activityToken)),
                conditions: conditions
            })
        );
        delete conditions;
        mintPoapTokenId = mandateCount; // store the mandate id for minting POAP tokens.

        // TRANSFER TOKENS INTO TREASURY //
        mandateCount++;
        conditions.allowedRole = 2; // = Primary Steward. Any Steward can call this mandate.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Transfer tokens to treasury: Any tokens accidently sent to the Primary Layer can be recovered by sending them to the treasury",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "Safe_RecoverTokens"),
                config: abi.encode(
                    treasury, // this should be the safe treasury!
                    helperConfig.getSafeAllowanceModule(block.chainid) // allowance module address
                ),
                conditions: conditions
            })
        );
        delete conditions;

    }
}
