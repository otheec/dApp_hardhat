// scripts/deploy.js

const hre = require("hardhat");

async function main() {
    // Deploy LoanToken
    const LoanToken = await hre.ethers.getContractFactory("LoanToken");
    const loanToken = await LoanToken.deploy(1000000);

    await loanToken.waitForDeployment();
    console.log("LoanToken deployed to:", loanToken.target);

    // Deploy AssignmentP2P with the address of the deployed LoanToken
    const ERC20_assigment = await hre.ethers.getContractFactory("ERC20_assigment");
    const erc20_assigment = await ERC20_assigment.deploy(loanToken.target);

    await erc20_assigment.waitForDeployment();
    console.log("ERC20_assigment deployed to:", erc20_assigment.target);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
