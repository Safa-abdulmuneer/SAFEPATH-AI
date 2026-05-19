import pandas as pd
import numpy as np
from sklearn.preprocessing import LabelEncoder
from sklearn.model_selection import train_test_split
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Conv1D, Dense, Dropout, Flatten, MaxPooling1D
from tensorflow.keras.utils import to_categorical

# 1. Load dataset
data = pd.read_csv(r"C:\Users\VIPIN KARMA\Downloads\Telegram Desktop\shecare30-12-24\shecare30-12-24\SheCare (2)\SheCare\myapp\phone_motion_dataset.csv")

# 2. Separate features and labels
X = data[['acc_x','acc_y','acc_z','gyro_x','gyro_y','gyro_z']].values
y = data['label'].values

# 3. Encode labels to integers
le = LabelEncoder()
y_encoded = le.fit_transform(y)
y_categorical = to_categorical(y_encoded)

# 4. Reshape X for 1D CNN (samples, timesteps, features)
# If each row is a single timestep, reshape to (samples, timesteps=1, features=6)
X = X.reshape((X.shape[0], 1, X.shape[1]))

# 5. Split into train and test
X_train, X_test, y_train, y_test = train_test_split(X, y_categorical, test_size=0.2, random_state=42)

# 6. Build 1D CNN model
model = Sequential([
    Conv1D(64, kernel_size=1, activation='relu', input_shape=(X.shape[1], X.shape[2])),
    Conv1D(128, kernel_size=1, activation='relu'),
    MaxPooling1D(pool_size=1),
    Flatten(),
    Dense(128, activation='relu'),
    Dropout(0.5),
    Dense(y_categorical.shape[1], activation='softmax')
])

model.compile(optimizer='adam', loss='categorical_crossentropy', metrics=['accuracy'])
model.summary()

# 7. Train model
history = model.fit(X_train, y_train, epochs=100, batch_size=32, validation_split=0.2)

# 8. Evaluate
loss, acc = model.evaluate(X_test, y_test)
print(f"Test Accuracy: {acc*100:.2f}%")

# 9. Save model
model.save("phone_motion_cnn.h5")
