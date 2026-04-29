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

// NB NOTES - the logic should be the following: 
// Roles should reflect roles in github repo: 
// keeping them alligned through social pressure.
// Rage quit option by forking repo and reassigning repo to Powers.  
// Participation assigned through github contribs + steward approval. 

contract DigitalLayer is DeploySetup {
    PowersTypes.Conditions conditions;
    PowersTypes.Flow[] flows;

    PowersTypes.MandateInitData[] constitution; 
    Powers powers; 

    //////////////////////////////////////////////////////////////////////
    //                        INITIALISATION                            //
    //////////////////////////////////////////////////////////////////////
    function run() public {
        console2.log("Deploying Digital Layer...");
        vm.startBroadcast();
            powers = new Powers(
                "Digital Layer", // name
                string.concat(baseURI, "digitalLayer.json"),
                helperConfig.getMaxCallDataLength(block.chainid), // max call data length
                helperConfig.getMaxReturnDataLength(block.chainid), // max return data length
                helperConfig.getMaxExecutionsLength(block.chainid) // max executions length
            );
        vm.stopBroadcast();

        console2.log("Digital Layer deployed at:", address(powers));
    }

    //////////////////////////////////////////////////////////////////////
    //                          CONSTITUTE                              //
    //////////////////////////////////////////////////////////////////////
    function constitutePowers(
        address PrimaryLayer,
        address electionRegistry, 
        uint16 requestAllowanceDigitalLayerId
    ) public {
        _createConstitution(PrimaryLayer, electionRegistry, requestAllowanceDigitalLayerId);
        
        for (uint256 i = 0; i < constitution.length; i += PACKAGE_SIZE) {
            uint256 packageLength = constitution.length - i < PACKAGE_SIZE ? constitution.length - i : PACKAGE_SIZE;
            PowersTypes.MandateInitData[] memory constitutionPart = new PowersTypes.MandateInitData[](packageLength);
            for (uint256 j = 0; j < constitutionPart.length; j++) {
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

    //////////////////////////////////////////////////////////////////////
    //                        CONSTITUTION                              //
    //////////////////////////////////////////////////////////////////////
    function _createConstitution(
        address PrimaryLayer,
        address electionRegistry,
        uint16 requestAllowanceDigitalLayerId
    ) internal {
        mandateCount = 0; // resetting mandate count.

        //////////////////////////////////////////////////////////////////////
        //                              SETUP                               //
        //////////////////////////////////////////////////////////////////////
        calldatas = new bytes[](10);
        calldatas[0] = abi.encodeWithSelector(IPowers.labelRole.selector, 0, "Setup Initiator", "");  
        calldatas[1] = abi.encodeWithSelector(IPowers.labelRole.selector, type(uint256).max, "Public", ""); 
        calldatas[2] = abi.encodeWithSelector(IPowers.labelRole.selector, 1, "Participants", ""); 
        calldatas[3] = abi.encodeWithSelector(IPowers.labelRole.selector, 2, "Repository Setup Initiators", "");  // £todo: update metadata 
        calldatas[4] = abi.encodeWithSelector(IPowers.labelRole.selector, 6, "Primary Layer", ""); 
        calldatas[5] = abi.encodeWithSelector(IPowers.assignRole.selector, 1, cedars);
        calldatas[6] = abi.encodeWithSelector(IPowers.assignRole.selector, 2, cedars);
        calldatas[7] = abi.encodeWithSelector(IPowers.assignRole.selector, 3, cedars);
        calldatas[8] = abi.encodeWithSelector(IPowers.assignRole.selector, 6, PrimaryLayer);
        calldatas[9] = abi.encodeWithSelector(IPowers.revokeMandate.selector, mandateCount + 1); // revoke mandate 1 after use.

        mandateCount++;
        conditions.allowedRole = type(uint256).max; // = public.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Initial Setup: Assign role labels and revokes itself after execution",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "PresetActions_OnOwnPowers"),
                config: abi.encode(calldatas),
                conditions: conditions
            })
        );
        delete conditions;

        //////////////////////////////////////////////////////////////////////
        //                      EXECUTIVE MANDATES                          //
        //////////////////////////////////////////////////////////////////////

        // REQUEST ALLOWANCES FROM PRIME DAO //
        uint16[] memory mandateIds = new uint16[](2);
        mandateIds[0] = mandateCount + 1;
        mandateIds[1] = mandateCount + 2;

        flows.push(PowersTypes.Flow({
            nameDescription: "Request Allowances from Prime DAO: This flow includes the veto and request of allowances from the Primary Layer.",
            mandateIds: mandateIds
        }));

        inputParams = new string[](5);
        inputParams[0] = "address Sub-DAO";
        inputParams[1] = "address Token";
        inputParams[2] = "uint96 allowanceAmount";
        inputParams[3] = "uint16 resetTimeMin";
        inputParams[4] = "uint32 resetBaseMin";
 
        // Participants: Veto request allowance from Primary Layer
        mandateCount++;
        conditions.allowedRole = 1; // Participants 
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Veto request allowance: Participants can veto a request for additional allowance", //
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "StatementOfIntent"),
                config: abi.encode(inputParams),
                conditions: conditions
            })
        );
        delete conditions;

        // Repository admins: Request allowance from Primary Layer
        mandateCount++;
        conditions.allowedRole = 2; // Repository admins 
        conditions.needNotFulfilled = mandateCount - 1;
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid));
        conditions.succeedAt = 66;
        conditions.quorum = 80;
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Request allowance: Repository admins can request an allowance from the Primary Layer Safe Treasury.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "ExternalAction_Simple"),
                config: abi.encode(
                    address(PrimaryLayer), // target contract
                    requestAllowanceDigitalLayerId, // parent mandate id (the request allowance at primary DAO mandate)
                    "Requesting allowance from Primary Layer Safe Treasury",
                    inputParams // dynamic params (the input params of the parent mandate)
                ),
                conditions: conditions
            })
        );
        delete conditions;

        // PAYMENT OF RECEIPTS //
        mandateIds = new uint16[](3);
        mandateIds[0] = mandateCount + 1;
        mandateIds[1] = mandateCount + 2;
        mandateIds[2] = mandateCount + 3;

        flows.push(PowersTypes.Flow({
            nameDescription: "Payment of Receipts: This flow includes the submission, oking, and approval of receipts for payment reimbursement.",
            mandateIds: mandateIds
        }));

        inputParams = new string[](3);
        inputParams[0] = "address Token";
        inputParams[1] = "uint256 Amount";
        inputParams[2] = "address PayableTo";

        // Public: Submit a receipt (Payment Reimbursement - After Action)
        mandateCount++;
        conditions.allowedRole = type(uint256).max; // This is a public mandate. Anyone can call it.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Submit a Receipt: Anyone can submit a receipt for payment reimbursement.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "StatementOfIntent"),
                config: abi.encode(inputParams),
                conditions: conditions
            })
        );
        delete conditions;

        // Repository admins: OK Receipt (Avoid Spam)
        mandateCount++;
        conditions.allowedRole = 2; // Any convener can ok a receipt.
        conditions.needFulfilled = mandateCount - 1; // need the previous mandate to be fulfilled.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "OK a receipt: Any convener can ok a receipt for payment reimbursement.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "StatementOfIntent"),
                config: abi.encode(inputParams),
                conditions: conditions
            })
        );
        delete conditions;

        // Repository admins: Approve Payment of Receipt
        mandateCount++;
        conditions.allowedRole = 2; // Repository admins
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid));
        conditions.succeedAt = 67;
        conditions.quorum = 50;
        conditions.needFulfilled = mandateCount - 1; // need the previous mandate to be fulfilled.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Approve payment of receipt: Execute a transaction from the Safe Treasury.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "SafeAllowance_Transfer"),
                config: abi.encode(helperConfig.getSafeAllowanceModule(block.chainid), treasury),
                conditions: conditions
            })
        );
        delete conditions;

        // PAYMENT OF PROJECTS //
        mandateIds = new uint16[](2);
        mandateIds[0] = mandateCount + 1;
        mandateIds[1] = mandateCount + 2;

        flows.push(PowersTypes.Flow({
            nameDescription: "Payment of Projects: This flow includes the submission and approval of projects for funding.",
            mandateIds: mandateIds
        }));

        inputParams = new string[](3);
        inputParams[0] = "address Token";
        inputParams[1] = "uint256 Amount";
        inputParams[2] = "address PayableTo";

        // Participants: Submit a project (Payment Before Action)
        mandateCount++;
        conditions.allowedRole = 1; // Participants can propose a project.
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid));
        conditions.succeedAt = 51;
        conditions.quorum = 5; // note the low quorum to encourage proposals.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Submit a project for Funding: Any Participant can submit a project for funding.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "StatementOfIntent"),
                config: abi.encode(inputParams),
                conditions: conditions
            })
        );
        delete conditions;

        // Repository admins: Approve Funding of Project
        mandateCount++;
        conditions.allowedRole = 2; // Repository admins
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid));
        conditions.succeedAt = 67;
        conditions.quorum = 50;
        conditions.needFulfilled = mandateCount - 1; // need the previous mandate to be fulfilled.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Approve funding of project: Execute a transaction from the Safe Treasury.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "SafeAllowance_Transfer"),
                config: abi.encode(helperConfig.getSafeAllowanceModule(block.chainid), treasury),
                conditions: conditions
            })
        );
        delete conditions;

        // MISCELLANEOUS //
        mandateIds = new uint16[](2);
        mandateIds[0] = mandateCount + 1;
        mandateIds[1] = mandateCount + 2;

        flows.push(PowersTypes.Flow({
            nameDescription: "Miscellaneous powers: This flow includes updating the URI and recovering tokens sent to the DAO by mistake.",
            mandateIds: mandateIds
        }));

        // UPDATE URI //
        inputParams = new string[](1);
        inputParams[0] = "string newUri";

        // Repository admins: Update URI
        mandateCount++;
        conditions.allowedRole = 2; // = Repository admins
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid)); // = 5 minutes / days
        conditions.succeedAt = 66; // = 2/3 majority
        conditions.quorum = 66; // = 66% quorum
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Update URI: Set allowed token for Physical Layer",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "BespokeAction_Simple"),
                config: abi.encode(
                    address(powers), // target address is its own powers contract
                    Powers.setUri.selector, // function selector to call
                    inputParams
                ),
                conditions: conditions
            })
        );
        delete conditions;

        // TRANSFER TOKENS INTO TREASURY //
        mandateCount++;
        conditions.allowedRole = 2; // = Repository admins. Any convener can call this mandate.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Transfer tokens to treasury: Any tokens accidently sent to the DAO can be recovered by sending them to the treasury",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "Safe_RecoverTokens"),
                config: abi.encode(
                    treasury, // this should be the safe treasury!
                    helperConfig.getSafeAllowanceModule(block.chainid) // allowance module address
                ),
                conditions: conditions
            })
        );
        delete conditions;

        //////////////////////////////////////////////////////////////////////
        //                      ELECTORAL MANDATES                          //
        //////////////////////////////////////////////////////////////////////

        // ASSIGN ParticipantSHIP // -- on the basis of contributions to website
        mandateIds = new uint16[](2);
        mandateIds[0] = mandateCount + 1;
        mandateIds[1] = mandateCount + 2;

        flows.push(PowersTypes.Flow({
            nameDescription: "Assign Participant: This flow allows users to apply for and claim Participant roles based on their GitHub contributions.",
            mandateIds: mandateIds
        }));

        // TODO: needs to be configured with github repo details etc.
        string[] memory paths = new string[](3);
        paths[0] = "documentation"; // can be anything
        paths[1] = "frontend";
        paths[2] = "solidity";
        uint256[] memory roleIds = new uint256[](3);
        roleIds[0] = 2;
        roleIds[1] = 3;
        roleIds[2] = 4;

        // Public: Apply for Participant role
        // mandateCount++;
        // conditions.allowedRole = type(uint256).max; // Public
        // conditions.throttleExecution = minutesToBlocks(3, helperConfig.getBlocksPerHour(block.chainid)); // to avoid spamming, the mandate is throttled.
        // constitution.push(
        //     PowersTypes.MandateInitData({
        //         nameDescription: "Apply for Participant Role: Anyone can claim Participant roles based on their GitHub contributions to the DAO's repository", // crrently the path is set at cedars/powers
        //         targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "Github_ClaimRoleWithSig"), // TODO: needs to be more configurable
        //         config: abi.encode(
        //             "develop", // branch
        //             paths,
        //             roleIds,
        //             "signed", // signatureString
        //             helperConfig.getChainlinkFunctionsSubscriptionId(block.chainid),
        //             helperConfig.getChainlinkFunctionsGasLimit(block.chainid),
        //             helperConfig.getChainlinkFunctionsDonId(block.chainid)
        //         ),
        //         conditions: conditions
        //     })
        // );
        // delete conditions;

        // // Public: Claim Participant Role
        // mandateCount++;
        // conditions.allowedRole = type(uint256).max; // Public
        // conditions.needFulfilled = mandateCount - 1; // must have applied for Participant role.
        // constitution.push(
        //     PowersTypes.MandateInitData({
        //         nameDescription: "Claim Participant Role: Following a successful initial claim, Participants can get Participant role assigned to their account.",
        //         targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "Github_AssignRoleWithSig"),
        //         config: abi.encode(), // empty config
        //         conditions: conditions
        //     })
        // );
        // delete conditions;

        // REVOKE ParticipantSHIP //
        mandateIds = new uint16[](2);
        mandateIds[0] = mandateCount + 1;
        mandateIds[1] = mandateCount + 2;

        flows.push(PowersTypes.Flow({
            nameDescription: "Revoke Participant: This flow allows Participants to veto and executives to revoke Participant.",
            mandateIds: mandateIds
        }));

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
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "StatementOfIntent"),
                config: abi.encode(inputParams),
                conditions: conditions
            })
        );
        delete conditions;

        // Executives: Revoke Participant
        mandateCount++;
        conditions.allowedRole = 2; // = Executives
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid)); // = 5 minutes / days
        conditions.succeedAt = 51; // = 51% majority
        conditions.quorum = 77; // = Note: high threshold.
        conditions.timelock = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid)); // = 10 minutes timelock before execution.
        conditions.needNotFulfilled = mandateCount - 1; // need the veto to have NOT been fulfilled.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Revoke Participant: Executives can revoke Participant from Participants.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "BespokeAction_Advanced"),
                config: abi.encode(
                    address(powers), 
                    IPowers.revokeRole.selector, // function selector to call
                    abi.encode(1), // params before (role id 1 = Participants) // the static params
                    inputParams, // the dynamic params (the input params of the parent mandate)
                    abi.encode() // no args after
                ),
                conditions: conditions
            })
        );
        delete conditions;


        // ELECT Repository admins //
        mandateIds = new uint16[](4);
        mandateIds[0] = mandateCount + 1;
        mandateIds[1] = mandateCount + 2;
        mandateIds[2] = mandateCount + 3;
        mandateIds[3] = mandateCount + 4;

        flows.push(PowersTypes.Flow({
            nameDescription: "Elect Repository Setup Initiators: This flow includes the creation, voting, tallying, and cleanup of an election for Repository Setup Initiators.",
            mandateIds: mandateIds
        }));

        inputParams = new string[](3);
        inputParams[0] = "string Title";
        inputParams[1] = "uint48 StartBlock";
        inputParams[2] = "uint48 EndBlock";

        // Participants: create election
        mandateCount++;
        conditions.allowedRole = 1; // = Participants
        conditions.throttleExecution = minutesToBlocks(120, helperConfig.getBlocksPerHour(block.chainid)); // = once every 2 hours
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Create a Convener election: an election for the convener role can be initiated be any Participant.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "BespokeAction_Simple"),
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
                nameDescription: "Open voting for Convener election: Participants can open the vote for a convener election. This will create a dedicated vote mandate.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "ElectionRegistry_CreateVoteMandate"),
                config: abi.encode(
                    electionRegistry, // election list contract
                    registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "ElectionRegistry_Vote"), // the vote mandate address
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
                nameDescription: "Tally Convener elections: After a convener election has finished, assign the Convener role to the winners.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "ElectionRegistry_Tally"),
                config: abi.encode(
                    electionRegistry, // election list contract
                    2, // RoleId for Repository admins
                    3 // Max role holders
                ),
                conditions: conditions
            })
        );
        delete conditions;

        // Participants: clean up election
        mandateCount++;
        conditions.allowedRole = 1;
        conditions.needFulfilled = mandateCount - 1; // = Tally election
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Clean up Convener election: After an election has finished, clean up related mandates.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "BespokeAction_OnReturnValue"),
                config: abi.encode(
                    address(powers), // target contract
                    IPowers.revokeMandate.selector, // function selector to call
                    abi.encode(), // params before
                    inputParams, // dynamic params (the input params of the parent mandate)
                    mandateCount - 2, // parent mandate id (the open vote mandate)
                    abi.encode() // no params after
                ),
                conditions: conditions
            })
        );
        delete conditions;

        // VOTE OF NO CONFIDENCE // 
        mandateIds = new uint16[](5);
        mandateIds[0] = mandateCount + 1;
        mandateIds[1] = mandateCount + 2;
        mandateIds[2] = mandateCount + 3;
        mandateIds[3] = mandateCount + 4;
        mandateIds[4] = mandateCount + 5;

        flows.push(PowersTypes.Flow({
            nameDescription: "Vote of No Confidence: This flow allows Participants to call a vote of no confidence to revoke Convener statuses and hold a new election.",
            mandateIds: mandateIds
        }));

        // very similar to elect Repository admins, but no throttle, higher threshold and ALL executives get role revoked the moment the first mandate passes.
        inputParams = new string[](3);
        inputParams[0] = "string Title";
        inputParams[1] = "uint48 StartBlock";
        inputParams[2] = "uint48 EndBlock";

        // Participants: Vote of No Confidence 
        mandateCount++;
        conditions.allowedRole = 1;
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid)); // = 5 minutes / days
        conditions.succeedAt = 77; // high majority
        conditions.quorum = 60; // = high quorum 
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Vote of No Confidence: Revoke Convener statuses.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "RevokeAccountsRoleId"),
                config: abi.encode(
                    2, // roleId
                    inputParams // the input params to fill out.
                ),
                conditions: conditions
            })
        );
        delete conditions;

        // Participants: create election
        mandateCount++;
        conditions.allowedRole = 1; // = Participants (should be Convener according to MD, but code says Participants)
        conditions.needFulfilled = mandateCount - 1; // = previous Vote of No Confidence mandate. Note: NO throttle on this one.
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Create a Convener election: an election for the convener role can be initiated be any Participant.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "BespokeAction_Simple"),
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
                nameDescription: "Open voting for Convener election: Participants can open the vote for a convener election. This will create a dedicated vote mandate.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "ElectionRegistry_CreateVoteMandate"),
                config: abi.encode(
                    electionRegistry, // election list contract
                    registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "ElectionRegistry_Vote"), // the vote mandate address
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
                nameDescription: "Tally Convener elections: After a convener election has finished, assign the Convener role to the winners.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "ElectionRegistry_Tally"),
                config: abi.encode(
                    electionRegistry,
                    2, // RoleId for Repository admins
                    5 // Max role holders
                ),
                conditions: conditions
            })
        );
        delete conditions;

        // Participants: clean up election
        mandateCount++;
        conditions.allowedRole = 1;
        conditions.needFulfilled = mandateCount - 1; // = Tally Convener election
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Clean up Convener election: After a convener election has finished, clean up related mandates.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "BespokeAction_OnReturnValue"),
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

        mandateIds = new uint16[](2);
        mandateIds[0] = mandateCount + 1;
        mandateIds[1] = mandateCount + 2;

        flows.push(PowersTypes.Flow({
            nameDescription: "Nominate for Election: This flow allows Participants to nominate themselves or revoke their nomination for an election.",
            mandateIds: mandateIds
        }));

        // Participants: Nominate for Executive election
        mandateCount++;
        conditions.allowedRole = 1; // = Participants (should be Repository admins according to MD, but code says Participants)
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Nominate for election: any Participant can nominate for an election.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "ElectionRegistry_Nominate"),
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
        conditions.allowedRole = 1; // = Participants (should be Repository admins according to MD, but code says Participants) 
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Revoke nomination for election: any Participant can revoke their nomination for an election.",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "ElectionRegistry_Nominate"),
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
        mandateIds = new uint16[](3);
        mandateIds[0] = mandateCount + 1;
        mandateIds[1] = mandateCount + 2;
        mandateIds[2] = mandateCount + 3;

        flows.push(PowersTypes.Flow({
            nameDescription: "Adopt Mandates: This flow allows for the adoption of new mandates, initiated by Participants, adopted by Repository admins, and subject to veto by the Primary Layer.",
            mandateIds: mandateIds
        }));

        string[] memory adoptMandatesParams = new string[](2);
        adoptMandatesParams[0] = "address[] mandates";
        adoptMandatesParams[1] = "uint256[] roleIds";

        // Participants: initiate Adopting Mandates
        mandateCount++;
        conditions.allowedRole = 1; // Participants
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid));
        conditions.succeedAt = 66;
        conditions.quorum = 77;
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Initiate Adopting Mandates: Participants can initiate adopting new mandates",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "StatementOfIntent"),
                config: abi.encode(adoptMandatesParams),
                conditions: conditions
            })
        );
        delete conditions;

        // PrimaryLayer: Veto Adopting Mandates
        mandateCount++;
        conditions.allowedRole = 6; // PrimaryLayer
        conditions.needFulfilled = mandateCount - 1;
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Veto Adopting Mandates: PrimaryLayer can veto proposals to adopt new mandates", 
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "StatementOfIntent"),
                config: abi.encode(adoptMandatesParams),
                conditions: conditions
            })
        );
        delete conditions;

        // // Repository admins: Adopt Mandates
        mandateCount++;
        conditions.allowedRole = 2; // Repository admins
        conditions.needFulfilled = mandateCount - 2;
        conditions.needNotFulfilled = mandateCount - 1;
        conditions.votingPeriod = minutesToBlocks(5, helperConfig.getBlocksPerHour(block.chainid));
        conditions.succeedAt = 66;
        conditions.quorum = 80;
        constitution.push(
            PowersTypes.MandateInitData({
                nameDescription: "Adopt new Mandates: Repository admins can adopt new mandates into the organization",
                targetMandate: registry.getMandateAddress(MAJOR, MINOR, PATCH, IS_STRICT, "Adopt_Mandates"),
                config: abi.encode(),
                conditions: conditions
            })
        );
        delete conditions;
    }
}
