import subprocess
from solcx import install_solc

def main():
    print("Setting up deployer...")
    install_solc("0.8.20")

if __name__ == "__main__":
    main()