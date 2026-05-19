import pandas as pd
import numpy as np
import random


def generate_phone_motion_dataset(num_samples=10000):
    """
    Generate a realistic phone motion dataset with accelerometer and gyroscope data
    """
    np.random.seed(42)
    random.seed(42)

    data = []

    for i in range(num_samples):
        # Determine the motion type with weighted distribution
        motion_type = np.random.choice(
            ['rest', 'shake', 'rapid_shake', 'throw', 'fall'],
            p=[0.4, 0.2, 0.15, 0.15, 0.1]  # rest is most common
        )

        if motion_type == 'rest':
            # Rest: small movements, near gravity vector
            acc_x = np.random.normal(0.0, 0.1)
            acc_y = np.random.normal(0.0, 0.1)
            acc_z = np.random.normal(9.8, 0.1)  # Gravity
            gyro_x = np.random.normal(0.0, 0.02)
            gyro_y = np.random.normal(0.0, 0.02)
            gyro_z = np.random.normal(0.0, 0.02)

        elif motion_type == 'shake':
            # Shake: moderate acceleration in x/y, some rotation
            acc_x = np.random.normal(1.5, 0.5)
            acc_y = np.random.normal(1.0, 0.4)
            acc_z = np.random.normal(9.8, 0.3)  # Gravity with some variation
            gyro_x = np.random.normal(0.3, 0.1)
            gyro_y = np.random.normal(0.2, 0.1)
            gyro_z = np.random.normal(0.1, 0.05)

        elif motion_type == 'rapid_shake':
            # Rapid shake: high frequency movements
            acc_x = np.random.normal(2.5, 0.8)
            acc_y = np.random.normal(2.0, 0.6)
            acc_z = np.random.normal(9.8, 0.5)
            gyro_x = np.random.normal(0.8, 0.3)
            gyro_y = np.random.normal(0.6, 0.2)
            gyro_z = np.random.normal(0.4, 0.1)

        elif motion_type == 'throw':
            # Throw: high acceleration followed by free fall
            acc_x = np.random.normal(3.0, 1.0)
            acc_y = np.random.normal(2.5, 0.8)
            acc_z = np.random.normal(5.0, 2.0)  # Reduced gravity during throw
            gyro_x = np.random.normal(1.2, 0.4)
            gyro_y = np.random.normal(1.0, 0.3)
            gyro_z = np.random.normal(0.8, 0.2)

        elif motion_type == 'fall':
            # Fall: free fall (near zero g) or impact
            if np.random.random() < 0.7:  # Free fall
                acc_x = np.random.normal(0.0, 0.2)
                acc_y = np.random.normal(0.0, 0.2)
                acc_z = np.random.normal(0.5, 0.3)  # Near zero gravity
            else:  # Impact
                acc_x = np.random.normal(0.0, 1.5)
                acc_y = np.random.normal(0.0, 1.5)
                acc_z = np.random.normal(15.0, 3.0)  # High g-force on impact

            gyro_x = np.random.normal(0.5, 0.4)
            gyro_y = np.random.normal(0.4, 0.3)
            gyro_z = np.random.normal(0.3, 0.2)

        # Add some noise to make it more realistic
        noise_level = 0.05
        acc_x += np.random.normal(0, noise_level)
        acc_y += np.random.normal(0, noise_level)
        acc_z += np.random.normal(0, noise_level)
        gyro_x += np.random.normal(0, noise_level * 0.1)
        gyro_y += np.random.normal(0, noise_level * 0.1)
        gyro_z += np.random.normal(0, noise_level * 0.1)

        data.append({
            'acc_x': round(acc_x, 9),
            'acc_y': round(acc_y, 9),
            'acc_z': round(acc_z, 9),
            'gyro_x': round(gyro_x, 9),
            'gyro_y': round(gyro_y, 9),
            'gyro_z': round(gyro_z, 9),
            'label': motion_type
        })

    return pd.DataFrame(data)


def analyze_dataset(df):
    """Analyze the generated dataset"""
    print("Dataset Overview:")
    print(f"Total samples: {len(df)}")
    print(f"Columns: {df.columns.tolist()}")
    print("\nClass Distribution:")
    print(df['label'].value_counts())
    print("\nData Statistics:")
    print(df.describe())

    # Print first few samples
    print("\nFirst 10 samples:")
    print(df.head(10))


# Generate the dataset
print("Generating phone motion dataset...")
df = generate_phone_motion_dataset(5000)

# Analyze the dataset
analyze_dataset(df)

# Save to CSV file
csv_filename = "phone_motion_dataset.csv"
df.to_csv(csv_filename, index=False)
print(f"\nDataset saved as: {csv_filename}")

# Create a smaller test dataset as well
test_df = generate_phone_motion_dataset(1000)
test_df.to_csv("phone_motion_test_dataset.csv", index=False)
print("Test dataset saved as: phone_motion_test_dataset.csv")

# Print sample data to verify format
print("\nSample of generated data (first 5 rows):")
print(df.head().to_string())