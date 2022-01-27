import web3 from "./web3";
import KaliWhitelistManager from "./artifacts/contracts/KaliWhitelistManager.sol/KaliWhitelistManager.json";

const instance = new web3.eth.Contract(
  KaliWhitelistManager.abi,
  "0x5DbdD12902F319f5Df6D403e6e15B2CbF89220C2" //need address
);

export default instance;
