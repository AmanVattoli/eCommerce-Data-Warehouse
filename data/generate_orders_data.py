import pandas as pd
import numpy as np
import argparse

"""
Run the script in terminal with the number of rows and the output file name as arguments:

    python generate_fact_orders.py 10000 FactOrders.csv

Arguments:
1. num_rows  Number of records to generate.
2. output_file  Name of the CSV file where the data will be saved.
"""



def generate_fact_orders(num_rows, output_file):

    # Generate a series of random dates between 2014-01-01 and 2024-07-28
    date_range = pd.date_range(start='2014-01-01', end='2024-07-28')
    random_dates = np.random.choice(date_range, size=num_rows)

    # Format dates to YYYYMMDD integer format
    formatted_dates = pd.to_datetime(random_dates).strftime('%Y%m%d').astype(int)

    # Generate random data for orders
    data = {
        'DateID': formatted_dates,
        'ProductID': np.random.randint(1, 1001, size=num_rows),
        'StoreID': np.random.randint(1, 101, size=num_rows),
        'CustomerID': np.random.randint(1, 1001, size=num_rows),
        'QuantityOrdered': np.random.randint(1, 21, size=num_rows),
        'OrderAmount': np.random.uniform(100, 1000, size=num_rows).round(2)
    }

    # Create DataFrame
    df = pd.DataFrame(data)

    # Generate discount and shipping cost percentages
    df['DiscountPercentage'] = np.random.uniform(0.02, 0.15, size=num_rows).round(4)
    df['ShippingPercentage'] = np.random.uniform(0.05, 0.15, size=num_rows).round(4)

    # Calculate dependent columns
    df['DiscountAmount'] = (df['OrderAmount'] * df['DiscountPercentage']).round(2)
    df['ShippingCost'] = (df['OrderAmount'] * df['ShippingPercentage']).round(2)
    df['TotalAmount'] = (df['OrderAmount'] - (df['DiscountAmount'] + df['ShippingCost'])).round(2)

    # Drop percentage
    df.drop(columns=['DiscountPercentage', 'ShippingPercentage'], inplace=True)

    # Save to CSV
    df.to_csv(output_file, index=False)

    print(f"\nSuccessfully generated {num_rows} FactOrders records and saved to '{output_file}'.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate Fake FactOrders Data CSV")
    parser.add_argument("num_rows", type=int, help="Number of rows to generate")
    parser.add_argument("output_file", type=str, help="Output CSV file name")

    args = parser.parse_args()

    generate_fact_orders(args.num_rows, args.output_file)
