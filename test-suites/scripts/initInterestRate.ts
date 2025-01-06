/* eslint-disable no-console */
/* eslint-disable no-await-in-loop */
import { BigNumber } from "@ethersproject/bignumber";
import { RateManager, rateStrategyStableTwo } from "../configs/rates";
import { AptosProvider } from "../wrappers/aptosProvider";
import { underlyingTokens } from "./createTokens";
import { AclManager } from "../configs/aclManage";
import chalk from "chalk";
import { DefaultInterestRateStrategyClient } from "../clients/defaultInterestRateStrategyClient";
import { AclClient } from "../clients/aclClient";

export async function initDefaultInteresRates() {
  // global aptos provider
  const aptosProvider = AptosProvider.fromEnvs();
  const defaultInterestRateStrategyClient = new DefaultInterestRateStrategyClient(aptosProvider, RateManager);
  const aclClient = new AclClient(aptosProvider, AclManager);
  const isRiskAdmin = await aclClient.isRiskAdmin(RateManager.accountAddress);
  if (!isRiskAdmin) {
    console.log(`Setting ${RateManager.accountAddress.toString()} to be asset risk and pool admin`);
    await aclClient.addRiskAdmin(RateManager.accountAddress);
    await aclClient.addPoolAdmin(RateManager.accountAddress);
  }
  console.log(`${RateManager.accountAddress.toString()} set to be risk and pool admin`);

  // set interest rate strategy fr each reserve
  for (const [, underlyingToken] of underlyingTokens.entries()) {
    const txReceipt = await defaultInterestRateStrategyClient.setReserveInterestRateStrategy(
      underlyingToken.accountAddress,
      BigNumber.from(rateStrategyStableTwo.optimalUsageRatio),
      BigNumber.from(rateStrategyStableTwo.baseVariableBorrowRate),
      BigNumber.from(rateStrategyStableTwo.variableRateSlope1),
      BigNumber.from(rateStrategyStableTwo.variableRateSlope2),
    );
    console.log(chalk.yellow(`${underlyingToken.symbol} interest rate strategy set with tx hash`, txReceipt.hash));
  }
}
