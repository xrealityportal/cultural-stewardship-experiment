// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

// import { Test, console, console2 } from "forge-std/Test.sol";
// import { Powers } from "lib/powers-monorepo/solidity/src/Powers.sol";
// import { Mandate } from "lib/powers-monorepo/solidity/src/Mandate.sol";
// import { IPowers } from "lib/powers-monorepo/solidity/src/interfaces/IPowers.sol";
// import { PowersTypes } from "lib/powers-monorepo/solidity/src/interfaces/PowersTypes.sol";
// import { Deploy } from "lib/powers-monorepo/solidity/src/governance/culturalStewardsDAO/Deploy.s.sol";
// import { Safe } from "lib/safe-smart-account/contracts/Safe.sol";
// import { SimpleErc20Votes } from "lib/powers-monorepo/solidity/src/test/mocks/SimpleErc20Votes.sol";
// import { Configurations } from "lib/powers-monorepo/solidity/src/script/Configurations.s.sol";
// import { Strings } from "lib/openzeppelin-contracts/contracts/utils/Strings.sol"; 
// import { PresetActions } from "lib/powers-monorepo/solidity/src/mandates/executive/PresetActions.sol";
// interface IAllowanceModule {
//     function delegates(address safe, uint48 index) external view returns (address delegate, uint48 prev, uint48 next);
//     function getTokenAllowance(address safe, address delegate, address token) external view returns (uint256[5] memory);
// }

// contract CulturalStewardsDAO_IntegrationTest is Test {
//     struct Mem {
//         address admin;
//         uint16 setDelegateMandateId;
//         uint16 initiateIdeasMandateId;
//         uint16 createIdeasMandateId;
//         uint16 assignRoleMandateId;
//         uint16 revokeIdeasMandateId;
//         uint16 initiatePhysicalId;
//         uint16 deployMeritBadgeId;
//         uint16 addDependencyId;
//         uint16 createPhysicalId;
//         uint16 assignRoleId;
//         uint16 assignAllowanceId;
//         uint16 revokeRoleId;
//         uint16 revokeAllowanceId;
//         uint16 assignDelegateId;
//         uint16 requestPhysicalAllowanceId;
//         uint16 grantPhysicalAllowanceId;
//         uint16 requestDigitalAllowanceId;
//         uint16 grantDigitalAllowanceId;
//         uint16 initiateReformId;
//         uint16 checkpoint1Id;
//         uint16 checkpoint2Id;
//         uint16 checkpoint3Id;
//         uint16 adoptMandateId;

//         uint256 actionId;
//         // Added fields to avoid stack too deep
//         uint256 constitutionLength;
//         uint256 packageSize;
//         uint256 numPackages;
//         bytes params;
//         uint256 nonce;
//         address physicalSubDAOAddress;
//         bytes revokeParams;
//         // Additional fields for other tests
//         uint48 delegateIndex;
//         address delegateAddr;
//         bool isActive;
//         bool isEnabled;
//         address ideasSubDAOAddress;
//         uint32 votingPeriod;
//         uint32 timelock;
//         uint48 roleSince;
//         bytes returnData;

//         address token; // ETH
//         uint96 amount;
//         uint16 resetTime;
//         uint32 resetBase;
//         address digitalSubDAOAddr;
//         bytes allowanceParams;

//         // New fields added during refactoring
//         address user;
//         address recipient;
//         address fakeIdeasLayer;
//         address mockPhysicalLayer;
//         address convener;
//         address member;

//         uint256 paymentAmount;
//         uint48 startBlock;
//         uint48 endBlock;
//         uint256 voteMandateId;
//         uint256 numberOfRole1Holders;

//         uint16 submitReceiptId;
//         uint16 okReceiptId;
//         uint16 approvePaymentId;
//         uint16 claimStep1Id;
//         uint16 claimStep2Id;
//         uint16 mintActivityId;
//         uint16 mintPoapPrimaryId;
//         uint16 mintActivityTokenPrimaryId;
//         uint16 mandateId;
//         uint16 createElectionId;
//         uint16 nominateId;
//         uint16 openVoteId;
//         uint16 tallyElectionId;
//         uint16 cleanupElectionId;
//         uint16 initiateRequestId;
//         uint16 createWGId;
//         uint16 createWGElectionId;
//         uint16 tallyId;
//         uint16 requestPhysicalId;

//         uint256[5] allowanceInfo;
//         bytes paymentParams;
//         uint256[] nonces;
//         uint256[] actionIds;
//         uint256[] tokenIds;
//         bytes electionParams;
//         bool[] votes;
//         uint256[] roleIds;
//         // Added for test_IdeasSubDAO_MembershipAndModeration
//         uint256 amountRoleHolders;
//         address moderator;
//         address applicant;
//         uint16 assignModeratorId;
//         uint16 applyMembershipId;
//         uint16 assignMembershipId;
//         uint16 revokeMembershipId;
//         uint16 revokeModeratorId;
//         bytes appParams;
//     }
//     Mem mem;

//     Deploy deployScript;
//     Configurations helperConfig;
//     Powers PrimaryLayer;
//     Powers digitalSubDAO; 

//     address treasury;
//     address safeAllowanceModule;
//     address cedars = 0x328735d26e5Ada93610F0006c32abE2278c46211;

//     function setUp() public {
//         helperConfig = new Configurations();

//         vm.skip(false); // Remove this line to run the test
//         uint256 sepoliaFork = vm.createFork(vm.envString("SEPOLIA_RPC_URL"));
//         vm.selectFork(sepoliaFork);

//         // Deploy the script
//         deployScript = new Deploy();
//         deployScript.run();

//         // Get the deployed contracts
//         PrimaryLayer = deployScript.getPrimaryLayer();   

//         // Execute "Initial Setup"
//         vm.prank(cedars);
//         PrimaryLayer.request(1, "", 0, "");

//         // Identify Mandate IDs
//         console.log("Executing Initial Setup Digital");
//         digitalSubDAO = deployScript.getDigitalSubDAO();
//         digitalSubDAO.request(1, "", 0, "");

//         mem.admin = PrimaryLayer.getRoleHolderAtIndex(1, 0);
//         console.log("Setup Initiator address: %s", mem.admin);

//         treasury = PrimaryLayer.getTreasury();
//         console.log("Treasury address: %s", treasury);

//         mem.digitalSubDAOAddr = address(digitalSubDAO);
//         vm.prank(mem.digitalSubDAOAddr);
//         digitalSubDAO.assignRole(2, cedars); // Assign Role 2 to Cedars AT THE DIGITAL DAO. (so that cedars can act there as convener as well.)

