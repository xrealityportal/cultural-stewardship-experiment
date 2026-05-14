// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { Script } from "forge-std/Script.sol";
import { console2 } from "forge-std/console2.sol";
import { console2 } from "forge-std/console2.sol";
import { DeploySetup } from "./DeploySetup.s.sol";
import { PowersTypes } from "@lib/powers-monorepo/solidity/src/interfaces/PowersTypes.sol";
import { Powers } from "@lib/powers-monorepo/solidity/src/Powers.sol";
import { IPowers } from "@lib/powers-monorepo/solidity/src/interfaces/IPowers.sol";
import { ElectionRegistry } from "@lib/powers-monorepo/solidity/src/helpers/ElectionRegistry.sol"; 
import { PowersFactory } from "@lib/powers-monorepo/solidity/src/helpers/PowersFactory.sol";
import { PowersDeployer } from "@lib/powers-monorepo/solidity/src/helpers/PowersDeployer.sol";

contract IdeasLayer is DeploySetup { 
    PowersTypes.Conditions conditions;
    PowersTypes.Flow[] flows;

    PowersTypes.MandateInitData[] constitution; 
    PowersFactory powersFactory;

    //////////////////////////////////////////////////////////////////////
    //                        INITIALISATION                            //
    //////////////////////////////////////////////////////////////////////
    function run() public { 
        console2.log("Deploying Ideas Layer factory (contract only)...");
        vm.startBroadcast();
        PowersDeployer IdeasLayerDeployer = new PowersDeployer();
        powersFactory = new PowersFactory(
            "Ideas Layer", // name
            string.concat(baseURI, "ideasLayer.json"),
            helperConfig.getMaxCallDataLength(block.chainid), // max call data length
            helperConfig.getMaxReturnDataLength(block.chainid), // max return data length
            helperConfig.getMaxExecutionsLength(block.chainid), // max executions length
            address(IdeasLayerDeployer)
        );
        vm.stopBroadcast();
        console2.log("Ideas Layer factory deployed at:", address(powersFactory));
    }

    //////////////////////////////////////////////////////////////////////
    //                          CONSTITUTE                              //
    //////////////////////////////////////////////////////////////////////
    function constitutePowers(
        address primaryLayer,
        address electionRegistry, 
        address safeTreasury,
        uint16 requestParticipantpowersId,
        uint16 requestNewConvergenceLayerId
    ) public {
        _createConstitution(primaryLayer, electionRegistry, safeTreasury, requestParticipantpowersId, requestNewConvergenceLayerId);
        
        PowersTypes.MandateInitData[] memory constitutionPacked = packageInitData(constitution, PACKAGE_SIZE, 1);
        vm.startBroadcast();
        powersFactory.addMandates(constitutionPacked);
        powersFactory.addFlows(flows);
        powersFactory.transferOwnership(primaryLayer);
        vm.stopBroadcast();
    }

    //////////////////////////////////////////////////////////////////////
    //                            GETTERS                               //
    //////////////////////////////////////////////////////////////////////
    function getAddress() public view returns (address) {
        return address(powersFactory);
    }

    //////////////////////////////////////////////////////////////////////
    //                        CONSTITUTION                              //
    //////////////////////////////////////////////////////////////////////
    function _createConstitution(
        address primaryLayer,
        address electionRegistry,
        address safeTreasury,
        uint16 requestParticipantpowersId,
        uint16 requestNewConvergenceLayerId
    ) internal {
        mandateCount = 4; // resetting mandate count.

        //////////////////////////////////////////////////////////////////////
        //                              SETUP                               //
        //////////////////////////////////////////////////////////////////////
        // setup role labels // 
        calldatas = new bytes[](13);
        calldatas[0] = abi.encodeWithSelector(IPowers.labelRole.selector, 0, "Setup Initiator", "");  
        calldatas[1] = abi.encodeWithSelector(IPowers.labelRole.selector, type(uint256).max, "Public", ""); 
        calldatas[2] = abi.encodeWithSelector(IPowers.labelRole.selector, 1, "Participants", "");
        calldatas[3] = abi.encodeWithSelector(IPowers.labelRole.selector, 2, "Stewards", ""); 
        calldatas[4] = abi.encodeWithSelector(IPowers.labelRole.selector, 3, "Assessors", "");  
        calldatas[5] = abi.encodeWithSelector(IPowers.labelRole.selector, 6, "Primary Layer", "");
        calldatas[6] = abi.encodeWithSelector(IPowers.assignRole.selector, 0, cedars);
        calldatas[7] = abi.encodeWithSelector(IPowers.assignRole.selector, 1, cedars);
        calldatas[8] = abi.encodeWithSelector(IPowers.assignRole.selector, 1, 0xc9ce1DC547C42F66464f5a7f0E3cd60EBf1C5Bd2);
        calldatas[9] = abi.encodeWithSelector(IPowers.assignRole.selector, 2, cedars);
        calldatas[10] = abi.encodeWithSelector(IPowers.assignRole.selector, 3, cedars);
        calldatas[11] = abi.encodeWithSelector(IPowers.assignRole.selector, 6, primaryLayer); 
        calldatas[12] = abi.encodeWithSelector(IPowers.revokeMandate.selector, mandateCount + 1); // revoke mandate 1 after use.

        mandateCount++;
        conditions.allowedRole = type(uint256).max; // = public.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Initial Setup: Assign role labels and revokes itself after execution",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "PresetActions_OnOwnPowers"),
                config: abi.encode(calldatas),
                conditions: conditions
            })
        );
        delete conditions;

        //////////////////////////////////////////////////////////////////////
        //                      EXECUTIVE MANDATES                          //
        //////////////////////////////////////////////////////////////////////
 
        // ASSIGN PARTICIPANT //
        uint16[] memory mandateIds = new uint16[](2);
        mandateIds[0] = mandateCount + 1;
        mandateIds[1] = mandateCount + 2;

        flows.push(PowersTypes.Flow({
            nameDescription: "Assign Participant: This flow allows users to apply for and claim a Participant role based on forum participation.",
            mandateIds: mandateIds
        }));

        // public: apply for Participant
        inputParams = new string[](2);
        inputParams[0] = "address Applicant";
        inputParams[1] = "string ApplicationURI";

        mandateCount++;
        conditions.allowedRole = type(uint256).max; // = Public
        conditions.throttleExecution = minutesToBlocks(10, helperConfig.getBlocksPerHour(block.chainid)); // to avoid spamming, the mandate is throttled.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Apply for Participant role: Anyone can apply for a Participant role to the Ideas Layer by submitting an application.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "StatementOfIntent"),
                config: abi.encode(inputParams),
                conditions: conditions
            })
        );
        delete conditions;

        // Assessors: assess and assign Participant
        mandateCount++;
        conditions.allowedRole = 3; // = Assessors
        conditions.needFulfilled = mandateCount - 1; // need the application to have been submitted.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Assess and Assign Participant: Assessors can assess applications and assign a Participant role to applicants.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "BespokeAction_Advanced"),
                config: abi.encode( 
                    address(0),
                    IPowers.assignRole.selector, // function selector to call
                    abi.encode(1), // params before (role id 1 = Participants) // the static params
                    inputParams, 
                    abi.encode() // no args after
                ),
                conditions: conditions
            })
        );
        delete conditions;

        // REQUEST CREATION NEW CONVERGENCE Layer //
        mandateIds = new uint16[](3);
        mandateIds[0] = mandateCount + 1;
        mandateIds[1] = mandateCount + 2;
        mandateIds[2] = mandateCount + 3;

        flows.push(PowersTypes.Flow({
            nameDescription: "Request new Convergence Layer: This flow includes the initiation by Participants, veto by Assessors, and execution by Stewards to request the creation of a new Convergence Layer.",
            mandateIds: mandateIds
        }));

        inputParams = new string[](1); // no input params, as all params are set in the config of the mandate.
        inputParams[0] = "address Setup Initiator"; // the only input param is the new URI for the convergence layer, which will be used by Stewards when requesting the creation of a new convergence layer.

        // Participants: Initialise request for new convergence layer.
        mandateCount++;
        conditions.allowedRole = 1; // = Participants
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid)); // 5 minutes to vote
        conditions.succeedAt = 51; // simple majority
        conditions.quorum = 5; // low quorum. Many Participants might not be very active.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Request new Convergence Layer: Participants can initiate the request for creating a new Convergence Layer under the Primary Layer",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "StatementOfIntent"),
                config: abi.encode(inputParams),
                conditions: conditions
            })
        );
        delete conditions; 

        // Assessors: Veto request for new convergence layer
        mandateCount++;
        conditions.allowedRole = 3; // = Assessors
        conditions.needFulfilled = mandateCount - 1; // need the previous mandate to be fulfilled (Participants need to have initiated the request for a new convergence layer).
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Veto request for new Convergence Layer: Assessors can veto the request for creating a new Convergence Layer under the Primary Layer.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "StatementOfIntent"),
                config: abi.encode(inputParams),
                conditions: conditions
            })
        );
        delete conditions;

        // Stewards: request at Primary Layer the creation of a new convergence layer.
        // Note: this is a statement of intent. Convergence layers are requested using a working group, after initated here by Stewards.
        mandateCount++;
        conditions.allowedRole = 2; // = Stewards
        conditions.quorum = 51; // simple majority
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid)); // 10 minutes to vote
        conditions.succeedAt = 51; // simple majority
        conditions.needFulfilled = mandateCount - 2; // need the Participants to have initiated the request for a new convergence layer.
        conditions.needNotFulfilled = mandateCount - 1; // need the Assessors to NOT have vetoed the request for a new convergence layer.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Send request: Stewards can send the request to create a new Convergence Layer to the Primary Layer",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "ExternalAction_Simple"),
                config: abi.encode( 
                    primaryLayer,
                    requestNewConvergenceLayerId, // parent mandate id (the create new convergence layer at Primary Layer mandate)
                    "Requesting creation of new Convergence Layer from Primary Layer", // description
                    inputParams
                ),
                conditions: conditions
            })
        );
        delete conditions;
        // uint16 requestNewConvergenceLayerWorkingGroupMandateId = mandateCount;

        // REVOKE PARTICIPANT //
        mandateIds = new uint16[](2);
        mandateIds[0] = mandateCount + 1;
        mandateIds[1] = mandateCount + 2;

        flows.push(PowersTypes.Flow({
            nameDescription: "Revoke Participant: This flow allows Assessors to revoke Participant, Participants have a veto and can block the revocation.",
            mandateIds: mandateIds
        }));

        // Assessors can revoke Participant following bad behaviour on forum etc.
        // Participants: veto Revoke Participant
        mandateCount++;
        conditions.allowedRole = 1; // = Participants
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid)); // = 5 minutes / days
        conditions.succeedAt = 51; // = 51% majority
        conditions.quorum = 77; // = Note: high threshold.
        conditions.needFulfilled = mandateCount - 1; // need the revoke Participant mandate to have been fulfilled for the veto to be valid.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Veto Revoke Participant: Participants can veto revoking Participant Role.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "StatementOfIntent"),
                config: abi.encode(inputParams),
                conditions: conditions
            })
        );
        delete conditions;

        // Assessors: Revoke Participant
        // Note: even though the inputParams also have the URI included (which is not needed for revoking Participant), we keep the same inputParams for both the assign and revoke mandate, as the excess params will simply be ignored.
        mandateCount++;
        conditions.allowedRole = 3; // = Assessors
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid)); // = 5 minutes / days
        conditions.succeedAt = 51; // = 51% majority
        conditions.quorum = 77; // = Note: high threshold.
        conditions.timelock = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid)); // = 10 minutes timelock before execution.
        conditions.needNotFulfilled = mandateCount - 1; // need the veto to have NOT been fulfilled.
        conditions.needFulfilled = mandateCount - 2; // need the revoke Participant mandate to have been fulfilled.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Revoke Participant: Assessors can revoke Participant role from an account.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "BespokeAction_Advanced"),
                config: abi.encode( 
                    address(0), // target is its own powers contract
                    IPowers.revokeRole.selector, // function selector to call
                    abi.encode(1), // params before (role id 1 = Participants) // the static params
                    inputParams, // the dynamic params (the input params of the parent mandate)
                    abi.encode() // no args after
                ),
                conditions: conditions
            })
        );
        delete conditions;

        // REQUEST TO BECOME PARTICIPANT AT PRIMARY LAYER //
        mandateIds = new uint16[](2);
        mandateIds[0] = mandateCount + 1;
        mandateIds[1] = mandateCount + 2;

        flows.push(PowersTypes.Flow({
            nameDescription: "Request Participant role at Primary Layer: This flow allows Participants to apply for Participant role in the Primary Layer and Assessors to approve and forward the request.",
            mandateIds: mandateIds
        }));

        inputParams = new string[](1);
        inputParams[0] = "uint256[] TokenIds";

        // Participants: apply for Participant role of Primary Layer. 
        mandateCount++;
        conditions.allowedRole = 1; // = Participants
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Apply for Participant role of Primary Layer: Participants can apply for Participant role of the Primary Layer by submitting a request with their POAPs.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "StatementOfIntent"),
                config: abi.encode(inputParams),
                conditions: conditions
            })
        );
        delete conditions;

        // Assessors: ok and send request to Primary Layer. 
        mandateCount++;
        conditions.allowedRole = 3; // = Assessors
        conditions.needFulfilled = mandateCount - 1; // need the application to have been submitted.
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid)); // 5 minutes to vote
        conditions.succeedAt = 51; // simple majority
        conditions.quorum = 10; // low quorum.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Request Participant role of Primary Layer: Assessors can ok requests for Participant role of the Primary Layer and send them to the Primary Layer for assessment.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "ExternalAction_Simple"),
                config: abi.encode( 
                    primaryLayer,
                    requestParticipantpowersId, // parent mandate id (the request Participant of Primary Layer mandate)
                    "Requesting Participant of Primary Layer", // description
                    inputParams
                ),
                conditions: conditions
            })
        ); 
        delete conditions;

        // ASSIGN ASSESSORS //
        mandateIds = new uint16[](2);
        mandateIds[0] = mandateCount + 1;
        mandateIds[1] = mandateCount + 2;

        flows.push(PowersTypes.Flow({
            nameDescription: "Assign Assessor Role: This flow allows Participants to veto and Stewards to assign the Assessor role.",
            mandateIds: mandateIds
        }));

        inputParams = new string[](1);
        inputParams[0] = "address Account";
        
        // Participants: veto assigning Assessor role.
        mandateCount++;
        conditions.allowedRole = 1; // = Participants
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid)); // = 5 minutes / days
        conditions.succeedAt = 51; // = 51% majority
        conditions.quorum = 70; // = Note: high threshold.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Veto Assign Assessor Role: Participants can veto assigning the Assessor role to an account.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "StatementOfIntent"),
                config: abi.encode(inputParams),
                conditions: conditions
            })
        );
        delete conditions;

        // Stewards: assign Assessor role.
        mandateCount++;
        conditions.allowedRole = 2; // = Stewards
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid)); // = 5 minutes / days
        conditions.succeedAt = 51; // = simple majority
        conditions.quorum = 30; // = relatively low threshold.
        conditions.needNotFulfilled = mandateCount - 1; // need the veto to have NOT been fulfilled.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Assign Assessor Role: Stewards can assign the Assessor role to an account.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "BespokeAction_Advanced"),
                config: abi.encode( 
                    address(0), // target is its own powers contract
                    IPowers.assignRole.selector, // function selector to call
                    abi.encode(3), // params before (role id 3 = Assessors) // the static params
                    inputParams, // the dynamic params (the input params of the parent mandate)
                    abi.encode() // no args after
                ),
                conditions: conditions
            })
        );
        delete conditions;

        // REVOKE ASSESSORS //
        mandateIds = new uint16[](2);
        mandateIds[0] = mandateCount + 1;
        mandateIds[1] = mandateCount + 2;

        flows.push(PowersTypes.Flow({
            nameDescription: "Revoke Assessor Role: This flow allows Participants to veto and Stewards to revoke the Assessor role.",
            mandateIds: mandateIds
        }));

        // Participants: veto revoking Assessor role.
        mandateCount++;
        conditions.allowedRole = 1; // = Participants
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid)); // = 5 minutes / days
        conditions.succeedAt = 51; // = 51% majority
        conditions.quorum = 70; // = Note: high threshold.
        conditions.needFulfilled = mandateCount - 1; // The Assessor needs to have been assigned in the first place..
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Veto Revoke Assessor Role: Participants can veto revoking the Assessor role from an account.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "StatementOfIntent"),
                config: abi.encode(inputParams),
                conditions: conditions
            })
        );
        delete conditions;

        // Stewards: revoke Assessor role.
        mandateCount++;
        conditions.allowedRole = 2; // = Stewards
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid)); // = 5 minutes / days
        conditions.succeedAt = 51; // = simple majority
        conditions.quorum = 30; // = relatively low threshold.
        conditions.needNotFulfilled = mandateCount - 1; // need the veto to have NOT been fulfilled.
        conditions.needFulfilled = mandateCount - 2; // The Assessor role needs to have been assigned.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Revoke Assessor Role: Stewards can revoke the Assessor role from an account.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "BespokeAction_Advanced"),
                config: abi.encode( 
                    address(0), // target is its own powers contract
                    IPowers.revokeRole.selector, // function selector to call
                    abi.encode(3), // params before (role id 3 = Assessors) // the static params
                    inputParams, // the dynamic params (the input params of the parent mandate)
                    abi.encode() // no args after
                ),
                conditions: conditions
            })
        );
        delete conditions;

        // ELECT STEWARDS //
        mandateIds = new uint16[](6);
        mandateIds[0] = mandateCount + 1;
        mandateIds[1] = mandateCount + 2;
        mandateIds[2] = mandateCount + 3;
        mandateIds[3] = mandateCount + 4;
        mandateIds[4] = mandateCount + 5;
        mandateIds[5] = mandateCount + 6;

        flows.push(PowersTypes.Flow({
            nameDescription: "Elect Stewards: This flow includes the creation, voting, tallying, and cleanup of an election for the Steward role.",
            mandateIds: mandateIds
        }));

        inputParams = new string[](1);
        inputParams[0] = "string Title"; 

        // Participants: create election
        mandateCount++;
        conditions.allowedRole = 1; // = Participants
        conditions.throttleExecution = minutesToBlocks(120, helperConfig.getBlocksPerHour(block.chainid)); // = once every 2 hours
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Create a Steward election: an election for the Steward role can be initiated by any Participant. The election will be open for 5 minutes.",
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

        // Participants: Open Vote for Steward election
        mandateCount++;
        conditions.allowedRole = 1; // = Participants
        conditions.needFulfilled = mandateCount - 1; // = Create Steward election
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Open voting for Steward election: After five minutes of initiating an election, Participants can open the vote for a Steward election. This will create a dedicated vote mandate.",
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
                    2, // RoleId for Stewards
                    3 // Max role holders
                ),
                conditions: conditions
            })
        );
        delete conditions;

        // Participants: clean up Steward election
        mandateCount++;
        conditions.allowedRole = 1;
        conditions.needFulfilled = mandateCount - 1; // = Tally Steward election
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Clean up Steward election: After five minutes of tallying the results, clean up related mandates.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "ElectionRegistry_CleanUpVoteMandate"),
                config: abi.encode(uint16(mandateCount - 2)), // The create vote mandate)
                conditions: conditions
            })
        );
        delete conditions; 

        // Participants: Nominate for Executive election
        mandateCount++;
        conditions.allowedRole = 1; // = Participants (should be Stewards according to MD, but code says Participants)
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

        // Participants revoke nomination for Executive election.
        mandateCount++;
        conditions.allowedRole = 1; // = Participants (should be Stewards according to MD, but code says Participants) 
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

        // ADOPT MANDATES //
        mandateIds = new uint16[](2);
        mandateIds[0] = mandateCount + 1;
        mandateIds[1] = mandateCount + 2;

        flows.push(PowersTypes.Flow({
            nameDescription: "Adopt Mandates: This flow allows for the adoption of new mandates, initiated by Stewards and subject to veto by Participants.",
            mandateIds: mandateIds
        }));

        // Adopt mandate //
        inputParams = new string[](2);
        inputParams[0] = "address[] mandates";
        inputParams[1] = "uint256[] roleIds";

        // Participants: Veto Adopting Mandates
        mandateCount++;
        conditions.allowedRole = 1; // Participants
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid));
        conditions.succeedAt = 66;
        conditions.quorum = 77;
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Veto Adopting Mandates: Participants can veto proposals to adopt new mandates",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "StatementOfIntent"),
                config: abi.encode(inputParams),
                conditions: conditions
            })
        );
        delete conditions;

        // Stewards: Adopt Mandates
        mandateCount++;
        conditions.allowedRole = 2; // Stewards
        conditions.needNotFulfilled = mandateCount - 1;
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid));
        conditions.succeedAt = 66;
        conditions.quorum = 80;
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Adopt new Mandates: Stewards can adopt new mandates into the organization",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "Adopt_Mandates"),
                config: abi.encode(),
                conditions: conditions
            })
        );
        delete conditions;

        // MISCELLANEOUS (NOT IN A FLOW) //
        // UPDATE URI //
        inputParams = new string[](1);
        inputParams[0] = "string newUri";

        // Stewards: Update URI
        mandateCount++;
        conditions.allowedRole = 2; // = Stewards
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid)); // = 5 minutes / days
        conditions.succeedAt = 66; // = 2/3 majority
        conditions.quorum = 66; // = 66% quorum
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Update URI: Set allowed token for Convergence Layer",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "BespokeAction_Simple"),
                config: abi.encode(
                    address(0), // target address is its own powers contract
                    Powers.setUri.selector, // function selector to call
                    inputParams
                ),
                conditions: conditions
            })
        );
        delete conditions;

        // TRANSFER TOKENS INTO TREASURY //
        mandateCount++;
        conditions.allowedRole = 2; // = Stewards. Any Steward can call this mandate.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Transfer tokens to treasury: Any tokens accidently sent to the Ideas Layer can be recovered by sending them to the treasury",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, "Safe_RecoverTokens"),
                config: abi.encode(
                    safeTreasury, // this should be the safe treasury!
                    helperConfig.getSafeAllowanceModule(block.chainid) // allowance module address
                ),
                conditions: conditions
            })
        );
        delete conditions;

    }
}
