import pandas as pd
import random
import csv
from faker import Faker
import os
import argparse

"""
Run the script in terminal to generate store data:

    python generate_store_data.py 100 stores.csv "FILE_PATH" \
    "Store Name Data" "Adjectives" "Nouns"

Arguments:
1. num_rows        Number of store records to generate.
2. csv_file          Name of the output CSV file.
3. excel_file_path   Path to the Excel lookup file.
4. sheet_name      Sheet name in the Excel file.
5. adjective_col     Column name for adjectives in Excel.
6. noun_col         Column name for nouns in Excel.
"""

# Initialize Faker
fake = Faker()

def generate_store_data(num_rows, csv_file, excel_file_path, sheet_name, adjective_col, noun_col):

    # Check if Excel file exists
    if not os.path.exists(excel_file_path):
        print(f"Error: The file '{excel_file_path}' does not exist.")
        exit()

    # Read lookup data
    try:
        df = pd.read_excel(excel_file_path, sheet_name=sheet_name, usecols=[adjective_col, noun_col])
    except Exception as e:
        print(f"Error reading Excel file: {e}")
        exit()

    # Validate required columns
    if adjective_col not in df.columns or noun_col not in df.columns:
        print("Error: Required columns missing in Excel file.")
        exit()

    # Open CSV file
    try:
        with open(csv_file, mode='w', newline='', encoding='utf-8') as file:
            writer = csv.DictWriter(file, fieldnames=[
                'StoreName', 'StoreType', 'StoreOpeningDate', 'Address', 'City', 'State', 'Country', 'Region',
                'Manager Name'
            ])
            writer.writeheader()

            # Generate store names and data
            for _ in range(num_rows):
                store_name = f"The {df[adjective_col].sample(1).iloc[0]} {df[noun_col].sample(1).iloc[0]}"

                row = {
                    "StoreName": store_name,
                    "StoreType": random.choice(['Exclusive', 'MBO', 'SMB', 'Outlet Stores']),
                    "StoreOpeningDate": fake.date(),
                    "Address": fake.street_address(),
                    "City": fake.city(),
                    "State": fake.state(),
                    "Country": fake.country(),
                    "Region": random.choice(['North', 'South', 'East', 'West']),
                    "Manager Name": fake.first_name()
                }

                writer.writerow(row)

        print(f"\nSuccessfully generated {num_rows} rows in '{csv_file}'.")
    except Exception as e:
        print(f"\nError writing CSV file: {e}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate Fake Store Data CSV")
    parser.add_argument("num_rows", type=int, help="Number of rows to generate")
    parser.add_argument("csv_file", type=str, help="Output CSV file name")
    parser.add_argument("excel_file_path", type=str, help="Path to Excel lookup file")
    parser.add_argument("sheet_name", type=str, help="Sheet name in the Excel file")
    parser.add_argument("adjective_col", type=str, help="Column name for adjectives in Excel")
    parser.add_argument("noun_col", type=str, help="Column name for nouns in Excel")

    args = parser.parse_args()

    generate_store_data(
        args.num_rows,
        args.csv_file,
        args.excel_file_path,
        args.sheet_name,
        args.adjective_col,
        args.noun_col
    )

