import "@stdlib/ownable";
import "@stdlib/deploy";

message(0xf8a7ea5) TokenTransfer {
    query_id: Int as uint64;
    amount: Int as coins;
    sender: Address;
    response_destination: Address?;
    custom_payload: Cell?;
    forward_ton_amount: Int as coins;
    forward_payload: Slice as remaining; 
}

message SignAction1 {
    comment: String;
}

message SignAction2 {
    batchid: Int;
    comment: String;
}

message OwnerWithdraw {
    amount: Int;
}

message OwnerWithdrawJetton {
    value: Int as coins;
    gas: Int as coins;
    jetton_wallet_contract_address: Address;
}

contract CatTonBooster with Deployable, OwnableTransferable {
    total_count: Int;
    owner: Address;

    init(owner: Address) {
        self.total_count = 0;
        self.owner = sender();
    }

    receive(msg: SignAction1) {
        let ctx: Context = context();
        self.total_count += 1;
        self.reply("".asComment());
    }

    receive(msg: SignAction2) {
        let ctx: Context = context();
        self.total_count += 1;
        self.reply(msg.comment.asComment());
    }

    receive(msg: OwnerWithdraw) {
        self.requireOwner();
        send(SendParameters{
            to: self.owner,
            value: msg.amount,
            bounce: false
        });
    }

    receive(msg: OwnerWithdrawJetton) {
        self.requireOwner();
        send(SendParameters {
            to: msg.jetton_wallet_contract_address,
            value: 0,
            mode: (SendRemainingValue + SendIgnoreErrors),
            bounce: true,
            body: TokenTransfer {
                query_id: now(), 
                amount: msg.value, 
                sender: self.owner, 
                response_destination: self.owner, 
                custom_payload: emptyCell(), 
                forward_ton_amount: 0, 
                forward_payload: beginCell().storeUint(now(), 32).storeUint(0, 32).endCell().asSlice()
            }.toCell()
        });
    }

    receive(msg: String){
        require(context().value >= ton("0.002"), "not enough fee");
    }

    get fun totalCount(): Int {
        return self.total_count;
    }

    get fun balance(): Int {
        return myBalance();
    }
} 