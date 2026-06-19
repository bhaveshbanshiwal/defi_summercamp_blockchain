import os
import time
import subprocess
import json
from web3 import Web3
from solcx import install_solc, compile_standard

def main():
    print("\n=========================================")
    print("?? Starting DeFi Builder Deployment Script")
    print("=========================================\n")
    
    if not os.path.exists("hardhat.config.js"):
        with open("hardhat.config.js", "w") as f:
            f.write("export default { solidity: '0.8.20' };\n")

    def install_dependencies():
        npm_cmd = "npm.cmd" if os.name == "nt" else "npm"
        if not os.path.exists("node_modules/@openzeppelin"):
            print("📦 Installing Hardhat and OpenZeppelin contracts via NPM...")
            subprocess.run([npm_cmd, "init", "-y"], stdout=subprocess.DEVNULL)
            subprocess.run([npm_cmd, "install", "hardhat", "@openzeppelin/contracts"], stdout=subprocess.DEVNULL)
        
        if os.path.exists("package.json"):
            subprocess.run([npm_cmd, "pkg", "set", "type=module"], stdout=subprocess.DEVNULL)

    # 1. Install OpenZeppelin AND Hardhat if missing
    install_dependencies()

    def start_hardhat_node():
        print("? Starting local blockchain (Hardhat Node) in the background...")
        npx_cmd = "npx.cmd" if os.name == "nt" else "npx"
        proc = subprocess.Popen([npx_cmd, "hardhat", "node"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        time.sleep(5) # Wait for node to spin up
        return proc

    # 2. Start local blockchain (Hardhat Node)
    node_process = start_hardhat_node()
    
    def connect_web3():
        w3 = Web3(Web3.HTTPProvider('http://127.0.0.1:8545'))
        if w3.is_connected():
            print("? Connected to local blockchain successfully!")
            return w3
        else:
            print("? Failed to connect to blockchain.")
            return None

    # 3. Connect Web3
    w3 = connect_web3()
    if not w3:
        node_process.terminate()
        return

    # Use Account #0 as the deployer (this account is loaded with fake ETH)
    deployer_account = w3.eth.accounts[0]
    w3.eth.default_account = deployer_account
    
    def compile_contracts():
        print("?? Compiling Solidity smart contracts...")
        install_solc("0.8.20")
        
        def read_file(path):
            with open(path, "r") as f: return f.read()

        # We use solcx to compile standard JSON directly from Python
        return compile_standard(
            {
                "language": "Solidity",
                "sources": {
                    "YourToken.sol": {"content": read_file("submissions/week1/YourToken.sol")},
                    "Vendor.sol": {"content": read_file("submissions/week1/Vendor.sol")},
                    "Balloons.sol": {"content": read_file("submissions/week2/Balloons.sol")},
                    "DEX.sol": {"content": read_file("submissions/week2/DEX.sol")},
                },
                "settings": {
                    "remappings": ["@openzeppelin/=node_modules/@openzeppelin/"],
                    "outputSelection": {"*": {"*": ["abi", "evm.bytecode"]}}
                },
            },
            solc_version="0.8.20",
        )

    # 4. Compile contracts
    compiled_sol = compile_contracts()

    # Helper function to deploy a compiled contract
    def deploy_contract(contract_file, contract_name, *args):
        contract_interface = compiled_sol["contracts"][contract_file][contract_name]
        bytecode = contract_interface["evm"]["bytecode"]["object"]
        abi = contract_interface["abi"]
        
        Contract = w3.eth.contract(abi=abi, bytecode=bytecode)
        tx_hash = Contract.constructor(*args).transact()
        tx_receipt = w3.eth.wait_for_transaction_receipt(tx_hash)
        print(f"   -> Deployed {contract_name} to: {tx_receipt.contractAddress}")
        return tx_receipt.contractAddress, abi

    # 5. Deploy Week 1
    print("\n--- Deploying Week 1 ---")
    token_address, token_abi = deploy_contract("YourToken.sol", "YourToken")
    vendor_address, _ = deploy_contract("Vendor.sol", "Vendor", token_address)
    
    # Fund the Vendor with 500 GLD tokens so users can buy them
    token_contract = w3.eth.contract(address=token_address, abi=token_abi)
    tx = token_contract.functions.transfer(vendor_address, w3.to_wei(500, "ether")).transact()
    w3.eth.wait_for_transaction_receipt(tx)
    print("   -> ?? Funded Vendor with 500 GLD")

    # 6. Deploy Week 2
    print("\n--- Deploying Week 2 ---")
    balloons_address, balloons_abi = deploy_contract("Balloons.sol", "Balloons")
    dex_address, dex_abi = deploy_contract("DEX.sol", "DEX", balloons_address)
    
    # Initialize DEX liquidity pool (100 BAL and 1 ETH)
    balloons_contract = w3.eth.contract(address=balloons_address, abi=balloons_abi)
    tx = balloons_contract.functions.approve(dex_address, w3.to_wei(100, "ether")).transact()
    w3.eth.wait_for_transaction_receipt(tx)
    
    dex_contract = w3.eth.contract(address=dex_address, abi=dex_abi)
    tx = dex_contract.functions.init(w3.to_wei(100, "ether")).transact({"value": w3.to_wei(1, "ether")})
    w3.eth.wait_for_transaction_receipt(tx)
    print("   -> ?? Initialized DEX liquidity pool (1 ETH & 100 BAL)")

    # 7. Update Flask App with new addresses
    print("\n?? Linking deployed addresses to Flask UI...")
    app_path = "flask-interface/app.py"
    with open(app_path, "r") as f:
        lines = f.readlines()
        
    for i, line in enumerate(lines):
        if "your_token_address=" in line:
            lines[i] = f'        your_token_address="{token_address}",\n'
        elif "vendor_address=" in line:
            lines[i] = f'        vendor_address="{vendor_address}",\n'
        elif "balloons_address=" in line:
            lines[i] = f'        balloons_address="{balloons_address}",\n'
        elif "dex_address=" in line:
            lines[i] = f'        dex_address="{dex_address}"\n'

    with open(app_path, "w") as f:
        f.writelines(lines)
        
    print("? App successfully updated!")
    
    # 8. Start Flask App
    print("\n?? Starting Flask Web Interface...")
    print("?? CLICK HERE TO OPEN: http://127.0.0.1:5000\n")
    try:
        subprocess.run(["python", app_path])
    except KeyboardInterrupt:
        pass
    finally:
        print("\nShutting down local blockchain node...")
        node_process.terminate()

if __name__ == "__main__":
    main()
