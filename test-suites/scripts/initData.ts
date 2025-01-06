/* eslint-disable no-console */
import { initReserveOraclePrice } from "./initOraclePrice";
import { configReserves } from "./configReserves";
import { initReserves } from "./initReserves";
import { createTokens } from "./createTokens";
import { createRoles } from "./createRoles";
import { initDefaultInteresRates } from "./initInterestRate";
import { initPoolAddressesProvider } from "./initPoolAddressesProvider";
import chalk from "chalk";

(async () => {
  // step1. create roles
  console.log(chalk.yellow("---------------------------------------------"));
  console.log(chalk.cyan("creating roles..."));
  await createRoles();
  console.log(chalk.green("created roles successfully!"));

  // step2. create tokens
  console.log(chalk.yellow("---------------------------------------------"));
  console.log(chalk.cyan("creating tokens..."));
  await createTokens();
  console.log(chalk.green("created tokens successfully!"));

  // step3. init interest rate strategies
  console.log(chalk.yellow("---------------------------------------------"));
  console.log(chalk.cyan("initializing default interest rate strategies..."));
  await initDefaultInteresRates();
  console.log(chalk.green("initialized interest rate strategies successfully!"));

  // step3. init reserves and interest rate strategies
  console.log(chalk.yellow("---------------------------------------------"));
  console.log(chalk.cyan("initializing reserves..."));
  await initReserves();
  console.log(chalk.green("initialized reserves successfully!"));

  // step4. config reserves
  console.log(chalk.yellow("---------------------------------------------"));
  console.log(chalk.cyan("configuring reserves..."));
  await configReserves();
  console.log(chalk.green("configured reserves successfully!"));

  // step5. config oracle price
  console.log(chalk.yellow("---------------------------------------------"));
  console.log(chalk.cyan("configuring oracle prices..."));
  await initReserveOraclePrice();
  console.log(chalk.green("configured oracle prices successfully!"));

  // // step6. config pool addresses provider
  // console.log(chalk.yellow("---------------------------------------------"));
  // console.log(chalk.cyan("configuring pool addresses provider..."));
  // await initPoolAddressesProvider();
  // console.log(chalk.green("configured pool addresses provider successfully!"));
})();
