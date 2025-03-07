import pandas as pd
import random
import csv
import os
import argparse

"""
Run the script in terminal with required parameters to generate product data:

    python generate_product_data.py 100 products.csv "FILE_PATH" \
    "Raw Product Names" "Product Name" "Product Categories" "Category Name"

Arguments:
1. num_rows        Number of product records to generate.
2. csv_file         Name of the output CSV file.
3. excel_file_path   Path to the Excel lookup file.
4. sheet_product     Sheet name for product names.
5. product_column    Column name for product names.
6. sheet_category    Sheet name for product categories.
7. category_column   Column name for product categories.
"""

# Function to generate product data
def generate_product_data(num_rows, csv_file, excel_file_path, sheet_product, product_column, sheet_category, category_column):


    # Check if the Excel file exists
    if not os.path.exists(excel_file_path):
        print(f"Error: The file '{excel_file_path}' does not exist.")
        return

    # Load lookup data with only required columns
    try:
        df_product = pd.read_excel(excel_file_path, sheet_name=sheet_product, usecols=[product_column])
        df_category = pd.read_excel(excel_file_path, sheet_name=sheet_category, usecols=[category_column])
    except Exception as e:
        print(f"Error reading Excel file: {e}")
        return

    # Validate required columns
    if product_column not in df_product.columns or category_column not in df_category.columns:
        print("Error: Required columns missing in Excel file.")
        return

    # Define brand names
    brand_names = ['FakeLuxeAura', 'FakeUrbanGlow', 'FakeEtherealEdge', 'FakeVelvetVista', 'FakeZenithStyle']

    # Open CSV file for writing
    try:
        with open(csv_file, mode='w', newline='', encoding='utf-8') as file:
            writer = csv.DictWriter(file, fieldnames=['ProductName', 'Category', 'Brand', 'UnitPrice'])
            writer.writeheader()

            # Generate product data
            for _ in range(num_rows):
                row = {
                    "ProductName": df_product[product_column].sample(1).iloc[0],
                    "Category": df_category[category_column].sample(1).iloc[0],
                    "Brand": random.choice(brand_names),
                    "UnitPrice": random.randint(100, 1000)
                }
                writer.writerow(row)

        print(f"\nSuccessfully generated {num_rows} product records in '{csv_file}'.")
    except Exception as e:
        print(f"\nError writing CSV file: {e}")

# Main function to parse arguments
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate Fake Product Data CSV")
    parser.add_argument("num_rows", type=int, help="Number of rows to generate")
    parser.add_argument("csv_file", type=str, help="Output CSV file name")
    parser.add_argument("excel_file_path", type=str, help="Path to Excel lookup file")
    parser.add_argument("sheet_product", type=str, help="Sheet name for product names")
    parser.add_argument("product_column", type=str, help="Column name for product names")
    parser.add_argument("sheet_category", type=str, help="Sheet name for product categories")
    parser.add_argument("category_column", type=str, help="Column name for product categories")

    args = parser.parse_args()

    generate_product_data(
        args.num_rows,
        args.csv_file,
        args.excel_file_path,
        args.sheet_product,
        args.product_column,
        args.sheet_category,
        args.category_column
    )


