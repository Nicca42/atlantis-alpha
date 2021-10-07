const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Basic DAO testing", () => {
    var deployer, proposer, voter_one, voter_two, voter_three;
    var core, coordinator, executable, proposals, voteWeight, votingBooth, 
        simpleMajority, testExecutable, govToken, repToken, timer;
    let exeID;

    beforeEach(async () => {
        [
            deployer,
            proposer,
            voter_one,
            voter_two,
            voter_three
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

            let status = await proposals.getPropVotables(propID);

            console.log(status)
            // expect(
            //     status.state
            // ).to.equal(
            //     testSettings.executable.calldata[1]
            // );
        });
    });

    it("Can execute executable", async () => {

    });

    it("Can create prop executable", async () => {

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
            voteFormat: "bool"
        },
        proposals: {
            minDelay: 15,
            startDelay: 15,
            endDelay: 15
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