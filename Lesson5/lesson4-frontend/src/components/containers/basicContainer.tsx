import BasicDataField from "../fields/basicDataField";
import BasicInputField from "../fields/basicInputField";
import ActionButton from "../buttons/actionButton";
import { useContext, useMemo, useState } from "react";
import { useAccounts, useSignAndExecuteTransactionBlock, useSuiClient, useSuiClientQuery } from "@mysten/dapp-kit";
import { AppContext } from "@/context/AppContext";
import { TransactionBlock } from "@mysten/sui.js/transactions";
import { toast } from "react-toastify";

const BasicContainer = () => {
  const { walletAddress, suiName } = useContext(AppContext);
  const { data: suiBalance, refetch } = useSuiClientQuery("getBalance", {
    owner: walletAddress ?? "",
  });
  const [selectedToken, setSelectedToken] = useState<string>("SUI");
  const client = useSuiClient();
  const [account] = useAccounts();
  const { mutate: signAndExecuteTransactionBlock } =
    useSignAndExecuteTransactionBlock();

  const userBalance = useMemo(() => {
    if (suiBalance?.totalBalance) {
      return Math.floor(Number(suiBalance?.totalBalance) / 10 ** 9);
    } else {
      return 0;
    }
  }, [suiBalance]);

  const PACKAGE_ID = "0xd4395116066d0e6d41a5b041154efaefc3dd8969084a2230732d205549e1bc31";
  const TREASURY_ID = "0x4211e66063acb06ca1128b6853cfa86131f3c84740cb74e13b43feaabb311a6d";

  const handleMint = async () => {
    if (!account.address) return;
    const tx = new TransactionBlock();
    const treasuryObj = tx.object(TREASURY_ID);
    const flashMintAmount = tx.pure.u64(1);

    // 1. flash mint
    const [fortuneCoin, recipit] = tx.moveCall({
      target: `${PACKAGE_ID}::fortune::flash_mint`,
      arguments: [treasuryObj, flashMintAmount],
    });

    // 2. mint bag
    const [fortuneBag] = tx.moveCall({
      target: `${PACKAGE_ID}::fortune_bag::mint`,
      arguments: [fortuneCoin],
    });
    const [fortuneValueInBag] = tx.moveCall({
      target: `${PACKAGE_ID}::fortune_bag::fortune_value`,
      arguments: [fortuneBag],
    });

    // 3. take from bag
    const [repayment] = tx.moveCall({
      target: `${PACKAGE_ID}::fortune_bag::take`,
      arguments: [fortuneBag, flashMintAmount],
    });

    // 4. transfer bag to sender
    tx.transferObjects([fortuneBag], account.address);

    // 5. flash burn
    tx.moveCall({
      target: `${PACKAGE_ID}::fortune::flash_burn`,
      arguments: [treasuryObj, repayment, recipit],
    });
    tx.setSender(account.address);

    const dryrunRes = await client.dryRunTransactionBlock({
      transactionBlock: await tx.build({ client: client }),
    });
    console.log(dryrunRes);

    if (dryrunRes.effects.status.status === 'success') {
      signAndExecuteTransactionBlock({
        transactionBlock: tx,
        options: {
          showEffects: true,
        },
      },
      {
        onSuccess: (res) => {
          toast.success(`Mint ${res.effects?.created?.length ?? 0} Bag!`);
          refetch();
        },
        onError: (err) => {
          toast.error("Tx Failed!");
          console.log(err);
        }
      })
    } else {
      toast.error("Something went wrong");
    }
  }

  return (
    <div className="w-[80%] flex flex-col items-center justify-center gap-4">
      <BasicDataField
        label="Your Wallet Balance"
        value={userBalance ?? "0.0000"}
        spaceWithUnit
        unit="SUI"
        minFractionDigits={0}
      />
      <BasicInputField
        label="Input"
        inputValue="0.0000"
        setInputValue={(value) => console.log(value)}
        tokenInfo={["SUI", "BUCK", "USDC", "USDT"]}
        canSelectToken={true}
        selectedToken={selectedToken}
        setSelectedToken={setSelectedToken}
        maxValue={0.0}
      />
      <ActionButton
        label="Flash Mint Fortune Bag"
        isConnected={true}
        isLoading={false}
        onClick={handleMint}
        buttonClass="w-70"
      />
    </div>
  );
};

export default BasicContainer;