//         /////////////////////////////////////////////////////////////////// 
//         // find mandate IDs using findMandateIdInOrg function if needed  //
//         ///////////////////////////////////////////////////////////////////
//         mem.initiateIdeasMandateId = findMandateIdInOrg("Initiate Ideas Layer: Initiate creation of Ideas Layer", PrimaryLayer);
//         mem.createIdeasMandateId = findMandateIdInOrg("Create Ideas Layer: Execute Ideas Layer creation", PrimaryLayer);
//         mem.assignRoleMandateId = findMandateIdInOrg("Assign role Id to DAO: Assign role id 4 (Ideas Layer) to the new DAO", PrimaryLayer);
//         mem.revokeIdeasMandateId = findMandateIdInOrg("Revoke role Id: Revoke role id 4 (Ideas Layer) from the DAO", PrimaryLayer);

//         mem.initiatePhysicalId = findMandateIdInOrg("Initiate Physical Layer: Initiate creation of Physical Layer", PrimaryLayer);
//         // mem.deployMeritBadgeId = findMandateIdInOrg("Deploy Merit Badge Contract: Deploy a Soulbound1155 contract to be used as merit badges for the Physical Layer", PrimaryLayer);
//         // mem.addDependencyId = findMandateIdInOrg("Add dependency: Add the deployed Soulbound1155 as a dependency to the create Physical Layer mandate", PrimaryLayer);
        
//         mem.createPhysicalId = findMandateIdInOrg("Create Physical Layer: Execute Physical Layer creation", PrimaryLayer);
//         mem.assignRoleId = findMandateIdInOrg("Assign role Id: Assign role Id 3 to Physical Layer", PrimaryLayer);
        
//         mem.assignDelegateId = findMandateIdInOrg("Assign Delegate status: Assign delegate status at Safe treasury to the Physical Layer", PrimaryLayer);
//         mem.assignAllowanceId = mem.assignDelegateId;

//         mem.revokeRoleId = findMandateIdInOrg("Revoke Role Id: Revoke role Id 3 from Physical Layer", PrimaryLayer);
//         mem.revokeAllowanceId = findMandateIdInOrg("Revoke Delegate status: Revoke delegate status Physical Layer at the Safe treasury", PrimaryLayer);
        
//         mem.requestPhysicalAllowanceId = findMandateIdInOrg("Request additional allowance: Any Physical Layer can request an allowance from the Safe Treasury.", PrimaryLayer);
//         mem.grantPhysicalAllowanceId = findMandateIdInOrg("Set Allowance: Execute and set allowance for a Physical Layer.", PrimaryLayer);
        
//         mem.requestDigitalAllowanceId = findMandateIdInOrg("Request additional allowance: The Digital Layer can request an allowance from the Safe Treasury.", PrimaryLayer);
//         mem.grantDigitalAllowanceId = findMandateIdInOrg("Set Allowance: Execute and set allowance for the Digital Layer.", PrimaryLayer);
        
//         mem.initiateReformId = findMandateIdInOrg("Initiate mandate adoption: Any executive can propose adopting new mandates into the organization.", PrimaryLayer);
//         mem.checkpoint1Id = findMandateIdInOrg("Reform Checkpoint 1: Executives confirm Members did not veto.", PrimaryLayer);
//         mem.checkpoint2Id = findMandateIdInOrg("Reform Checkpoint 2: Executives confirm Digital Layer did not veto.", PrimaryLayer);
//         mem.checkpoint3Id = findMandateIdInOrg("Reform Checkpoint 3: Executives confirm Ideas Layer did not veto.", PrimaryLayer);
//         mem.adoptMandateId = findMandateIdInOrg("Adopt new Mandates: Executives can adopt new mandates into the organization", PrimaryLayer);
//     }

//     function test_InitialSetup() public {
//         // 4. Verify Role Labels
//         assertEq(PrimaryLayer.getRoleLabel(1), "Members", "Role 1 should be Members");
//         assertEq(PrimaryLayer.getRoleLabel(2), "Executives", "Role 2 should be Executives");
//         assertEq(PrimaryLayer.getRoleLabel(3), "Physical Layers", "Role 3 should be Physical Layers");
//         assertEq(PrimaryLayer.getRoleLabel(4), "Ideas Layers", "Role 4 should be Ideas Layers");
//         assertEq(PrimaryLayer.getRoleLabel(5), "Digital Layers", "Role 5 should be Digital Layers");

//         // 6. Verify Safe Module
//         mem.isEnabled = Safe(payable(treasury)).isModuleEnabled(helperConfig.getSafeAllowanceModule(block.chainid));
//         assertTrue(mem.isEnabled, "Allowance Module should be enabled on Safe");

//         // 7. Verify Mandate 1 is Revoked
//         (,, mem.isActive) = PrimaryLayer.getAdoptedMandate(1);
//         assertFalse(mem.isActive, "Mandate 1 should be revoked");

//         // 9. Verify Digital Layer is Delegate
//         mem.delegateIndex = uint48(uint160(address(digitalSubDAO)));

//         (mem.delegateAddr,,) = IAllowanceModule(helperConfig.getSafeAllowanceModule(block.chainid)).delegates(treasury, mem.delegateIndex);
//         assertEq(mem.delegateAddr, address(digitalSubDAO), "Digital Layer should be a delegate on Allowance Module");
//     }

//     function test_adoptNewMandatesPrimaryLayer() public {
        
//     }

//     function test_CreateAndRevokeIdeasSubDAO() public {
//         _deployIdeasSubDAO();

//         // --- Verify Creation ---
//         // Note: _deployIdeasSubDAO already decodes and stores address in mem.ideasSubDAOAddress
//         mem.roleSince = PrimaryLayer.hasRoleSince(mem.ideasSubDAOAddress, 4);
//         assertTrue(mem.roleSince > 0, "Ideas Layer should have Role 4");

//         // --- Step 4: Revoke Ideas Layer (Executives) ---
//         vm.startPrank(mem.admin);
//         console.log("Revoking Ideas Layer...");

//         mem.revokeParams = abi.encode(mem.ideasSubDAOAddress);
//         mem.nonce++;

//         // Propose Revoke
//         mem.actionId = PrimaryLayer.propose(mem.revokeIdeasMandateId, mem.revokeParams, mem.nonce, "");

//         // Vote
//         PrimaryLayer.castVote(mem.actionId, 1);

//         // Wait voting period + timelock
//         mem.votingPeriod = PrimaryLayer.getConditions(mem.revokeIdeasMandateId).votingPeriod;
//         mem.timelock = PrimaryLayer.getConditions(mem.revokeIdeasMandateId).timelock;
//         vm.roll(block.number + mem.votingPeriod + mem.timelock + 1);

//         // Execute
//         PrimaryLayer.request(mem.revokeIdeasMandateId, mem.revokeParams, mem.nonce, "");
//         vm.stopPrank();

//         // --- Verify Revocation ---
//         mem.roleSince = PrimaryLayer.hasRoleSince(mem.ideasSubDAOAddress, 4);
//         assertEq(mem.roleSince, 0, "Ideas Layer should NOT have Role 4 anymore");
//     }

