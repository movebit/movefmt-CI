import { Account, MoveFunctionId } from "@aptos-labs/ts-sdk";
import { AptosProvider } from "../wrappers/aptosProvider";

// Resources Admin Account
const aptosProvider = AptosProvider.fromEnvs();
export const SupplyBorrowManager = Account.fromPrivateKey({
  privateKey: aptosProvider.getProfileAccountPrivateKeyByName("aave_pool"),
});
export const SupplyBorrowManagerAccountAddress = SupplyBorrowManager.accountAddress.toString();

// Resource Func Addr
// Supply
/// Entry
export const SupplyFuncAddr: MoveFunctionId = `${SupplyBorrowManagerAccountAddress}::supply_logic::supply`;
export const WithdrawFuncAddr: MoveFunctionId = `${SupplyBorrowManagerAccountAddress}::supply_logic::withdraw`;
export const FinalizeTransferFuncAddr: MoveFunctionId = `${SupplyBorrowManagerAccountAddress}::supply_logic::finalize_transfer`;
export const SetUserUseReserveAsCollateralFuncAddr: MoveFunctionId = `${SupplyBorrowManagerAccountAddress}::supply_logic::set_user_use_reserve_as_collateral`;

// Borrow
/// Entry
export const BorrowFuncAddr: MoveFunctionId = `${SupplyBorrowManagerAccountAddress}::borrow_logic::borrow`;
export const RepayFuncAddr: MoveFunctionId = `${SupplyBorrowManagerAccountAddress}::borrow_logic::repay`;
export const RepayWithATokensFuncAddr: MoveFunctionId = `${SupplyBorrowManagerAccountAddress}::borrow_logic::repay_with_a_tokens`;

// Liquidation
/// Entry
export const LiquidationCallFuncAddr: MoveFunctionId = `${SupplyBorrowManagerAccountAddress}::liquidation_logic::liquidation_call`;

// User Logic
/// View
export const GetUserAccountDataFuncAddr: MoveFunctionId = `${SupplyBorrowManagerAccountAddress}::user_logic::get_user_account_data`;

// Mock Account
