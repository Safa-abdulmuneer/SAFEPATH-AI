import json
import os
from web3 import Web3
from solcx import compile_source, install_solc

# Setup solc
install_solc("0.8.0")

# Ganache connection
ganache_url = "HTTP://127.0.0.1:7545"
w3 = Web3(Web3.HTTPProvider(ganache_url))

# Check connection
if w3.is_connected():
    print("✅ Connected to Ganache")
    print(f"📌 Chain ID: {w3.eth.chain_id}")
    print(f"💰 Default account: {w3.eth.accounts[0]}")
    w3.eth.default_account = w3.eth.accounts[0]
else:
    print("❌ Failed to connect to Ganache")

# File paths
# BASE_DIR = os.path./dirname(os.path.dirname(os.path.abspath(__file__)))
sol_path = "C:\\Users\\sayan\\PycharmProjects\\safe_path_web\\myapp\\contract\\CreditScore.Sol"  # Change to your contract name
deploy_info_path = "C:\\Users\\sayan\\PycharmProjects\\safe_path_web\\myapp\\contract\\deployed.json"


def get_contract():
    """Get or deploy contract"""
    # Check if already deployed
    if os.path.exists(deploy_info_path):
        # Load contract from file
        with open(deploy_info_path, "r") as f:
            deploy_data = json.load(f)
        contract_address = deploy_data["address"]
        abi = deploy_data["abi"]

        contract = w3.eth.contract(address=contract_address, abi=abi)
        print(f"✔ Contract loaded from existing deployment: {contract_address}")
        return contract, contract_address, abi
    else:
        # Deploy new contract
        return deploy_contract()


def deploy_contract():
    """Deploy new contract"""
    try:
        # Read the smart contract file
        with open(sol_path, "r") as file:
            contract_source = file.read()

        print("📄 Compiling contract...")
        compiled_sol = compile_source(contract_source, solc_version="0.8.0")

        # Get contract interface (change 'CreditScore' to your contract name)
        contract_interface = compiled_sol['<stdin>:CreditScore']

        # Create contract
        Contract = w3.eth.contract(
            abi=contract_interface['abi'],
            bytecode=contract_interface['bin']
        )

        # Deploy
        print("🚀 Deploying contract...")
        tx_hash = Contract.constructor().transact()
        tx_receipt = w3.eth.wait_for_transaction_receipt(tx_hash)

        contract_address = tx_receipt.contractAddress
        abi = contract_interface["abi"]

        # Save deployment info
        os.makedirs(os.path.dirname(deploy_info_path), exist_ok=True)
        with open(deploy_info_path, "w") as f:
            json.dump({"address": contract_address, "abi": abi}, f)

        contract = w3.eth.contract(address=contract_address, abi=abi)
        print(f"✅ Contract deployed and saved: {contract_address}")
        print(f"⛽ Gas used: {tx_receipt['gasUsed']}")

        return contract, contract_address, abi

    except Exception as e:
        print(f"❌ Deployment error: {str(e)}")
        return None, None, None


# Initialize contract
contract, CONTRACT_ADDRESS, CONTRACT_ABI = get_contract()


# Function to update credit score
# Function to update credit score
def update_user_credit_score(username, credit_score, total_spots):
    """Update user credit score on blockchain"""
    try:
        if not contract:
            print("❌ Contract not initialized")
            return None

        print(f"📤 Calling blockchain function...")
        print(f"   Contract address: {CONTRACT_ADDRESS}")
        print(f"   Function: updateCreditScore({username}, {credit_score}, {total_spots})")

        # Call contract function
        tx_hash = contract.functions.updateCreditScore(
            username,
            credit_score,
            total_spots
        ).transact()

        print(f"⏳ Waiting for transaction receipt...")
        # Wait for transaction
        receipt = w3.eth.wait_for_transaction_receipt(tx_hash)

        print(f"✅ Blockchain update successful")
        print(f"   TX Hash: {tx_hash.hex()}")
        print(f"   Block: {receipt['blockNumber']}")
        print(f"   Gas used: {receipt['gasUsed']}")
        print(f"   Status: {receipt['status']}")

        return tx_hash.hex()

    except Exception as e:
        print(f"❌ Blockchain error: {str(e)}")
        print(f"   Error type: {type(e).__name__}")
        return None


# Function to get user credit score
def get_user_credit_score(username):
    """Get user credit score from blockchain"""
    try:
        if not contract:
            print("❌ Contract not initialized")
            return None

        print(f"🔍 Querying blockchain for user: {username}")

        # Call view function
        result = contract.functions.getUserByUsername(username).call()

        print(f"📊 Raw blockchain result: {result}")

        user_data = {
            'user_id': result[0],
            'username': result[1],
            'credit_score': result[2],
            'total_spots': result[3],
            'last_updated': result[4],
        }

        print(f"✅ Found user: {user_data}")
        return user_data

    except Exception as e:
        print(f"❌ Error getting user data: {str(e)}")
        if "execution reverted" in str(e):
            print(f"ℹ️ User {username} not found in blockchain")
        return None