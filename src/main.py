import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

def main():
    print("=" * 50)
    print("Invoice Reconciliation System")
    print("=" * 50)
    print(f"Database: {os.getenv('POSTGRES_DB')}")
    print(f"User: {os.getenv('POSTGRES_USER')}")
    print(f"Host: {os.getenv('POSTGRES_HOST')}")
    print("=" * 50)
    print("System initialized successfully!")

if __name__ == "__main__":
    main()