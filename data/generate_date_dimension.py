import pandas as pd
import argparse

"""
Run the script in terminal with start date, end date, and output file as arguments:

    python generate_date_dimension.py 2014-01-01 2024-12-31 DimDate.csv

Arguments:
1. start_date (YYYY-MM-DD)  Start date for the Date Dimension table
2. end_date (YYYY-MM-DD)    End date for the Date Dimension table
3. output_file      Name of the CSV file
"""

def generate_date_dimension(start_date, end_date, output_file):

    try:
        # Generate a series of dates
        date_range = pd.date_range(start=start_date, end=end_date)

        # Create DataFrame
        date_dimension = pd.DataFrame(date_range, columns=['Date'])

        # Add new columns
        date_dimension['DateID'] = date_dimension['Date'].dt.strftime('%Y%m%d').astype(int)
        date_dimension['DayOfWeek'] = date_dimension['Date'].dt.dayofweek.astype('category')
        date_dimension['DayName'] = date_dimension['Date'].dt.day_name()
        date_dimension['Month'] = date_dimension['Date'].dt.month.astype('category')
        date_dimension['MonthName'] = date_dimension['Date'].dt.month_name()
        date_dimension['Quarter'] = date_dimension['Date'].dt.quarter.astype('category')
        date_dimension['Year'] = date_dimension['Date'].dt.year
        date_dimension['IsWeekend'] = date_dimension['DayOfWeek'].apply(lambda x: x in [5, 6])

        # Reorder columns
        cols = ['DateID', 'Date', 'DayOfWeek', 'DayName', 'Month', 'MonthName', 'Quarter', 'Year', 'IsWeekend']
        date_dimension = date_dimension[cols]

        # Save to CSV
        date_dimension.to_csv(output_file, index=False)
        print(f"Successfully generated Date Dimension file: {output_file}")

    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate a Date Dimension CSV file for data warehousing.")
    parser.add_argument("start_date", type=str, help="Start date (YYYY-MM-DD)")
    parser.add_argument("end_date", type=str, help="End date (YYYY-MM-DD)")
    parser.add_argument("output_file", type=str, help="Output CSV file name")

    args = parser.parse_args()

    generate_date_dimension(args.start_date, args.end_date, args.output_file)
