
import { describe, expect, it } from "vitest";
import { Cl, cvToJSON, stringCV } from '@stacks/transactions';
import { forwardToBlock } from "./helpers/test-helper";
import {
  uintCV,
  listCV
} from "@stacks/transactions";
import { cvToValue } from "@stacks/transactions/src/clarity/clarityValue.ts";
import { tuple } from "@stacks/transactions/dist/cl";

const accounts = simnet.getAccounts();
const address1 = accounts.get("wallet_1")!;

/*
  The test below is an example. To learn more, read the testing documentation here:
  https://docs.hiro.so/stacks/clarinet-js-sdk
*/

describe("Test Mining Info", () => {
  const start = simnet.callReadOnlyFn("blockchain", "get-mining-start-block", [], address1);
  const cvStartBlock = start.result;
  const initialBurnHeight = simnet.burnBlockHeight;
  const iStartBlock = Number(cvToValue(cvStartBlock));

  it("requires mining of whole STX", () => {
    console.log("Start Block: " + iStartBlock + ", initialBurnHeight: " + initialBurnHeight);
    let resp = simnet.callPublicFn("miner", "pox-mine", [uintCV(0), listCV( [uintCV(3000000), uintCV(100), uintCV(4000000)] )], address1);
    let result = resp.result;
    expect(result).toBeErr(uintCV(6020));
  })

  it("doesn't allow mining in the past", () => {
    // Get us to block
    console.log("Start Block: " + iStartBlock + ", initialBurnHeight: " + initialBurnHeight);
    forwardToBlock(simnet, 20);

    // mine the current block. Should work.
    let resp = simnet.callPublicFn("miner", "pox-mine", [uintCV(21), listCV([uintCV(3000000), uintCV(1000000), uintCV(4000000)])], address1);
    let result = resp.result;
    expect(result).toBeOk(tuple(
      {
        event: stringCV("Mining Commit Complete", 'ascii'),
        conductor: uintCV(160000),
        miners: uintCV(7200000),
        pool: uintCV(640000)
      }
    ));

    // mine the previous block. Should fail.
    resp = simnet.callPublicFn("miner", "pox-mine", [uintCV(20), listCV([uintCV(3000000), uintCV(1000000), uintCV(4000000)])], address1);
    result = resp.result;
    expect(result).toBeErr(uintCV(6009));
  })


});