//     function test_CreateAndRevokePhysicalSubDAO() public {
//         _deployIdeasSubDAO();
//         _deployPhysicalSubDAO();

//         // Verify Role 3 (Physical Layers)
//         assertTrue(PrimaryLayer.hasRoleSince(mem.physicalSubDAOAddress, 3) > 0, "Role 3 missing");

//         // Verify Status (Delegate)
//         // Note: _deployPhysicalSubDAO assigns delegate status
//         mem.delegateIndex = uint48(uint160(address(mem.physicalSubDAOAddress)));
//         (mem.delegateAddr,,) = IAllowanceModule(helperConfig.getSafeAllowanceModule(block.chainid)).delegates(treasury, mem.delegateIndex);
//         assertEq(
//             mem.delegateAddr, mem.physicalSubDAOAddress, "Digital Layer should be a delegate on Allowance Module"
//         );

//         // --- Step 5: Revoke Physical Layer ---
//         vm.startPrank(cedars); // _deployPhysicalSubDAO ends pranking cedars, but better be safe
//         console.log("Revoking Physical Layer...");
//         mem.revokeParams = abi.encode(mem.physicalSubDAOAddress, true); // address, bool
//         mem.nonce++;

//         // Revoke Role
//         console.log("Revoking Role...");
//         mem.actionId = PrimaryLayer.propose(mem.revokeRoleId, mem.revokeParams, mem.nonce, "");
//         PrimaryLayer.castVote(mem.actionId, 1);
//         vm.roll(
//             block.number + PrimaryLayer.getConditions(mem.revokeRoleId).votingPeriod
//                 + PrimaryLayer.getConditions(mem.revokeRoleId).timelock + 1
//         );
//         PrimaryLayer.request(mem.revokeRoleId, mem.revokeParams, mem.nonce, "");

//         // Verify Role Revoked
//         assertEq(PrimaryLayer.hasRoleSince(mem.physicalSubDAOAddress, 3), 0, "Role 3 not revoked");

//         // Revoke Allowance
//         console.log("Revoking Allowance...");
//         PrimaryLayer.request(mem.revokeAllowanceId, mem.revokeParams, mem.nonce, "Revoke Allowance");

//         // Verify Allowance Revoked
//         mem.delegateIndex = uint48(uint160(address(mem.physicalSubDAOAddress)));
//         (mem.delegateAddr,,) = IAllowanceModule(helperConfig.getSafeAllowanceModule(block.chainid)).delegates(treasury, mem.delegateIndex);
//         assertEq(mem.delegateAddr, address(0), "Digital Layer should NOT be a delegate on Allowance Module anymore");

//         vm.stopPrank();
//     }

//     function test_AddAllowances() public {
//         _deployIdeasSubDAO();
//         _deployPhysicalSubDAO();

//         // Verify Role 3 (Physical Layers)
//         assertTrue(PrimaryLayer.hasRoleSince(mem.physicalSubDAOAddress, 3) > 0, "Role 3 missing");

//         // --- TEST 1: Physical Layer Allowance Flow ---

//         // Params for allowance: Sub-DAO, Token, Amount, ResetTime, ResetBase
//         mem.token = address(0); // ETH
//         mem.amount = 1 ether;
//         mem.resetTime = 100;
//         mem.resetBase = 0;

//         mem.allowanceParams = abi.encode(mem.physicalSubDAOAddress, mem.token, mem.amount, mem.resetTime, mem.resetBase);
//         mem.nonce++;

//         // 1. Physical Layer requests allowance
//         vm.startPrank(mem.physicalSubDAOAddress);
//         console.log("Physical Layer requesting allowance...");
//         PrimaryLayer.request(mem.requestPhysicalAllowanceId, mem.allowanceParams, mem.nonce, "Physical Layer requesting allowance");
//         vm.stopPrank();

//         // 2. Veto by Physical Layers check (we will just wait out the timelock/voting period of the grant without vetoing)
//         // Note: The grant mandate requires the veto NOT to be fulfilled.

//         // 3. Executives grant allowance
//         // Role 2 (Executives) is held by cedars.
//         vm.startPrank(cedars);
//         console.log("Executives granting allowance to Physical Layer...");

//         mem.actionId = PrimaryLayer.propose(mem.grantPhysicalAllowanceId, mem.allowanceParams, mem.nonce, "Grant Physical Layer Allowance - Propose");
//         PrimaryLayer.castVote(mem.actionId, 1);

//         // Wait voting + timelock
//         mem.votingPeriod = PrimaryLayer.getConditions(mem.grantPhysicalAllowanceId).votingPeriod;
//         mem.timelock = PrimaryLayer.getConditions(mem.grantPhysicalAllowanceId).timelock;
//         vm.roll(block.number + mem.votingPeriod + mem.timelock + 1);

//         PrimaryLayer.request(mem.grantPhysicalAllowanceId, mem.allowanceParams, mem.nonce, "Grant Physical Layer Allowance - Request");
//         vm.stopPrank();

//         // Verify Allowance
//         mem.allowanceInfo = IAllowanceModule(helperConfig.getSafeAllowanceModule(block.chainid)).getTokenAllowance(treasury, mem.physicalSubDAOAddress, mem.token);
//         assertEq(uint96(mem.allowanceInfo[0]), mem.amount, "Physical Layer allowance should be set");

//         // --- TEST 2: Digital Layer Allowance Flow ---

//         // Verify Digital Layer has delegate status (Checked in InitialSetup)
//         mem.digitalSubDAOAddr = address(digitalSubDAO);

//         // Params for allowance
//         mem.allowanceParams = abi.encode(mem.digitalSubDAOAddr, mem.token, mem.amount, mem.resetTime, mem.resetBase);
//         mem.nonce++;

//         // 1. Digital Layer requests allowance
//         vm.startPrank(mem.digitalSubDAOAddr);
//         console.log("Digital Layer requesting allowance...");
//         PrimaryLayer.request(mem.requestDigitalAllowanceId, mem.allowanceParams, mem.nonce, "Digital Layer requesting allowance");
//         vm.stopPrank();

//         // 2. Executives grant allowance
//         vm.startPrank(cedars); // cedars has role 2
//         console.log("Executives granting allowance to Digital Layer...");

//         mem.actionId = PrimaryLayer.propose(mem.grantDigitalAllowanceId, mem.allowanceParams, mem.nonce, "Grant Digital Layer Allowance - Propose");
//         PrimaryLayer.castVote(mem.actionId, 1);

//         mem.votingPeriod = PrimaryLayer.getConditions(mem.grantDigitalAllowanceId).votingPeriod;
//         mem.timelock = PrimaryLayer.getConditions(mem.grantDigitalAllowanceId).timelock;
//         vm.roll(block.number + mem.votingPeriod + mem.timelock + 1);

