import csv
import random
import argparse
import time
from faker import Faker

"""
Run the script in terminal with the number of rows and the output file name as arguments:

    python generate_customer_data.py 100 customers.csv

Arguments:
1. num_rows   Number of customer records to generate.
2. csv_file   Name of the CSV file where the data will be saved.
"""

# Initialize Faker
fake = Faker()


def generate_customer_data(num_rows, csv_file):

    start_time = time.time()

    # Define CSV headers
    headers = [
        'First Name', 'Last Name', 'Gender', 'DateOfBirth', 'Email',
        'Phone Number', 'Address', 'City', 'State', 'Postal Code',
        'Country', 'LoyaltyProgramID'
    ]

    # Open the CSV file for writing
    try:
        with open(csv_file, mode='w', newline='', encoding='utf-8') as file:
            writer = csv.DictWriter(file, fieldnames=headers)
            writer.writeheader()  # Write the header row

            for _ in range(num_rows):
                customer = {
                    "First Name": fake.first_name(),
                    "Last Name": fake.last_name(),
                    "Gender": random.choice(['Male', 'Female', 'Other', 'Not Specified']),
                    "DateOfBirth": fake.date_of_birth(minimum_age=18, maximum_age=90).isoformat(),
                    "Email": fake.unique.email(),
                    "Phone Number": generate_phone_number(),
                    "Address": fake.street_address(),
                    "City": fake.city(),
                    "State": fake.state(),
                    "Postal Code": fake.zipcode(),
                    "Country": fake.country(),
                    "LoyaltyProgramID": random.randint(1, 5)
                }
                writer.writerow(customer)

        # Print success message with execution time
        print(f"\nSuccessfully generated {num_rows} customer records in '{csv_file}'.")
        print(f"Execution Time: {round(time.time() - start_time, 2)} seconds\n")

    except Exception as e:
        print(f"\nError: {e}\n")


def generate_phone_number():
    country_code = "+1"  # USA/Canada
    area_code = random.randint(200, 999)  # Valid area codes
    prefix = random.randint(200, 999)  # 3-digit exchange code
    line_number = random.randint(1000, 9999)  # 4-digit subscriber number
    return f"{country_code}{area_code}{prefix}{line_number}"


if __name__ == "__main__":
    # Parse command-line arguments
    parser = argparse.ArgumentParser(description="Generate Fake Customer Data CSV")
    parser.add_argument("num_rows", type=int, help="Number of rows to generate")
    parser.add_argument("csv_file", type=str, help="Output CSV file name")
    args = parser.parse_args()

    generate_customer_data(args.num_rows, args.csv_file)
