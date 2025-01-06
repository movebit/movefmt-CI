import { Aptos, AptosConfig } from "@aptos-labs/ts-sdk";
import { AptosProvider } from "../wrappers/aptosProvider";

// Initialize Aptos instance
const aptosProvider = AptosProvider.fromEnvs();
const config = new AptosConfig({ network: aptosProvider.getNetwork() });
export const aptos = new Aptos(config);
