import { Blockchain, SandboxContract, TreasuryContract } from '@ton/sandbox';
import { Address, Sender, toNano, Cell, Slice, beginCell, internal } from '@ton/core';
import { CatTonSigning } from '../wrappers/CatTonSigning';
import '@ton/test-utils';

describe('CatTonSigning', () => {
    let blockchain: Blockchain;
    let deployer: SandboxContract<TreasuryContract>;
    let openedContract: SandboxContract<CatTonSigning>;

    beforeEach(async () => {
        blockchain = await Blockchain.create();
        deployer = await blockchain.treasury('deployer');

        const sender: Sender = deployer.getSender();
        const senderAddress: Address = sender.address!;
        const senderWalletFriendly: string = senderAddress.toString({ urlSafe: false, bounceable: false, testOnly: false });

        const origenContract: CatTonSigning = await CatTonSigning.fromInit(deployer.address);
        openedContract = blockchain.openContract(origenContract);
        const deployContractFriendly: string = openedContract.address.toString({ urlSafe: false, bounceable: true, testOnly: false });

        const deployResult = await openedContract.send(
            sender,
            { value: toNano('0.05'), },
            { $$type: 'Deploy', queryId: 0n, }
        );

        expect(deployResult.transactions).toHaveTransaction({
            from: sender.address,
            to: openedContract.address,
            deploy: true,
            success: true,
        });
        const ownerFriendly = await openedContract.getOwner();
        expect(ownerFriendly.toString()).toBe(sender.address?.toString());
    });

    it('should increment total_count on receiving SignAction1 message', async () => {
        const sender: Sender = deployer.getSender();
        const callResult = await openedContract.send(sender,
            { value: toNano('0.01'), },
            { $$type: 'SignAction1', comment: 'Test Comment' }
        );

        expect(callResult.transactions).toHaveTransaction({
            from: sender.address,
            to: openedContract.address,
            success: true,
        });
        expect(await openedContract.getTotalCount()).toBe(1n);
    });

});
