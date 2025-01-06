import { Account, MoveFunctionId } from "@aptos-labs/ts-sdk";
import { AptosProvider } from "../wrappers/aptosProvider";

// Resources Admin Account
const aptosProvider = AptosProvider.fromEnvs();
export const LargePackagesManager = Account.fromPrivateKey({
  privateKey: aptosProvider.getProfileAccountPrivateKeyByName("aave_large_packages"),
});
export const LargePackagesAccountAddress = LargePackagesManager.accountAddress.toString();

// Resource Func Addr
export const StageCodeChunkFuncAddr: MoveFunctionId = `${LargePackagesAccountAddress}::large_packages::stage_code_chunk`;
export const StageCodeChunkAndPublishToAccountFuncAddr: MoveFunctionId = `${LargePackagesAccountAddress}::large_packages::stage_code_chunk_and_publish_to_account`;
export const StageCodeChunkAndPublishToObjectFuncAddr: MoveFunctionId = `${LargePackagesAccountAddress}::large_packages::stage_code_chunk_and_publish_to_object`;
export const StageCodeChunkAndUpgradeObjectCodeFuncAddr: MoveFunctionId = `${LargePackagesAccountAddress}::large_packages::stage_code_chunk_and_upgrade_object_code`;
export const CleanupStagingAreaFuncAddr: MoveFunctionId = `${LargePackagesAccountAddress}::large_packages::cleanup_staging_area`;

// Mock Account