//         PrimaryLayer.request(mem.grantDigitalAllowanceId, mem.allowanceParams, mem.nonce, "Grant Digital Layer Allowance - Request");
//         vm.stopPrank();

//         // Verify Allowance
//         mem.allowanceInfo = IAllowanceModule(helperConfig.getSafeAllowanceModule(block.chainid)).getTokenAllowance(treasury, mem.digitalSubDAOAddr, mem.token);
//         assertEq(uint96(mem.allowanceInfo[0]), mem.amount, "Digital Layer allowance should be set");
//     }

//     function test_PaymentOfReceipts_DigitalSubDAO() public {
//         // --- Grant Allowance to Digital Layer (Primary Layer side) ---
//         // Reusing logic from test_AddAllowances
//         // Mandate IDs

//         mem.token = address(0); // ETH
//         mem.amount = 1 ether;
//         mem.resetTime = 100;
//         mem.resetBase = 0;

//         mem.allowanceParams = abi.encode(mem.digitalSubDAOAddr, mem.token, mem.amount, mem.resetTime, mem.resetBase);
//         mem.nonce = 100;

//         // 1. Request Allowance (by Cedars - Role 5)
//         console2.log("Digital Layer (via Cedars) requesting allowance...");
//         vm.startPrank(mem.digitalSubDAOAddr);
//         PrimaryLayer.request(mem.requestDigitalAllowanceId, mem.allowanceParams, mem.nonce, "");
//         vm.stopPrank();

//         // 2. Grant Allowance (by conveners - Role 2)
//         console2.log("Executives granting allowance to Digital Layer...");
//         vm.startPrank(mem.admin);
//         mem.actionId = PrimaryLayer.propose(mem.grantDigitalAllowanceId, mem.allowanceParams, mem.nonce, "");
//         PrimaryLayer.castVote(mem.actionId, 1);

//         uint32 votingPeriod = PrimaryLayer.getConditions(mem.grantDigitalAllowanceId).votingPeriod;
//         uint32 timelock = PrimaryLayer.getConditions(mem.grantDigitalAllowanceId).timelock;
//         vm.roll(block.number + votingPeriod + timelock + 1);

//         PrimaryLayer.request(mem.grantDigitalAllowanceId, mem.allowanceParams, mem.nonce, "");
//         vm.stopPrank();

//         // Verify Allowance
//         mem.allowanceInfo = IAllowanceModule(helperConfig.getSafeAllowanceModule(block.chainid)).getTokenAllowance(treasury, mem.digitalSubDAOAddr, mem.token);
//         assertEq(uint96(mem.allowanceInfo[0]), mem.amount, "Digital Layer allowance should be set");

//         // Fund Treasury
//         vm.deal(treasury, 10 ether);
//         assertEq(treasury.balance, 10 ether, "Treasury should have funds");

//         // --- Digital Layer Payment Flow ---
//         // Mandates:
//         // 2: Submit Receipt (Public)
//         // 3: OK Receipt (Conveners)
//         // 4: Approve Payment (Conveners)

//         mem.recipient = address(0x123456789);
//         mem.paymentAmount = 0.5 ether;

//         // Params: address Token, uint256 Amount, address PayableTo
//         mem.paymentParams = abi.encode(mem.token, mem.paymentAmount, mem.recipient);

//         // Step 1: Submit Receipt (Public)
//         mem.user = address(0x999);
//         vm.startPrank(mem.user);
//         console.log("Submitting receipt...");
//         // Propose
//         mem.nonce++;
//         mem.submitReceiptId = findMandateIdInOrg("Submit a Receipt: Anyone can submit a receipt for payment reimbursement.", digitalSubDAO);
//         digitalSubDAO.request(mem.submitReceiptId, mem.paymentParams, mem.nonce, "");
//         vm.stopPrank();

//         vm.roll(block.number + 1); // Advance block to avoid same-block issues

//         // Step 2: OK Receipt (Conveners)
//         // Who is convener? Cedars (assigned in Mandate 1).
//         vm.startPrank(cedars);
//         console.log("OK'ing receipt...");
//         // Request (Condition: Role 2. No voting period set).
//         mem.okReceiptId = findMandateIdInOrg("OK a receipt: Any convener can ok a receipt for payment reimbursement.", digitalSubDAO);
//         digitalSubDAO.request(mem.okReceiptId, mem.paymentParams, mem.nonce, "");
//         vm.stopPrank();

//         // Step 3: Approve Payment (Conveners)
//         vm.startPrank(cedars);
//         console.log("Approving payment...");
//         mem.approvePaymentId = findMandateIdInOrg("Approve payment of receipt: Execute a transaction from the Safe Treasury.", digitalSubDAO);
//         mem.actionId = digitalSubDAO.propose(mem.approvePaymentId, mem.paymentParams, mem.nonce, "");

//         // Vote (Quorum 50%, SucceedAt 67%)
//         // Cedars is likely the only role holder?
//         // In Mandate 1, only Cedars is assigned Role 2.
//         // So 1 vote should be 100%.
//         digitalSubDAO.castVote(mem.actionId, 1);

//         // Wait voting period (5 mins)
//         votingPeriod = digitalSubDAO.getConditions(mem.approvePaymentId).votingPeriod;
//         vm.roll(block.number + votingPeriod + 1);

//         // Execute
//         digitalSubDAO.request(mem.approvePaymentId, mem.paymentParams, mem.nonce, "");
//         vm.stopPrank();

//         // Verify Payment
//         assertEq(mem.recipient.balance, mem.paymentAmount, "Recipient should have received payment");

//         // Verify Allowance Spent
//         mem.allowanceInfo = IAllowanceModule(helperConfig.getSafeAllowanceModule(block.chainid)).getTokenAllowance(treasury, mem.digitalSubDAOAddr, mem.token);
//         assertEq(uint96(mem.allowanceInfo[1]), mem.paymentAmount, "Allowance spent should match payment");
//     }

//     function test_AdoptMandate_PrimaryLayer() public {
//         _deployIdeasSubDAO();
//         _deployPhysicalSubDAO();

//         // 1. Prepare Mandate Data
//         PresetActions newMandate = new PresetActions();
        
//         address[] memory mandates = new address[](1);
//         mandates[0] = address(newMandate);
        
//         uint256[] memory roleIds = new uint256[](1);
//         roleIds[0] = 2; // Executives
        
//         mem.params = abi.encode(mandates, roleIds);
//         mem.nonce = 500; // Arbitrary nonce to avoid collision

//         // 2. Initiate Reform (Executives)
//         vm.startPrank(cedars);
//         console.log("Initiating Reform...");
//         PrimaryLayer.request(mem.initiateReformId, mem.params, mem.nonce, "Initiate Reform");

