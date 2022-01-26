import web3 from "./web3";
import KaliWhitelistManager from "./artifacts/contracts/KaliWhitelistManager.sol/KaliWhitelistManager.json";

const instance = new web3.eth.Contract(
  KaliWhitelistManager.abi,
  "0x8574E6331a73cbE4E83f30848CDE1b6640dF507b" //need address
);

export default instance;
