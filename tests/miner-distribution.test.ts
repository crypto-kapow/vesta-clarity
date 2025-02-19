
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

describe("Test Distribution setting & fetching", () => {
  const start = simnet.callReadOnlyFn("blockchain", "get-mining-start-block", [], address1);
  const cvStartBlock = start.result;
  const initialBurnHeight = simnet.burnBlockHeight;
  const iStartBlock = Number(cvToValue(cvStartBlock));

  it("calculates the start of each cycle correctly", () => {
    let resp = simnet.callReadOnlyFn("miner", "get-cycle-start-block", [uintCV(0)], address1);
    let result = resp.result;
    expect(result).toBeOk(uintCV(0));

    resp = simnet.callReadOnlyFn("miner", "get-cycle-start-block", [uintCV(1)], address1);
    result = resp.result;
    expect(result).toBeOk(uintCV(0));

    resp = simnet.callReadOnlyFn("miner", "get-cycle-start-block", [uintCV(998)], address1);
    result = resp.result;
    expect(result).toBeOk(uintCV(0));

    resp = simnet.callReadOnlyFn("miner", "get-cycle-start-block", [uintCV(999)], address1);
    result = resp.result;
    expect(result).toBeOk(uintCV(0));

    resp = simnet.callReadOnlyFn("miner", "get-cycle-start-block", [uintCV(1000)], address1);
    result = resp.result;
    expect(result).toBeOk(uintCV(1000));

    resp = simnet.callReadOnlyFn("miner", "get-cycle-start-block", [uintCV(1001)], address1);
    result = resp.result;
    expect(result).toBeOk(uintCV(1000));

    resp = simnet.callReadOnlyFn("miner", "get-cycle-start-block", [uintCV(20000)], address1);
    result = resp.result;
    expect(result).toBeOk(uintCV(20000));

    resp = simnet.callReadOnlyFn("miner", "get-cycle-start-block", [uintCV(21999)], address1);
    result = resp.result;
    expect(result).toBeOk(uintCV(21000));

    resp = simnet.callReadOnlyFn("miner", "get-cycle-start-block", [uintCV(22000)], address1);
    result = resp.result;
    expect(result).toBeOk(uintCV(22000));
  })



});