//         // 3. Reform Checkpoint 1 (Executives) - Needs timelock
//         // Must propose first because timelock > 0
//         console.log("Proposing Checkpoint 1...");
//         mem.actionId = PrimaryLayer.propose(mem.checkpoint1Id, mem.params, mem.nonce, "Checkpoint 1");
        
//         // Wait timelock (5 mins)
//         mem.timelock = PrimaryLayer.getConditions(mem.checkpoint1Id).timelock;
//         vm.roll(block.number + mem.timelock + 1);

//         console.log("Requesting Checkpoint 1...");
//         PrimaryLayer.request(mem.checkpoint1Id, mem.params, mem.nonce, "Checkpoint 1");

//         // 4. Reform Checkpoint 2 (Executives) - No timelock
//         console.log("Requesting Checkpoint 2...");
//         PrimaryLayer.request(mem.checkpoint2Id, mem.params, mem.nonce, "Checkpoint 2");

//         // 5. Reform Checkpoint 3 (Executives) - No timelock
//         console.log("Requesting Checkpoint 3...");
//         PrimaryLayer.request(mem.checkpoint3Id, mem.params, mem.nonce, "Checkpoint 3");

//         // 6. Adopt Mandate (Executives) - Vote + Timelock
//         console.log("Proposing Adoption...");
//         mem.actionId = PrimaryLayer.propose(mem.adoptMandateId, mem.params, mem.nonce, "Adopt Mandate");

//         // Vote
//         PrimaryLayer.castVote(mem.actionId, 1);

//         // Wait voting period + timelock
//         mem.votingPeriod = PrimaryLayer.getConditions(mem.adoptMandateId).votingPeriod;
//         mem.timelock = PrimaryLayer.getConditions(mem.adoptMandateId).timelock;
//         vm.roll(block.number + mem.votingPeriod + mem.timelock + 1);

//         console.log("Requesting Adoption...");
//         PrimaryLayer.request(mem.adoptMandateId, mem.params, mem.nonce, "Adopt Mandate");
//         vm.stopPrank();

//         // 7. Verify Adoption
//         uint16 nextMandateId = PrimaryLayer.getMandateCounter() - 1; // getMandateCounter returns next ID
//         (address mandateAddr, , bool active) = PrimaryLayer.getAdoptedMandate(nextMandateId);
        
//         assertEq(mandateAddr, address(newMandate), "New mandate should be adopted");
//         assertTrue(active, "New mandate should be active");
//     }

//     function test_JoinPrimeDAO() public {
//         _deployIdeasSubDAO();
//         _deployPhysicalSubDAO();

//         // Setup Member
//         mem.member = address(0xABC);
        
//         // --- Step 1: Become Member of Ideas Sub-DAO ---
//         // Apply (User)
//         mem.applyMembershipId = findMandateIdInOrg("Apply for Membership: Anyone can apply for membership to the DAO by submitting an application.", Powers(payable(mem.ideasSubDAOAddress)));
//         mem.appParams = abi.encode(mem.member, "ipfs://application");
//         vm.prank(mem.member);
//         Powers(payable(mem.ideasSubDAOAddress)).request(mem.applyMembershipId, mem.appParams, 1, "Apply for Ideas Sub-DAO Membership");

//         // Assign (Moderator - Cedars)
//         // Note: Cedars is assigned Role 3 (Moderator) in createIdeasConstitution
//         mem.assignMembershipId = findMandateIdInOrg("Assess and Assign Membership: Moderators can assess applications and assign membership to applicants.", Powers(payable(mem.ideasSubDAOAddress)));
//         vm.prank(cedars);
//         Powers(payable(mem.ideasSubDAOAddress)).request(mem.assignMembershipId, mem.appParams, 1, "Assess and Assign Ideas Sub-DAO Membership");

//         // Verify Membership
//         assertTrue(Powers(payable(mem.ideasSubDAOAddress)).hasRoleSince(mem.member, 1) > 0, "Member should have Ideas Role 1");

//         // --- Step 2: Mint POAPs at Physical DAO ---
//         // Note: Cedars is assigned Role 2 (Convener) in createPhysicalConstitution
//         // Mandate: "Mint POAP: Any Convener can mint a POAP." calling Primary Layer
//         // The Primary Layer mandate (GovernedToken_MintEncodedToken) expects (to, artist, uri)
//         // But the Physical DAO ExternalAction_Simple has inputParams="address To".
//         // However, we pass the full encoded data that matches the target mandate signature.
        
//         mem.mintPoapPrimaryId = findMandateIdInOrg("Mint POAP: Any Convener can mint a POAP.", Powers(payable(mem.physicalSubDAOAddress)));
        
//         // Mint 2 tokens
//         // We need to pass valid calldata for GovernedToken_MintEncodedToken: (address to, address artist, string uri)
//         bytes memory mintCalldata = abi.encode(mem.member, address(0), "");
        
//         vm.prank(cedars);
//         Powers(payable(mem.physicalSubDAOAddress)).request(mem.mintPoapPrimaryId, mintCalldata, 1, "Mint POAP 1");
        
//         // Token ID calculation logic from GovernedToken_MintEncodedToken
//         // id = (uint256(uint160(caller)) << 48) | uint256(block.number);
//         // caller is PhysicalSubDAO address
//         uint256 tokenId1 = (uint256(uint160(mem.physicalSubDAOAddress)) << 48) | uint256(block.number);
        
//         vm.roll(block.number + 1); // Advance block to get unique ID
        
//         vm.prank(cedars);
//         Powers(payable(mem.physicalSubDAOAddress)).request(mem.mintPoapPrimaryId, mintCalldata, 2, "Mint POAP 2");
//         uint256 tokenId2 = (uint256(uint160(mem.physicalSubDAOAddress)) << 48) | uint256(block.number);

//         // --- Step 3: Request Membership at Ideas DAO ---
//         uint256[] memory tokenIds = new uint256[](2);
//         tokenIds[0] = tokenId1;
//         tokenIds[1] = tokenId2;
//         mem.params = abi.encode(tokenIds);
        
//         // Member applies at Ideas DAO
//         uint16 applyPrimaryId = findMandateIdInOrg("Apply for Membership of Primary Layer: Members can apply for membership of the Primary Layer by submitting a request with their POAPs.", Powers(payable(mem.ideasSubDAOAddress)));
//         vm.prank(mem.member);
//         Powers(payable(mem.ideasSubDAOAddress)).request(applyPrimaryId, mem.params, 1, "Apply for Ideas Sub-DAO Membership");
        
//         // Moderator (Cedars) approves and sends request to Primary Layer
//         uint16 requestPrimaryId = findMandateIdInOrg("Request Membership of Primary Layer: Moderators can ok requests for membership of the Primary Layer and send them to the Primary Layer for assessment.", Powers(payable(mem.ideasSubDAOAddress)));

