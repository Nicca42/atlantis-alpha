const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Basic DAO testing", () => {
    var deployer, proposer, voter_one, voter_two, voter_three, voter_four;
    var core, coordinator, executable, proposals, voteWeight, votingBooth, 
        simpleMajority, testExecutable, govToken, repToken, timer;
    let exeID, propID, propExeID, status;

    beforeEach(async () => {
        [
            deployer,
            proposer,
            voter_one,
            voter_two,
            voter_three,
            voter_four
        ] = await ethers.getSigners();

        const Core = await ethers.getContractFactory("Core");
        const Coordinator = await ethers.getContractFactory("Coordinator");
        const Executable = await ethers.getContractFactory("Executables");
        const Proposals = await ethers.getContractFactory("Proposals");
        const VotingBooth = await ethers.getContractFactory("VotingBooth");
        const VoteWeight = await ethers.getContractFactory("VoteWeight");
        const SimpleMajority = await ethers.getContractFactory("SimpleMajority");
        const TestExecutable = await ethers.getContractFactory("TestExecutable");
        const Token = await ethers.getContractFactory("Token");
        const Timer = await ethers.getContractFactory("Timer");

        timer = await Timer.deploy();
        testExecutable = await TestExecutable.deploy(timer.address);
        repToken = await Token.deploy(
            testSettings.tokens.rep.name,
            testSettings.tokens.rep.symbol
        );
        govToken = await Token.deploy(
            testSettings.tokens.gov.name,
            testSettings.tokens.gov.symbol
        );

        core = await Core.deploy();
        coordinator = await Coordinator.deploy(core.address, timer.address);
        executable = await Executable.deploy(core.address, timer.address);
        proposals = await Proposals.deploy(core.address, timer.address);
        votingBooth = await VotingBooth.deploy(core.address, timer.address);
        voteWeight = await VoteWeight.deploy(core.address, timer.address);
        simpleMajority = await SimpleMajority.deploy(core.address, timer.address);

        await core.initialise(
            coordinator.address,
            executable.address,
            proposals.address,
            voteWeight.address,
            votingBooth.address
        );

        await votingBooth.initialise(
            simpleMajority.address,
            testSettings.voteType.id,
            testSettings.voteType.voteFormat
        );

        await voteWeight.initialise(
            govToken.address,
            repToken.address
        );
        
        await proposals.initialise(
            testSettings.proposals.minDelay,
            testSettings.proposals.startDelay,
            testSettings.proposals.endDelay
        );

        await govToken.mint(proposer.address, 10);
        await govToken.mint(voter_one.address, 10);
        await govToken.mint(voter_two.address, 100);
        await govToken.mint(voter_three.address, 1000);

        await repToken.mint(proposer.address, 1000);
        await repToken.mint(voter_one.address, 100);
        await repToken.mint(voter_two.address, 10);
        await repToken.mint(voter_three.address, 1);
    });

    describe("Executable testing", async () => {
        it("Can create an executable", async () => {
            let exe = await (await executable.createExe(
                [testExecutable.address, testExecutable.address],
                testSettings.executable.funcSig,
                testSettings.executable.bytes,
                testSettings.executable.values,
                testSettings.executable.description
            )).wait();
    
            let exeID = exe.events[0].args.exeID;
            let stored = await executable.getExe(exeID);
    
            expect(stored.targets[0]).to.equal(testExecutable.address);
            expect(stored.callData[0]).to.equal(testSettings.executable.calldata[0]);
            expect(stored.callData[1]).to.equal(testSettings.executable.calldata[1]);
        });

        it("Can't create bad executable", async () => {
            await expect(
                executable.createExe(
                    [testExecutable.address],
                    testSettings.executable.funcSig,
                    testSettings.executable.bytes,
                    testSettings.executable.values,
                    testSettings.executable.description
                )
            ).to.be.revertedWith('Exe: Array length mismatch');
            await expect(
                executable.createExe(
                    [testExecutable.address, testExecutable.address],
                    testSettings.executable.badFuncSig,
                    testSettings.executable.bytes,
                    testSettings.executable.values,
                    testSettings.executable.description
                )
            ).to.be.revertedWith('Exe: Array length mismatch');
            await expect(
                executable.createExe(
                    [testExecutable.address, testExecutable.address],
                    testSettings.executable.funcSig,
                    testSettings.executable.badBytes,
                    testSettings.executable.values,
                    testSettings.executable.description
                )
            ).to.be.revertedWith('Exe: Array length mismatch');
            await expect(
                executable.createExe(
                    [testExecutable.address, testExecutable.address],
                    testSettings.executable.funcSig,
                    testSettings.executable.bytes,
                    testSettings.executable.badValues,
                    testSettings.executable.description
                )
            ).to.be.revertedWith('Exe: Array length mismatch');
        });
    });

    describe("Proposal testing", async () => {
        beforeEach(async () => {
            let exe = await (await executable.createExe(
                [testExecutable.address, testExecutable.address],
                testSettings.executable.funcSig,
                testSettings.executable.bytes,
                testSettings.executable.values,
                testSettings.executable.description
            )).wait();
            exeID = exe.events[0].args.exeID;
        });

        it("Can create a proposal", async () => {
            let proposal = await (await proposals.connect(proposer).createPropWithExe(
                "Proposal to distribute reputation rewards to proposer.",
                testSettings.voteType.id,
                exeID
            )).wait();

            propID = proposal.events[1].args.propID.toString();
            propExeID = proposal.events[1].args.exeID.toString();

            status = await proposals.getPropVotables(propID);

            expect(
                propID.toString()
            ).to.equal(
                '1'
            );
            expect(
                status.state
            ).to.equal(
                1
            );
            expect(
                status.spent
            ).to.equal(
                false
            );
        });

        it("Can't create bad proposal", async () => {
            await expect(
                proposals.connect(proposer).createPropWithExe(
                    "Proposal to distribute reputation rewards to proposer.",
                    testSettings.voteType.id,
                    testSettings.proposals.badExeID
                )
            ).to.be.revertedWith('Exe: Exe does not exist');
            await expect(
                proposals.connect(proposer).createPropWithExe(
                    "Proposal to distribute reputation rewards to proposer.",
                    testSettings.voteType.badId,
                    exeID
                )
            ).to.be.revertedWith('Prop: Invalid vote type');
        });
    });

    describe("Voting testing", async () => {
        beforeEach(async () => {
            let exe = await (await executable.createExe(
                [testExecutable.address, testExecutable.address],
                testSettings.executable.funcSig,
                testSettings.executable.bytes,
                testSettings.executable.values,
                testSettings.executable.description
            )).wait();
            exeID = exe.events[0].args.exeID;

            let proposal = await (await proposals.connect(proposer).createPropWithExe(
                "Proposal to distribute reputation rewards to proposer.",
                testSettings.voteType.id,
                exeID
            )).wait();

            propID = proposal.events[1].args.propID.toString();
            propExeID = proposal.events[1].args.exeID.toString();

            status = await proposals.getPropVotables(propID);
            await timer.setCurrentTime(status.voteStart); 
        });

        it("Can vote for proposal", async () => {
            let voteFor = await simpleMajority.encodeBallot(true);

            await votingBooth.connect(proposer).vote(propID, voteFor);

            let currentVote = await simpleMajority.getCurrentVote(propID);
            let voterStatus = await simpleMajority.hasVoted(propID, proposer.address);

            expect(
                voterStatus
            ).to.equal(
                true
            );
            expect(
                currentVote.weightFor.toString()
            ).to.equal(
                '1010'
            );
            expect(
                currentVote.weightAgainst.toString()
            ).to.equal(
                '0'
            );
            expect(
                currentVote.voterTurnout.toString()
            ).to.equal(
                '1'
            );
        });

        it("Can vote against proposal", async () => {
            let voteAgainst = await simpleMajority.encodeBallot(false);

            await votingBooth.connect(proposer).vote(propID, voteAgainst);

            let currentVote = await simpleMajority.getCurrentVote(propID);
            let voterStatus = await simpleMajority.hasVoted(propID, proposer.address);

            expect(
                voterStatus
            ).to.equal(
                true
            );
            expect(
                currentVote.weightAgainst.toString()
            ).to.equal(
                '1010'
            );
            expect(
                currentVote.weightFor.toString()
            ).to.equal(
                '0'
            );
            expect(
                currentVote.voterTurnout.toString()
            ).to.equal(
                '1'
            );
        });

        it("Can't vote on bad proposal", async () => {
            let voteFor = await simpleMajority.encodeBallot(true);
            let voteAgainst = await simpleMajority.encodeBallot(false);

            await expect(
                votingBooth.connect(proposer).vote('0', voteAgainst)
            ).to.be.revertedWith('Booth: Invalid vote type/prop');
            await expect(
                votingBooth.connect(proposer).vote(propID, '0x01')
            ).to.be.revertedWith('Con: Vote incorrectly formatted');
        });

        it("Can't vote before start", async () => {
            let voteFor = await simpleMajority.encodeBallot(true);
            let voteAgainst = await simpleMajority.encodeBallot(false);

            await timer.setCurrentTime(status.voteStart - 1); 

            await expect(
                votingBooth.connect(proposer).vote(propID, voteFor)
            ).to.be.revertedWith('Coord: prop not votable');
        });

        it("Can't vote after end", async () => {
            let voteFor = await simpleMajority.encodeBallot(true);
            let voteAgainst = await simpleMajority.encodeBallot(false);

            await timer.setCurrentTime(status.voteEnd + 1); 

            await expect(
                votingBooth.connect(proposer).vote(propID, voteFor)
            ).to.be.revertedWith('Coord: prop not votable');
        });
    });

    describe("Quorum testing", async () => {
        beforeEach(async () => {
            let exe = await (await executable.createExe(
                [testExecutable.address, testExecutable.address],
                testSettings.executable.funcSig,
                testSettings.executable.bytes,
                testSettings.executable.values,
                testSettings.executable.description
            )).wait();
            exeID = exe.events[0].args.exeID;

            let proposal = await (await proposals.connect(proposer).createPropWithExe(
                "Proposal to distribute reputation rewards to proposer.",
                testSettings.voteType.id,
                exeID
            )).wait();

            propID = proposal.events[1].args.propID.toString();
            propExeID = proposal.events[1].args.exeID.toString();

            status = await proposals.getPropVotables(propID);
            await timer.setCurrentTime(status.voteStart); 
        });

        it("Proposal passes correctly", async () => {
            let voteFor = await simpleMajority.encodeBallot(true);
            let voteAgainst = await simpleMajority.encodeBallot(false);

            await votingBooth.connect(voter_one).vote(propID, voteFor);
            let consensus = await simpleMajority.consensusReached(propID);
            
            await votingBooth.connect(voter_two).vote(propID, voteAgainst);
            let consensus1 = await simpleMajority.consensusReached(propID);
            
            await votingBooth.connect(proposer).vote(propID, voteFor);
            let consensus2 = await simpleMajority.consensusReached(propID);

            await votingBooth.connect(voter_three).vote(propID, voteFor);
            let consensus3 = await simpleMajority.consensusReached(propID);            
            let currentVote = await simpleMajority.getCurrentVote(propID);

            expect(
                currentVote.weightFor.toString()
            ).to.equal(
                '2121'
            );
            expect(
                currentVote.weightAgainst.toString()
            ).to.equal(
                '110'
            );
            expect(
                currentVote.voterTurnout.toString()
            ).to.equal(
                '4'
            );
            expect(
                consensus.reached
            ).to.equal(
                false
            );
            expect(
                consensus1.reached
            ).to.equal(
                false
            );
            expect(
                consensus2.reached
            ).to.equal(
                true
            );
            expect(
                consensus3.reached
            ).to.equal(
                true
            );
            expect(
                consensus.votePassed
            ).to.equal(
                true
            );
            expect(
                consensus1.votePassed
            ).to.equal(
                false
            );
            expect(
                consensus2.votePassed
            ).to.equal(
                true
            );
            expect(
                consensus3.votePassed
            ).to.equal(
                true
            );
        });

        it("Proposal fails correctly", async () => {
            let voteFor = await simpleMajority.encodeBallot(true);
            let voteAgainst = await simpleMajority.encodeBallot(false);

            await votingBooth.connect(voter_one).vote(propID, voteFor);
            let consensus = await simpleMajority.consensusReached(propID);
            
            await votingBooth.connect(voter_two).vote(propID, voteAgainst);
            let consensus1 = await simpleMajority.consensusReached(propID);
            
            await votingBooth.connect(proposer).vote(propID, voteAgainst);
            let consensus2 = await simpleMajority.consensusReached(propID);

            await votingBooth.connect(voter_three).vote(propID, voteAgainst);
            let consensus3 = await simpleMajority.consensusReached(propID);            
            let currentVote = await simpleMajority.getCurrentVote(propID);

            expect(
                currentVote.weightAgainst.toString()
            ).to.equal(
                '2121'
            );
            expect(
                currentVote.weightFor.toString()
            ).to.equal(
                '110'
            );
            expect(
                currentVote.voterTurnout.toString()
            ).to.equal(
                '4'
            );
            expect(
                consensus.reached
            ).to.equal(
                false
            );
            expect(
                consensus1.reached
            ).to.equal(
                false
            );
            expect(
                consensus2.reached
            ).to.equal(
                true
            );
            expect(
                consensus3.reached
            ).to.equal(
                true
            );
            expect(
                consensus.votePassed
            ).to.equal(
                true
            );
            expect(
                consensus1.votePassed
            ).to.equal(
                false
            );
            expect(
                consensus2.votePassed
            ).to.equal(
                false
            );
            expect(
                consensus3.votePassed
            ).to.equal(
                false
            );
        });

        it("Proposal ties correctly (fails)", async () => {
            await govToken.mint(voter_four.address, 10);
            await repToken.mint(voter_four.address, 1000);

            let voteFor = await simpleMajority.encodeBallot(true);
            let voteAgainst = await simpleMajority.encodeBallot(false);

            await votingBooth.connect(proposer).vote(propID, voteFor);
            let consensus = await simpleMajority.consensusReached(propID);

            await votingBooth.connect(voter_four).vote(propID, voteAgainst);
            let consensus1 = await simpleMajority.consensusReached(propID);            
            let currentVote = await simpleMajority.getCurrentVote(propID);

            expect(
                currentVote.weightAgainst.toString()
            ).to.equal(
                '1010'
            );
            expect(
                currentVote.weightFor.toString()
            ).to.equal(
                '1010'
            );
            expect(
                currentVote.voterTurnout.toString()
            ).to.equal(
                '2'
            );
            expect(
                consensus.reached
            ).to.equal(
                false
            );
            expect(
                consensus1.reached
            ).to.equal(
                true
            );
            expect(
                consensus.votePassed
            ).to.equal(
                true
            );
            expect(
                consensus1.votePassed
            ).to.equal(
                false
            );
        });
    });

    describe("Queueing testing", async () => {
        beforeEach(async () => {
            let exe = await (await executable.createExe(
                [testExecutable.address, testExecutable.address],
                testSettings.executable.funcSig,
                testSettings.executable.bytes,
                testSettings.executable.values,
                testSettings.executable.description
            )).wait();
            exeID = exe.events[0].args.exeID;

            let proposal = await (await proposals.connect(proposer).createPropWithExe(
                "Proposal to distribute reputation rewards to proposer.",
                testSettings.voteType.id,
                exeID
            )).wait();

            propID = proposal.events[1].args.propID.toString();
            propExeID = proposal.events[1].args.exeID.toString();

            status = await proposals.getPropVotables(propID);
            await timer.setCurrentTime(status.voteStart); 
        });

        it("Can't queue passed proposal before voting ends", async () => {
            let voteFor = await simpleMajority.encodeBallot(true);
            let voteAgainst = await simpleMajority.encodeBallot(false);

            await votingBooth.connect(voter_one).vote(propID, voteFor);
            await votingBooth.connect(voter_two).vote(propID, voteAgainst);
            await votingBooth.connect(proposer).vote(propID, voteFor);
            await votingBooth.connect(voter_three).vote(propID, voteFor);
            
            await expect(
                coordinator.connect(proposer).queueProposal(propID)
            ).to.be.revertedWith('Coord: voting active or executed');
        });

        it("Can queue passed proposal", async () => {
            let voteFor = await simpleMajority.encodeBallot(true);
            let voteAgainst = await simpleMajority.encodeBallot(false);

            await votingBooth.connect(voter_one).vote(propID, voteFor);
            await votingBooth.connect(voter_two).vote(propID, voteAgainst);
            await votingBooth.connect(proposer).vote(propID, voteFor);
            await votingBooth.connect(voter_three).vote(propID, voteFor);
            
            let statusBefore = await proposals.getPropVotables(propID);
            await timer.setCurrentTime(statusBefore.voteEnd);
            
            await coordinator.connect(proposer).queueProposal(propID)
            
            status = await proposals.getPropVotables(propID);

            expect(
                statusBefore.state
            ).to.equal(
                2
            );
            expect(
                statusBefore.spent
            ).to.equal(
                false
            );
            expect(
                status.state
            ).to.equal(
                3
            );
            expect(
                status.spent
            ).to.equal(
                false
            );
        });

        it("Can defeat failed proposal", async () => {
            let voteFor = await simpleMajority.encodeBallot(true);
            let voteAgainst = await simpleMajority.encodeBallot(false);

            await votingBooth.connect(voter_one).vote(propID, voteAgainst);
            await votingBooth.connect(voter_two).vote(propID, voteAgainst);
            await votingBooth.connect(proposer).vote(propID, voteAgainst);
            await votingBooth.connect(voter_three).vote(propID, voteFor);
            
            let statusBefore = await proposals.getPropVotables(propID);
            await timer.setCurrentTime(statusBefore.voteEnd);
            
            await coordinator.connect(proposer).queueProposal(propID)
            
            status = await proposals.getPropVotables(propID);

            expect(
                statusBefore.state
            ).to.equal(
                2
            );
            expect(
                statusBefore.spent
            ).to.equal(
                false
            );
            expect(
                status.state
            ).to.equal(
                6
            );
            expect(
                status.spent
            ).to.equal(
                true
            );
        });

        it("Can expire proposal", async () => {
            let voteFor = await simpleMajority.encodeBallot(true);

            await votingBooth.connect(voter_one).vote(propID, voteFor);
            
            let statusBefore = await proposals.getPropVotables(propID);
            await timer.setCurrentTime(statusBefore.voteEnd);
            
            await coordinator.connect(proposer).queueProposal(propID)
            
            status = await proposals.getPropVotables(propID);

            expect(
                statusBefore.state
            ).to.equal(
                2
            );
            expect(
                statusBefore.spent
            ).to.equal(
                false
            );
            expect(
                status.state
            ).to.equal(
                5
            );
            expect(
                status.spent
            ).to.equal(
                true
            );
        });
    });

    describe("Executing testing", async () => {
        beforeEach(async () => {
            let exe = await (await executable.createExe(
                [testExecutable.address, testExecutable.address],
                testSettings.executable.funcSig,
                testSettings.executable.bytes,
                testSettings.executable.values,
                testSettings.executable.description
            )).wait();
            exeID = exe.events[0].args.exeID;

            let proposal = await (await proposals.connect(proposer).createPropWithExe(
                "Proposal to distribute reputation rewards to proposer.",
                testSettings.voteType.id,
                exeID
            )).wait();

            propID = proposal.events[1].args.propID.toString();
            propExeID = proposal.events[1].args.exeID.toString();

            status = await proposals.getPropVotables(propID);
            await timer.setCurrentTime(status.voteStart); 
        });

        it("Can execute proposal", async () => {
            let voteFor = await simpleMajority.encodeBallot(true);
            let voteAgainst = await simpleMajority.encodeBallot(false);

            await votingBooth.connect(voter_one).vote(propID, voteFor);
            await votingBooth.connect(voter_two).vote(propID, voteAgainst);
            await votingBooth.connect(proposer).vote(propID, voteFor);
            await votingBooth.connect(voter_three).vote(propID, voteFor);

            let statusBefore = await proposals.getPropVotables(propID);
            await timer.setCurrentTime(statusBefore.voteEnd);
            
            await coordinator.connect(proposer).queueProposal(propID);
            let statusDuring = await proposals.getPropVotables(propID);

            await core.execute(propExeID);
            status = await proposals.getPropVotables(propID);

            expect(
                statusBefore.state
            ).to.equal(
                2
            );
            expect(
                statusBefore.spent
            ).to.equal(
                false
            );
            expect(
                statusDuring.state
            ).to.equal(
                3
            );
            expect(
                statusDuring.spent
            ).to.equal(
                false
            );
            expect(
                status.state
            ).to.equal(
                4
            );
            expect(
                status.spent
            ).to.equal(
                true
            );
        });

        it("Can't execute proposal before queueing", async () => {
            let voteFor = await simpleMajority.encodeBallot(true);
            let voteAgainst = await simpleMajority.encodeBallot(false);

            await votingBooth.connect(voter_one).vote(propID, voteFor);
            await votingBooth.connect(voter_two).vote(propID, voteAgainst);
            await votingBooth.connect(proposer).vote(propID, voteFor);
            await votingBooth.connect(voter_three).vote(propID, voteFor);

            let statusBefore = await proposals.getPropVotables(propID);
            await timer.setCurrentTime(statusBefore.voteEnd);

            await expect(
                core.execute(propExeID)
            ).to.be.revertedWith('Coord: exe not executable');
        });

        it("Can't execute proposal that does not reach quorum", async () => {
            let voteFor = await simpleMajority.encodeBallot(true);
            let voteAgainst = await simpleMajority.encodeBallot(false);

            await votingBooth.connect(voter_one).vote(propID, voteFor);

            let statusBefore = await proposals.getPropVotables(propID);
            await timer.setCurrentTime(statusBefore.voteEnd);
            
            await coordinator.connect(proposer).queueProposal(propID);

            await expect(
                core.execute(propExeID)
            ).to.be.revertedWith('Coord: exe not executable');
        });

        it("Can't execute proposal that is defeated", async () => {
            let voteFor = await simpleMajority.encodeBallot(true);
            let voteAgainst = await simpleMajority.encodeBallot(false);

            await votingBooth.connect(voter_one).vote(propID, voteAgainst);
            await votingBooth.connect(voter_two).vote(propID, voteAgainst);
            await votingBooth.connect(proposer).vote(propID, voteAgainst);
            await votingBooth.connect(voter_three).vote(propID, voteFor);

            let statusBefore = await proposals.getPropVotables(propID);
            await timer.setCurrentTime(statusBefore.voteEnd);
            
            await coordinator.connect(proposer).queueProposal(propID);

            await expect(
                core.execute(propExeID)
            ).to.be.revertedWith('Coord: exe not executable');
        });

        it("Can't execute proposal that has expired", async () => {
            let voteFor = await simpleMajority.encodeBallot(true);

            await votingBooth.connect(voter_one).vote(propID, voteFor);

            let statusBefore = await proposals.getPropVotables(propID);
            await timer.setCurrentTime(statusBefore.voteEnd);
            
            await coordinator.connect(proposer).queueProposal(propID);

            await expect(
                core.execute(propExeID)
            ).to.be.revertedWith('Coord: exe not executable');
        });
    });

    describe("Elevated permission functions testing", async () => {
        it("Core onlyCore", async () => {
            let bytesKey = await testExecutable.encodeBytes32("TEST_EXECUTABLE");
            let bytes1 = await testExecutable.encodeKeyAddress(
                bytesKey.toString(),
                testExecutable.address
            );
            let bytes2 = await testExecutable.encodeKeyAddress(
                bytesKey.toString(),
                voter_four.address
            );

            let exe = await (await executable.createExe(
                [
                    core.address,
                    core.address,
                    core.address
                ],
                [
                    "addContract(bytes32,address)",
                    "updateContract(bytes32,address)",
                    "deleteContract(bytes32)"
                ],
                [
                    bytes1.toString(), // key address
                    bytes2.toString(), // key new address
                    bytesKey.toString() // key
                ],
                [
                    0,
                    0,
                    0
                ],
                "Adding, updating then deleting a contract"
            )).wait();
            exeID = exe.events[0].args.exeID;

            let proposal = await (await proposals.connect(proposer).createPropWithExe(
                "Proposal to distribute reputation rewards to proposer.",
                testSettings.voteType.id,
                exeID
            )).wait();

            propID = proposal.events[1].args.propID.toString();
            propExeID = proposal.events[1].args.exeID.toString();

            status = await proposals.getPropVotables(propID);
            await timer.setCurrentTime(status.voteStart); 

            let voteFor = await simpleMajority.encodeBallot(true);
            let voteAgainst = await simpleMajority.encodeBallot(false);

            await votingBooth.connect(voter_one).vote(propID, voteFor);
            await votingBooth.connect(voter_two).vote(propID, voteFor);
            await votingBooth.connect(proposer).vote(propID, voteFor);
            await votingBooth.connect(voter_three).vote(propID, voteFor);

            let statusBefore = await proposals.getPropVotables(propID);
            await timer.setCurrentTime(statusBefore.voteEnd);
            
            await coordinator.connect(proposer).queueProposal(propID);

            await core.execute(propExeID);
        });

        it("Core onlyCore negatives", async () => {
            let bytesKey = await testExecutable.encodeBytes32("TEST_EXECUTABLE");

            await expect(
                core.connect(proposer).addContract(bytesKey, testExecutable.address)
            ).to.be.revertedWith('Core: Only exes can modify');
            await expect(
                core.connect(proposer).updateContract(bytesKey, testExecutable.address)
            ).to.be.revertedWith('Core: Only exes can modify');
            await expect(
                core.connect(proposer).deleteContract(bytesKey)
            ).to.be.revertedWith('Core: Only exes can modify');
        });

        it("Coordinator onlyCore & onlySystem negatives", async () => {
            let bytesKey = await testExecutable.encodeBytes32("TEST_EXECUTABLE");

            await expect(
                coordinator.connect(proposer).setExecute(exeID)
            ).to.be.revertedWith('System: Only core can modify');
            await expect(
                testExecutable.connect(proposer).addSub(
                    coordinator.address, 
                    bytesKey, 
                    testExecutable.address
                )
            ).to.be.revertedWith('Coord: Incorrect ID for sub');
        });

        it("Executable onlyProps negatives", async () => {
            await expect(
                executable.connect(proposer).createPropExe(propID, exeID, "test")
            ).to.be.revertedWith('Exe: Only prop can call');
        });

        it("Proposals onlyCore & OnlyCoord negatives", async () => {
            await expect(
                proposals.connect(proposer).updateMinDelay(123)
            ).to.be.revertedWith('System: Only core can modify');
            await expect(
                proposals.connect(proposer).updateDelays(123, 123)
            ).to.be.revertedWith('System: Only core can modify');
            await expect(
                proposals.connect(proposer).propVoting(propID)
            ).to.be.revertedWith('Prop: Only coord can call');
            await expect(
                proposals.connect(proposer).propExpire(propID)
            ).to.be.revertedWith('Prop: Only coord can call');
            await expect(
                proposals.connect(proposer).propDefeated(propID)
            ).to.be.revertedWith('Prop: Only coord can call');
            await expect(
                proposals.connect(proposer).propQueued(propID)
            ).to.be.revertedWith('Prop: Only coord can call');
            await expect(
                proposals.connect(proposer).propExecuted(propID)
            ).to.be.revertedWith('Prop: Only coord can call');
        });

        it("Voting booth onlyCore negatives", async () => {
            let bytesKey = await testExecutable.encodeBytes32("TEST_EXECUTABLE");

            await expect(
                votingBooth.connect(proposer).addVoteType(
                    bytesKey.toString(),
                    proposer.address,
                    "bool,uint256,uint256"
                )
            ).to.be.revertedWith('System: Only core can modify');
        });

        it("Initialiser tests", async () => {
            await expect(
                core.connect(proposer).initialise(
                    proposer.address,
                    proposer.address,
                    proposer.address,
                    proposer.address,
                    proposer.address
                )
            ).to.be.revertedWith('Init: Contract is initialized');
            
            await expect(
                votingBooth.initialise(
                    simpleMajority.address,
                    testSettings.voteType.id,
                    testSettings.voteType.voteFormat
                )
            ).to.be.revertedWith('Init: Contract is initialized');

            await expect(
                voteWeight.initialise(
                    govToken.address,
                    repToken.address
                )
            ).to.be.revertedWith('Init: Contract is initialized');

            await expect(
                proposals.initialise(
                    testSettings.proposals.minDelay,
                    testSettings.proposals.startDelay,
                    testSettings.proposals.endDelay
                )
            ).to.be.revertedWith('Init: Contract is initialized');
        });
    });

    let testSettings = {
        tokens: {
            rep: {
                name: "rep token",
                symbol: "REPT"
            },
            gov: {
                name: "gov token",
                symbol: "GOVT"

            },
        },
        voteType: {
            id: "0x53494d504c455f4d414a4f524954590000000000000000000000000000000000",
            badId: "0x0000000000000000000000000000000000000000000000000000000000000000",
            voteFormat: "bool"
        },
        proposals: {
            minDelay: 15,
            startDelay: 15,
            endDelay: 15,
            badExeID: "0x0000000000000000000000000000000000000000000000000000000000000000"
        },
        executable: {
            funcSig: ["setNumber(uint256)", "setBytes(bytes32)"],
            badFuncSig: ["setBytes(bytes32)"],
            bytes: [
                "0x0000000000000000000000000000000000000000000000000000000000000001",
                "0x0000000000000000000000000000000000000000000000000000000000000001"
            ],
            badBytes: [
                "0x0000000000000000000000000000000000000000000000000000000000000001"
            ],
            calldata: [
                "0x3fb5c1cb0000000000000000000000000000000000000000000000000000000000000001",
                "0xe6748da90000000000000000000000000000000000000000000000000000000000000001"
            ],
            badCalldata: [
                "0x3fb5c1cb0000000000000000000000000000000000000000000000000000000000000001"
            ],
            values: [0, 0],
            badValues: [0],
            description: "A test executable."
        }
    };
});