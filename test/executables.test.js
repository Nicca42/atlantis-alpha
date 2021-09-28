const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Executable contract isolation testing", () => {
    var deployer, core;
    var core, executable, testExecutable;

    beforeEach(async () => {
        [
            deployer,
            core
        ] = await ethers.getSigners();

        const Core = await ethers.getContractFactory("Core");
        const Executable = await ethers.getContractFactory("Executables");
        const TestExecutable = await ethers.getContractFactory("TestExecutable");

        testExecutable = await TestExecutable.deploy();
        core = await Core.deploy();
        executable = await Executable.deploy(core.address);

        await core.initialise(
            testExecutable.address,
            executable.address,
            "0x0000000000000000000000000000000000000000",
            "0x0000000000000000000000000000000000000000",
            "0x0000000000000000000000000000000000000000",
            "0x0000000000000000000000000000000000000000"
        );
    });

    it("Can create an executable", async () => {
        let exe = await (await executable.createExe(
            [testExecutable.address, testExecutable.address],
            testExe.funcSig,
            testExe.bytes,
            testExe.values,
            testExe.description
        )).wait();

        let exeID = exe.events[0].args.exeID;
        let stored = await executable.getExe(exeID);

        expect(stored.targets[0]).to.equal(testExecutable.address);
        expect(stored.callData[0]).to.equal(testExe.calldata[0]);
        expect(stored.callData[1]).to.equal(testExe.calldata[1]);
    });

    it("Can execute executable", async () => {
        let exe = await (await executable.createExe(
            [testExecutable.address, testExecutable.address],
            testExe.funcSig,
            testExe.bytes,
            testExe.values,
            testExe.description
        )).wait();

        let exeID = exe.events[0].args.exeID;

        await core.execute(exeID);

        let storedNumber = await testExecutable.aNumber();
        let storedAddress = await testExecutable.anAddress();
        let storedBytes = await testExecutable.aBytes();

        expect(storedNumber).to.equal(1);
        expect(storedAddress).to.equal(core.address);
        expect(storedBytes).to.equal(testExe.bytes[1]);
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
        description: "A test executable."
    }
});