//         // need to vote on the application
//         vm.startPrank(cedars);
//         Powers(payable(mem.ideasSubDAOAddress)).propose(requestPrimaryId, mem.params, 1, "Assess and Assign Ideas Sub-DAO Membership - propose");
//         vm.stopPrank();

//         vm.roll(block.number + 1);  
        
//         vm.startPrank(cedars);
//         Powers(payable(mem.ideasSubDAOAddress)).castVote(requestPrimaryId, 1);
//         vm.roll(block.number + Powers(payable(mem.ideasSubDAOAddress)).getConditions(requestPrimaryId).votingPeriod + 1);
//         Powers(payable(mem.ideasSubDAOAddress)).request(requestPrimaryId, mem.params, 1, "Assess and Assign Ideas Sub-DAO Membership - request");

//         vm.stopPrank();

//         // This triggers "Request Membership Step 1" in Primary Layer.
//         // We can verify that Step 1 is fulfilled if we want, but we'll see if Step 2 works.

//         // --- Step 4: Claim Membership at Primary Layer ---
//         mem.claimStep2Id = findMandateIdInOrg("Request Membership Step 2: 2 POAPS from physical DAO are needed that are not older than 6 months.", PrimaryLayer);
        
//         vm.prank(mem.member);
//         PrimaryLayer.request(mem.claimStep2Id, mem.params, 1, "Claim Membership Step 2");
        
//         // Verify Role 1 in Primary Layer
//         assertTrue(PrimaryLayer.hasRoleSince(mem.member, 1) > 0, "Member should have Primary Role 1");

//         // --- Step 5: Revoke Membership Primary Layer ---
//         // Veto Revoke (Members)
//         // We skip veto and proceed to proposal by Executive
//         mem.revokeMembershipId = findMandateIdInOrg("Revoke Membership: Executives can revoke membership from members.", PrimaryLayer);
//         bytes memory revokeParams = abi.encode(mem.member);
        
//         vm.startPrank(cedars); // Cedars is Executive (Role 2)
//         mem.actionId = PrimaryLayer.propose(mem.revokeMembershipId, revokeParams, 1, "Revoke Membership - Proposal");
//         PrimaryLayer.castVote(mem.actionId, 1);
        
//         vm.roll(block.number + PrimaryLayer.getConditions(mem.revokeMembershipId).votingPeriod + PrimaryLayer.getConditions(mem.revokeMembershipId).timelock + 1);
        
//         PrimaryLayer.request(mem.revokeMembershipId, revokeParams, 1, "Revoke Membership - Request");
//         vm.stopPrank();
        
//         // Verify Revocation
//         assertEq(PrimaryLayer.hasRoleSince(mem.member, 1), 0, "Member should NOT have Primary Role 1 after revocation");
//     }

//     function test_IdeasSubDAO_Election() public {
//         _deployIdeasSubDAO();

//         // --- Setup User (Member) ---
//         mem.user = address(0x100);
//         vm.prank(address(mem.ideasSubDAOAddress)); // Setup Initiator of Ideas Layer is itself
//         Powers(payable(mem.ideasSubDAOAddress)).assignRole(1, mem.user);
//         assertTrue(Powers(payable(mem.ideasSubDAOAddress)).hasRoleSince(mem.user, 1) != 0, "User should have Role 1 (Member)");

//         // --- Refactored Election Flow ---
//         vm.startPrank(mem.user);
//         mem.nonce = 100;

//         // 1. Create Election (Mandate 8)
//         console.log("Creating Election...");
//         mem.startBlock = uint48(block.number + 50);
//         mem.endBlock = uint48(block.number + 100);
//         mem.electionParams = abi.encode("Convener Election", mem.startBlock, mem.endBlock);

//         mem.createElectionId = findMandateIdInOrg("Create a Convener election: an election for the convener role can be initiated be any member.", Powers(payable(mem.ideasSubDAOAddress)));
//         Powers(payable(mem.ideasSubDAOAddress)).request(mem.createElectionId, mem.electionParams, mem.nonce, "Create Election - Request");

//         // 2. Nominate (Mandate 9)
//         console.log("Nominating...");
//         mem.nominateId = findMandateIdInOrg("Nominate for election: any member can nominate for an election.", Powers(payable(mem.ideasSubDAOAddress)));
//         Powers(payable(mem.ideasSubDAOAddress)).request(mem.nominateId, mem.electionParams, mem.nonce, "Nominate - Request");

//         // 3. Open Vote (Mandate 11)
//         console.log("Creating Vote...");
//         vm.roll(mem.startBlock + 1); // Advance to start
//         mem.openVoteId = findMandateIdInOrg("Open voting for Convener election: Members can open the vote for a convener election. This will create a dedicated vote mandate.", Powers(payable(mem.ideasSubDAOAddress)));
//         mem.actionId = Powers(payable(mem.ideasSubDAOAddress)).request(mem.openVoteId, mem.electionParams, mem.nonce, "Open Vote - Request");

//         // Get Vote Mandate ID
//         mem.returnData = Powers(payable(mem.ideasSubDAOAddress)).getActionReturnData(mem.actionId, 0);
//         mem.voteMandateId = abi.decode(mem.returnData, (uint256));
//         console.log("Vote Mandate ID: %s", mem.voteMandateId);

//         // 4. Vote (Mandate = voteMandateId)
//         console.log("Voting...");
//         // mem.votes = new bool[](1);
//         // mem.votes[0] = true;
//         mem.params = abi.encode(true);

//         Powers(payable(mem.ideasSubDAOAddress)).request(uint16(mem.voteMandateId), mem.params, mem.nonce, "Vote - Request");

//         // 5. Tally (Mandate 12)
//         console.log("Tallying...");
//         vm.roll(mem.endBlock + 1); // Advance to end
//         mem.tallyElectionId = findMandateIdInOrg("Tally Convener elections: After a convener election has finished, assign the Convener role to the winners.", Powers(payable(mem.ideasSubDAOAddress)));
//         Powers(payable(mem.ideasSubDAOAddress)).request(mem.tallyElectionId, mem.electionParams, mem.nonce, "Tally - Request");

//         // 6. Clean Up (Mandate 13)
//         console.log("Cleaning Up...");
//         // Verify Vote Mandate Active
//         (,, mem.isActive) = Powers(payable(mem.ideasSubDAOAddress)).getAdoptedMandate(uint16(mem.voteMandateId));
//         assertTrue(mem.isActive, "Vote Mandate should be active before cleanup");

//         // Clean up needs same calldata and nonce as Open Vote to find the return value
//         mem.cleanupElectionId = findMandateIdInOrg("Clean up Convener election: After a convener election has finished, clean up related mandates.", Powers(payable(mem.ideasSubDAOAddress)));
//         Powers(payable(mem.ideasSubDAOAddress)).request(mem.cleanupElectionId, mem.electionParams, mem.nonce, "Clean Up - Request");

