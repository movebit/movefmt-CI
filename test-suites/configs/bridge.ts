import { Account, MoveFunctionId } from "@aptos-labs/ts-sdk";
import { AptosProvider } from "../wrappers/aptosProvider";

// Resources Admin Account
const aptosProvider = AptosProvider.fromEnvs();
export const BridgeManager = Account.fromPrivateKey({
  privateKey: aptosProvider.getProfileAccountPrivateKeyByName("aave_pool"),
});
export const BridgeManagerAccountAddress = BridgeManager.accountAddress.toString();

// Resource Func Addr
export const MintUnbackedFuncAddr: MoveFunctionId = `${BridgeManagerAccountAddress}::bridge_logic::mint_unbacked`;
export const BackUnbackedFuncAddr: MoveFunctionId = `${BridgeManagerAccountAddress}::bridge_logic::back_unbacked`;

// Mock Account
