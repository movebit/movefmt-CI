import { AccountAddress, CommittedTransactionResponse } from "@aptos-labs/ts-sdk";
import { BigNumber } from "@ethersproject/bignumber";
import { AptosContractWrapperBaseClass } from "./baseClass";
import {
  CalculateInterestRatesFuncAddr,
  GetBaseVariableBorrowRateFuncAddr,
  GetGetMaxExcessUsageRatioFuncAddr,
  GetGetOptimalUsageRatioFuncAddr,
  GetMaxVariableBorrowRateFuncAddr,
  GetVariableRateSlope1FuncAddr,
  GetVariableRateSlope2FuncAddr,
  SetReserveInterestRateStrategyFuncAddr,
} from "../configs/rates";
import { mapToBN } from "../helpers/contractHelper";

export class DefaultInterestRateStrategyClient extends AptosContractWrapperBaseClass {

  public async setReserveInterestRateStrategy(
    asset: AccountAddress,
    optimalUsageRatio: BigNumber,
    baseVariableBorrowRate: BigNumber,
    variableRateSlope1: BigNumber,
    variableRateSlope2: BigNumber,
  ): Promise<CommittedTransactionResponse> {
    return this.sendTxAndAwaitResponse(SetReserveInterestRateStrategyFuncAddr, [
      asset,
      optimalUsageRatio.toString(),
      baseVariableBorrowRate.toString(),
      variableRateSlope1.toString(),
      variableRateSlope2.toString(),
    ]);
  }

  public async getOptimalUsageRatio(asset: AccountAddress): Promise<BigNumber> {
    const [resp] = (await this.callViewMethod(GetGetOptimalUsageRatioFuncAddr, [asset])).map(mapToBN);
    return resp;
  }

  public async getMaxExcessUsageRatio(asset: AccountAddress): Promise<BigNumber> {
    const [resp] = (await this.callViewMethod(GetGetMaxExcessUsageRatioFuncAddr, [asset])).map(mapToBN);
    return resp;
  }

  public async getVariableRateSlope1(asset: AccountAddress): Promise<BigNumber> {
    const [resp] = (await this.callViewMethod(GetVariableRateSlope1FuncAddr, [asset])).map(mapToBN);
    return resp;
  }

  public async getVariableRateSlope2(asset: AccountAddress): Promise<BigNumber> {
    const [resp] = (await this.callViewMethod(GetVariableRateSlope2FuncAddr, [asset])).map(mapToBN);
    return resp;
  }

  public async getBaseVariableBorrowRate(asset: AccountAddress): Promise<BigNumber> {
    const [resp] = (await this.callViewMethod(GetBaseVariableBorrowRateFuncAddr, [asset])).map(mapToBN);
    return resp;
  }

  public async getMaxVariableBorrowRate(asset: AccountAddress): Promise<BigNumber> {
    const [resp] = (await this.callViewMethod(GetMaxVariableBorrowRateFuncAddr, [asset])).map(mapToBN);
    return resp;
  }

  public async calculateInterestRates(
    unbacked: BigNumber,
    liquidityAdded: BigNumber,
    liquidityTaken: BigNumber,
    totalVariableDebt: BigNumber,
    reserveFactor: BigNumber,
    reserve: AccountAddress,
    aTokenUnderlyingBalance: BigNumber,
  ): Promise<{ currentLiquidityRate: BigNumber; currentVariableBorrowRate: BigNumber }> {
    const [currentLiquidityRate, currentVariableBorrowRate] = await this.callViewMethod(
      CalculateInterestRatesFuncAddr,
      [
        unbacked.toString(),
        liquidityAdded.toString(),
        liquidityTaken.toString(),
        totalVariableDebt.toString(),
        reserveFactor.toString(),
        reserve,
        aTokenUnderlyingBalance.toString(),
      ],
    );
    return {
      currentLiquidityRate: BigNumber.from(currentLiquidityRate),
      currentVariableBorrowRate: BigNumber.from(currentVariableBorrowRate),
    };
  }
}