//         // Verify Vote Mandate Revoked
//         (,, mem.isActive) = Powers(payable(mem.ideasSubDAOAddress)).getAdoptedMandate(uint16(mem.voteMandateId));
//         assertFalse(mem.isActive, "Vote Mandate should be revoked after cleanup");

//         vm.stopPrank();

//         // Verify Result
//         assertTrue(Powers(payable(mem.ideasSubDAOAddress)).hasRoleSince(mem.user, 2) != 0, "User should have Role 2 (Convener)");
//     }

//     function test_IdeasSubDAO_MembershipAndModeration() public {
//         _deployIdeasSubDAO();

//         // --- Step 1: Assign Moderator Role & execute setup ---
//         mem.moderator = address(0xCAFE);
//         mem.applicant = address(0xDEAF);
//         Powers(payable(mem.ideasSubDAOAddress)).request(1, "", 0, "");

//         mem.assignModeratorId = findMandateIdInOrg("Assign Moderator Role: Conveners can assign the Moderator role to an account.", Powers(payable(mem.ideasSubDAOAddress)));
//         mem.applyMembershipId = findMandateIdInOrg("Apply for Membership: Anyone can apply for membership to the DAO by submitting an application.", Powers(payable(mem.ideasSubDAOAddress)));
//         mem.assignMembershipId = findMandateIdInOrg("Assess and Assign Membership: Moderators can assess applications and assign membership to applicants.", Powers(payable(mem.ideasSubDAOAddress)));
//         mem.revokeMembershipId = findMandateIdInOrg("Revoke Membership: Moderators can revoke membership from members.", Powers(payable(mem.ideasSubDAOAddress)));
//         mem.revokeModeratorId = findMandateIdInOrg("Revoke Moderator Role: Conveners can revoke the Moderator role from an account.", Powers(payable(mem.ideasSubDAOAddress)));

//         mem.params = abi.encode(mem.moderator);
//         mem.nonce = 100;

//         vm.startPrank(cedars);
//         console.log("Assigning Moderator...");
        
//         mem.actionId = Powers(payable(mem.ideasSubDAOAddress)).propose(mem.assignModeratorId, mem.params, mem.nonce, "Assign Moderator - Request");
//         Powers(payable(mem.ideasSubDAOAddress)).castVote(mem.actionId, 1);
        
//         mem.votingPeriod = Powers(payable(mem.ideasSubDAOAddress)).getConditions(mem.assignModeratorId).votingPeriod;
//         vm.roll(block.number + mem.votingPeriod + 1);
        
//         Powers(payable(mem.ideasSubDAOAddress)).request(mem.assignModeratorId, mem.params, mem.nonce, "Assign Moderator - Request");
//         vm.stopPrank();

//         assertTrue(Powers(payable(mem.ideasSubDAOAddress)).hasRoleSince(mem.moderator, 3) > 0, "Moderator should have Role 3");

//         // --- Step 2: Apply and Assign Membership ---
//         mem.appParams = abi.encode(mem.applicant, "ipfs://application");
   
//         vm.startPrank(mem.applicant);
//         console.log("Applying for Membership...");
//         Powers(payable(mem.ideasSubDAOAddress)).request(mem.applyMembershipId, mem.appParams, mem.nonce, "Apply for Membership - Request");
//         vm.stopPrank();

//         vm.startPrank(mem.moderator);
//         console.log("Assigning Membership...");
//         Powers(payable(mem.ideasSubDAOAddress)).request(mem.assignMembershipId, mem.appParams, mem.nonce, "Assign Membership - Request");
//         vm.stopPrank();

//         assertTrue(Powers(payable(mem.ideasSubDAOAddress)).hasRoleSince(mem.applicant, 1) > 0, "Applicant should have Role 1 (Member)");

//         // --- Step 3: Revoke Membership ---
        
//         vm.startPrank(mem.moderator);
//         console.log("Revoking Membership...");
//         mem.actionId = Powers(payable(mem.ideasSubDAOAddress)).propose(mem.revokeMembershipId, mem.appParams, mem.nonce, "Revoke Membership - Propose");
//         vm.stopPrank();
        
//         mem.amountRoleHolders = Powers(payable(mem.ideasSubDAOAddress)).getAmountRoleHolders(3);
//         for (uint256 i = 0; i < mem.amountRoleHolders; i++) {
//             mem.member = Powers(payable(mem.ideasSubDAOAddress)).getRoleHolderAtIndex(3, i);
//             vm.prank(mem.member);
//             Powers(payable(mem.ideasSubDAOAddress)).castVote(mem.actionId, 1);
//         }
        
//         mem.votingPeriod = Powers(payable(mem.ideasSubDAOAddress)).getConditions(mem.revokeMembershipId).votingPeriod;
//         mem.timelock = Powers(payable(mem.ideasSubDAOAddress)).getConditions(mem.revokeMembershipId).timelock;
//         vm.roll(block.number + mem.votingPeriod + mem.timelock + 1);
        
//         vm.prank(mem.moderator);
//         Powers(payable(mem.ideasSubDAOAddress)).request(mem.revokeMembershipId, mem.appParams, mem.nonce, "Revoke Membership - Request");
 
//         assertTrue(Powers(payable(mem.ideasSubDAOAddress)).hasRoleSince(mem.applicant, 1) == 0, "Applicant should NOT have Role 1 anymore");

//         // --- Step 4: Revoke Moderator ---
//         mem.revokeParams = abi.encode(mem.moderator);
        
//         vm.startPrank(cedars);
//         console.log("Revoking Moderator...");
//         mem.actionId = Powers(payable(mem.ideasSubDAOAddress)).propose(mem.revokeModeratorId, mem.revokeParams, mem.nonce, "Revoke Moderator - Request");
//         vm.stopPrank();

//         mem.amountRoleHolders = Powers(payable(mem.ideasSubDAOAddress)).getAmountRoleHolders(2);
//         for (uint256 i = 0; i < mem.amountRoleHolders; i++) {
//             mem.member = Powers(payable(mem.ideasSubDAOAddress)).getRoleHolderAtIndex(2, i);
//             vm.prank(mem.member);
//             Powers(payable(mem.ideasSubDAOAddress)).castVote(mem.actionId, 1);
//         }
        
//         mem.votingPeriod = Powers(payable(mem.ideasSubDAOAddress)).getConditions(mem.revokeModeratorId).votingPeriod;
//         vm.roll(block.number + mem.votingPeriod + 1);
        
//         vm.prank(cedars);
//         Powers(payable(mem.ideasSubDAOAddress)).request(mem.revokeModeratorId, mem.revokeParams, mem.nonce, "Revoke Moderator - Request");
 
