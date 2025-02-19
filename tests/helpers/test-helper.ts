import { Cl, cvToJSON } from '@stacks/transactions';
import { cvToValue } from "@stacks/transactions/src/clarity/clarityValue.ts";

export function forwardToBlock(simnet, height: number) {
    const start = simnet.callReadOnlyFn("blockchain", "get-mining-start-block", [], 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5');
    const cvStartBlock = start.result;
    const currentBurnHeight = simnet.burnBlockHeight;
    const iStartBlock = Number(cvToValue(cvStartBlock));
    const neededHeight = height * 6 + iStartBlock;
    const blocksToMine = neededHeight - currentBurnHeight;

    console.log("Forwarding " + blocksToMine + " burn blocks from " + currentBurnHeight + " to be at coin height " + height);

    if (blocksToMine <= 0)
        throw Error("Already passed desired block");

    simnet.mineEmptyBlocks(blocksToMine);
}