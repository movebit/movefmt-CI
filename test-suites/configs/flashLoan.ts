import { Account, MoveFunctionId } from "@aptos-labs/ts-sdk";
import { AptosProvider } from "../wrappers/aptosProvider";

// Resources Admin Account
const aptosProvider = AptosProvider.fromEnvs();
export const FlashLoanManager = Account.fromPrivateKey({
  privateKey: aptosProvider.getProfileAccountPrivateKeyByName("aave_pool"),
});
export const FlashLoanManagerAccountAddress = FlashLoanManager.accountAddress.toString();

// Resource Func Addr
export const ExecuteFlashLoanFuncAddr: MoveFunctionId = `${FlashLoanManagerAccountAddress}::flash_loan_logic::flashloan`;
export const PayFlashLoanComplexFuncAddr: MoveFunctionId = `${FlashLoanManagerAccountAddress}::flash_loan_logic::pay_flash_loan_complex`;
export const ExecuteFlashLoanSimpleFuncAddr: MoveFunctionId = `${FlashLoanManagerAccountAddress}::flash_loan_logic::flash_loan_simple`;
export const PayFlashLoanSimpleFuncAddr: MoveFunctionId = `${FlashLoanManagerAccountAddress}::flash_loan_logic::pay_flash_loan_simple`;

// Mock Account
