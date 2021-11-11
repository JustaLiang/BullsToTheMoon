import {HardhatRuntimeEnvironment} from 'hardhat/types';
import {DeployFunction} from 'hardhat-deploy/types';
import { ethers } from 'hardhat';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
    const { deploy } = hre.deployments;
    const deployer = (await hre.getUnnamedAccounts())[0];

    // the following will only deploy "GenericMetaTxProcessor" if the contract was never deployed or if the code changed since last deployment
    await deploy("BullsToTheMoon", {
        from: deployer,
        // gas: 4000000,
        args: [ethers.constants.AddressZero],
    });
};
export default func;