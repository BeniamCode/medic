import csv
from edgedb import create_client

# Function to insert data into EdgeDB
def insert_data(client, row):
    # Convert keys to lowercase and replace spaces with underscores
    formatted_row = {key.lower().replace(" ", "_"): value for key, value in row.items()}

    insert_query = """
    INSERT Profile {
        name := <str>$name,
        street_address := <str>$street_address,
        district := <str>$district,
        postal_code := <str>$postal_code,
        address_locality := <str>$address_locality,
        region := <str>$region,
        phone := <str>$phone,
        mobile := <str>$mobile,
        website := <str>$website,
        email := <str>$email
    }
    """
    client.execute(insert_query, **formatted_row)


def main():
    # Connect to EdgeDB
    client = create_client(database="edgedb")

    # Open and read the CSV file
    try:
        with open('scraped_data.csv', newline='', encoding='utf-8') as csvfile:
            reader = csv.DictReader(csvfile)
            for row in reader:
                # Insert each row into EdgeDB
                insert_data(client, row)
    except Exception as e:
        print(f"An error occurred: {e}")
    # No need to explicitly close the client

if __name__ == "__main__":
    main()