//         assertTrue(Powers(payable(mem.ideasSubDAOAddress)).hasRoleSince(mem.moderator, 3) == 0, "Moderator should NOT have Role 3 anymore");
//     }

//     //////////////////////////////////////////////////////////////////////////////////
//     //                             Helper Functions                                 //
//     //////////////////////////////////////////////////////////////////////////////////  
//     function findMandateIdInOrg(string memory description, Powers org) public view returns (uint16) {
//         uint16 counter = org.mandateCounter();
//         for (uint16 i = 1; i < counter; i++) {
//             (address mandateAddress, , ) = org.getAdoptedMandate(i);
//             string memory mandateDesc = Mandate(mandateAddress).getNameDescription(address(org), i);
//             if (Strings.equal(mandateDesc, description)) {
//                 return i;
//             }
//         }
//         revert(string.concat("Mandate not found: ", description));
//     }

//     function _deployIdeasSubDAO() internal {
//         // --- Step 1: Initiate Ideas Layer (Members) ---
//         vm.startPrank(mem.admin);

//         mem.params = abi.encode("Ideas Layer", "ipfs://ideas");
//         mem.nonce++; // Ensure nonce is managed.

//         // Propose
//         mem.actionId = PrimaryLayer.propose(mem.initiateIdeasMandateId, mem.params, mem.nonce, "Initiate Ideas Layer");
//         vm.stopPrank();

//         // Vote (Members)
//         uint256 amountRole1Holders = PrimaryLayer.getAmountRoleHolders(1);
//         for (uint256 i = 0; i < amountRole1Holders; i++) {
//             address roleHolder = PrimaryLayer.getRoleHolderAtIndex(1, i);
//             vm.prank(roleHolder);
//             PrimaryLayer.castVote(mem.actionId, 1); // 1 = For
//         }

//         // Wait for voting period
//         mem.votingPeriod = PrimaryLayer.getConditions(mem.initiateIdeasMandateId).votingPeriod;
//         vm.roll(block.number + mem.votingPeriod + 1);

//         // Execute (Request)
//         vm.startPrank(mem.admin);
//         PrimaryLayer.request(mem.initiateIdeasMandateId, mem.params, mem.nonce, "Initiate Ideas Layer");
//         vm.stopPrank();

//         // --- Step 2: Create Ideas Layer (Executives) ---
//         vm.startPrank(mem.admin);

//         // Propose
//         mem.actionId = PrimaryLayer.propose(mem.createIdeasMandateId, mem.params, mem.nonce, "Create Ideas Layer");

//         // Vote
//         PrimaryLayer.castVote(mem.actionId, 1);

//         // Wait
//         mem.votingPeriod = PrimaryLayer.getConditions(mem.createIdeasMandateId).votingPeriod;
//         vm.roll(block.number + mem.votingPeriod + 1);

//         // Execute
//         mem.actionId = PrimaryLayer.request(mem.createIdeasMandateId, mem.params, mem.nonce, "Create Ideas Layer");
//         vm.stopPrank();

//         // --- Step 3: Assign Role Id (Executives) ---
//         vm.startPrank(mem.admin);

//         // Execute (No quorum, immediate execution)
//         PrimaryLayer.request(mem.assignRoleMandateId, mem.params, mem.nonce, "Assign Role 4 to Ideas Layer");
//         vm.stopPrank();

//         // --- Store Address ---
//         mem.returnData = PrimaryLayer.getActionReturnData(mem.actionId, 0);
//         mem.ideasSubDAOAddress = abi.decode(mem.returnData, (address));

//         vm.prank(mem.admin);
//         Powers(payable(mem.ideasSubDAOAddress)).request(1, "", 0, ""); // Ping to initialize

//         console.log("Ideas Layer deployed at: %s", mem.ideasSubDAOAddress);
//     }

//     function _deployPhysicalSubDAO() internal {
//         // Requires mem.ideasSubDAOAddress to be set and have Role 4.
        
//         mem.params = abi.encode("Physical Layer", "ipfs://physical");
//         mem.nonce++; // Increment nonce
        
//         console.log("Initiating Physical Layer...");
//         // Propose (By Ideas Layer - Role 4)
//         vm.prank(mem.ideasSubDAOAddress);
//         PrimaryLayer.request(mem.initiatePhysicalId, mem.params, mem.nonce, "Initiate Physical Layer");

//         // --- Step 2: Deploy & Register Merit Badge Contract ---
//         // deploy Merit Badge Contract (Cedars/Exec)
//         // vm.prank(cedars);
//         // PrimaryLayer.request(mem.deployMeritBadgeId, mem.params, mem.nonce, "Deploy Merit Badge Contract");

//         // // Add dependency to Create Physical Layer mandate (Cedars/Exec)
//         // vm.prank(cedars);
//         // PrimaryLayer.request(mem.addDependencyId, mem.params, mem.nonce, "Add dependency: Merit Badge Contract");

//         // --- Step 3: Create Physical Layer ---
//         console.log("Creating Physical Layer...");
//         vm.prank(cedars);
//         mem.actionId = PrimaryLayer.propose(mem.createPhysicalId, mem.params, mem.nonce, "Create Physical Layer Propose");

//         // Vote (Executives - Role 2)
//         mem.numberOfRole1Holders = PrimaryLayer.getAmountRoleHolders(2);
//         for (uint256 i = 0; i < mem.numberOfRole1Holders; i++) {
//             address voter = PrimaryLayer.getRoleHolderAtIndex(2, i);
//             vm.prank(voter);
//             PrimaryLayer.castVote(mem.actionId, 1);
//         }

//         vm.roll(block.number + PrimaryLayer.getConditions(mem.createPhysicalId).votingPeriod + 1);
//         vm.prank(cedars);
//         mem.actionId = PrimaryLayer.request(mem.createPhysicalId, mem.params, mem.nonce, "Create Physical Layer Request");

//         // Get address
//         mem.returnData = PrimaryLayer.getActionReturnData(mem.actionId, 0);
//         mem.physicalSubDAOAddress = abi.decode(mem.returnData, (address));
//         console.log("Physical Layer created at: %s", mem.physicalSubDAOAddress);

//         // --- Step 3: Assign Role ---
//         console.log("Assigning Role...");
//         vm.startPrank(cedars);
//         PrimaryLayer.request(mem.assignRoleId, mem.params, mem.nonce, "Assign Role 3 to Physical Layer");

//         // --- Step 4: Assign Delegate Status ---
//         // (Necessary for Allowance Module)
//         PrimaryLayer.request(mem.assignDelegateId, mem.params, mem.nonce, "Assign Delegate Status");
        
//         // step 5: Ping layer to initialize (so that it can receive the role assignment and delegate status)
//         Powers(payable(mem.physicalSubDAOAddress)).request(1, "", 0, ""); // Ping to initialize
        
//         vm.stopPrank();
//     }


// }
