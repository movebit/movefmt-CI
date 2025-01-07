/* eslint-disable no-console */
import { PoolManager, strategyAAVE, strategyDAI, strategyUSDC, strategyWETH } from "../configs/pool";
import { AAVE, DAI, USDC, WETH } from "../configs/tokens";
import { underlyingTokens } from "./createTokens";
import { PoolClient } from "../clients/poolClient";
import { AptosProvider } from "../wrappers/aptosProvider";
import chalk from "chalk";
import { BigNumber } from "@ethersproject/bignumber";
import { AccountAddress } from "@aptos-labs/ts-sdk";

async function getReserveInfo() {
  // get assets addresses
  const assets: Array<AccountAddress> = [];
  const dai = underlyingTokens.find((token) => token.symbol === DAI).accountAddress;
  const weth = underlyingTokens.find((token) => token.symbol === WETH).accountAddress;
  const usdc = underlyingTokens.find((token) => token.symbol === USDC).accountAddress;
  const aave = underlyingTokens.find((token) => token.symbol === AAVE).accountAddress;
  assets.push(dai);
  assets.push(weth);
  assets.push(usdc);
  assets.push(aave);

  // get assets base ltv
  const baseLtv: Array<string> = [];
  baseLtv.push(strategyDAI.baseLTVAsCollateral);
  baseLtv.push(strategyWETH.baseLTVAsCollateral);
  baseLtv.push(strategyUSDC.baseLTVAsCollateral);
  baseLtv.push(strategyAAVE.baseLTVAsCollateral);

  // get assets liquidation threshold
  const liquidationThreshold: Array<string> = [];
  liquidationThreshold.push(strategyDAI.liquidationThreshold);
  liquidationThreshold.push(strategyWETH.liquidationThreshold);
  liquidationThreshold.push(strategyUSDC.liquidationThreshold);
  liquidationThreshold.push(strategyAAVE.liquidationThreshold);

  // get assets liquidation bonus
  const liquidationBonus: Array<string> = [];
  liquidationBonus.push(strategyDAI.liquidationBonus);
  liquidationBonus.push(strategyWETH.liquidationBonus);
  liquidationBonus.push(strategyUSDC.liquidationBonus);
  liquidationBonus.push(strategyAAVE.liquidationBonus);

  // reserve_factor
  const reserveFactor: Array<string> = [];
  reserveFactor.push(strategyDAI.reserveFactor);
  reserveFactor.push(strategyWETH.reserveFactor);
  reserveFactor.push(strategyUSDC.reserveFactor);
  reserveFactor.push(strategyAAVE.reserveFactor);

  // borrow_cap
  const borrowCap: Array<string> = [];
  borrowCap.push(strategyDAI.borrowCap);
  borrowCap.push(strategyWETH.borrowCap);
  borrowCap.push(strategyUSDC.borrowCap);
  borrowCap.push(strategyAAVE.borrowCap);

  // supply_cap
  const supplyCap: Array<string> = [];
  supplyCap.push(strategyDAI.supplyCap);
  supplyCap.push(strategyWETH.supplyCap);
  supplyCap.push(strategyUSDC.supplyCap);
  supplyCap.push(strategyAAVE.supplyCap);

  // borrowing_enabled
  const borrowingEnabled: Array<boolean> = [];
  borrowingEnabled.push(strategyDAI.borrowingEnabled);
  borrowingEnabled.push(strategyWETH.borrowingEnabled);
  borrowingEnabled.push(strategyUSDC.borrowingEnabled);
  borrowingEnabled.push(strategyAAVE.borrowingEnabled);

  // flash_loan_enabled
  const flashLoanEnabled: Array<boolean> = [];
  flashLoanEnabled.push(strategyDAI.flashLoanEnabled);
  flashLoanEnabled.push(strategyWETH.flashLoanEnabled);
  flashLoanEnabled.push(strategyUSDC.flashLoanEnabled);
  flashLoanEnabled.push(strategyAAVE.flashLoanEnabled);

  return {
    assets,
    baseLtv,
    liquidationThreshold,
    liquidationBonus,
    reserveFactor,
    borrowCap,
    supplyCap,
    borrowingEnabled,
    flashLoanEnabled,
  };
}

export async function configReserves() {
  const {
    assets,
    baseLtv,
    liquidationThreshold,
    liquidationBonus,
    reserveFactor,
    borrowCap,
    supplyCap,
    borrowingEnabled,
    flashLoanEnabled,
  } = await getReserveInfo();

  // global aptos provider
  const aptosProvider = AptosProvider.fromEnvs();
  const poolClient = new PoolClient(aptosProvider, PoolManager);

  for (let index in assets) {
    let txReceipt = await poolClient.configureReserveAsCollateral(
      assets[index],
      BigNumber.from(baseLtv[index]),
      BigNumber.from(liquidationThreshold[index]),
      BigNumber.from(liquidationBonus[index]),
    );
    console.log(chalk.yellow(`Reserve ${assets[index]} configured with tx hash = ${txReceipt.hash}`));

    txReceipt = await poolClient.setReserveBorrowing(
      assets[index],
      borrowingEnabled[index],
    );
    console.log(chalk.yellow(`Reserve ${assets[index]} enabled borrowing with tx hash = ${txReceipt.hash}`));

    txReceipt = await poolClient.setReserveFlashLoaning(
      assets[index],
      flashLoanEnabled[index],
    );
    console.log(chalk.yellow(`Reserve ${assets[index]} enabled flashloaning with tx hash = ${txReceipt.hash}`));

    txReceipt = await poolClient.setReserveFactor(
      assets[index],
      BigNumber.from(reserveFactor[index]),
    );
    console.log(chalk.yellow(`Reserve ${assets[index]} set factor with tx hash = ${txReceipt.hash}`));

    txReceipt = await poolClient.setBorrowCap(
      assets[index],
      BigNumber.from(borrowCap[index]),
    );
    console.log(chalk.yellow(`Reserve ${assets[index]} set borrow cap with tx hash = ${txReceipt.hash}`));

    txReceipt = await poolClient.setSupplyCap(
      assets[index],
      BigNumber.from(supplyCap[index]),
    );
    console.log(chalk.yellow(`Reserve ${assets[index]} set supply cap with tx hash = ${txReceipt.hash}`));
  }
}
