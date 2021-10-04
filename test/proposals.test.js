const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Proposal contract isolation testing", () => {
    var deployer, user, mock;
    var core, coordinator, executable, proposals, testExecutable;

    beforeEach(async () => {
        [
            deployer,
            user,
            mock
        ] = await ethers.getSigners();

        const Core = await ethers.getContractFactory("Core");
        const Coordinator = await ethers.getContractFactory("Coordinator");
        const Executable = await ethers.getContractFactory("Executables");
        const Proposals = await ethers.getContractFactory("Proposals")
        const TestExecutable = await ethers.getContractFactory("TestExecutable");

        core = await Core.deploy();
        executable = await Executable.deploy(core.address);
        coordinator = await Coordinator.deploy(core.address);
        proposals = await Proposals.deploy(core.address);
        testExecutable = await TestExecutable.deploy();

        await core.initialise(
            coordinator.address,
            executable.address,
            proposals.address,
            "0x0000000000000000000000000000000000000000",
            "0x0000000000000000000000000000000000000000",
            "0x0000000000000000000000000000000000000000"
        );
    });

    it("Proposals", async () => {
        let exe = await (await executable.connect(user).createExe(
            [testExecutable.address, testExecutable.address],
            testExe.funcSig,
            testExe.bytes,
            testExe.values,
            testExe.description
        )).wait();

        let exeID = exe.events[0].args.exeID;
        
        let proposal = await (await proposals.connect(user).createPropWithExe(
            testExe.propDescription,
            mock.address,
            exeID,
            exeID
        )).wait();

        console.log(exeID);
        console.log(proposal.events[1].args.exeID);

        let propExe = await executable.getExeInfo(proposal.events[1].args.exeID);

        console.log( await propExe.description)
    });

    let testExe = {
        funcSig: ["setNumber(uint256)", "setBytes(bytes32)"],
        bytes: [
            "0x0000000000000000000000000000000000000000000000000000000000000001",
            "0x0000000000000000000000000000000000000000000000000000000000000001"
        ],
        calldata: [
            "0x3fb5c1cb0000000000000000000000000000000000000000000000000000000000000001",
            "0xe6748da90000000000000000000000000000000000000000000000000000000000000001"
        ],
        values: [0, 0],
        description: "A test executable.",
        propDescription: "A proposal description"
    };
});