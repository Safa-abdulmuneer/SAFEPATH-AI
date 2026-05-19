import os
import numpy as np
import librosa
import librosa.display
import matplotlib.pyplot as plt
from sklearn.model_selection import train_test_split
from tensorflow.keras.utils import to_categorical
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Conv2D, MaxPooling2D, Flatten, Dense, Dropout
from tensorflow.keras.preprocessing.image import ImageDataGenerator

# 🎯 Path to your dataset
DATASET_PATH = r"C:\Projects 2025\DataSet\Voice Emotion\TESS_Toronto_emotional_speech_set_data\train"

# 🎵 Parameters
SAMPLE_RATE = 22050
DURATION = 3  # seconds
SAMPLES_PER_TRACK = SAMPLE_RATE * DURATION

# 📂 Function to extract mel spectrograms
MAX_LENGTH = 130  # Adjust according to your dataset (number of time frames)


def extract_features(file_path):
    try:
        audio, sr = librosa.load(file_path, sr=SAMPLE_RATE, duration=DURATION)
        mel_spec = librosa.feature.melspectrogram(y=audio, sr=sr, n_mels=128)
        mel_spec_db = librosa.power_to_db(mel_spec, ref=np.max)

        # Pad or trim to MAX_LENGTH
        if mel_spec_db.shape[1] < MAX_LENGTH:
            pad_width = MAX_LENGTH - mel_spec_db.shape[1]
            mel_spec_db = np.pad(mel_spec_db, pad_width=((0, 0), (0, pad_width)), mode='constant')
        else:
            mel_spec_db = mel_spec_db[:, :MAX_LENGTH]

        return mel_spec_db
    except Exception as e:
        print(f"Error processing {file_path}: {e}")
        return None


# 🧩 Load dataset
X, y = [], []
emotions = os.listdir(DATASET_PATH)
for i, emotion in enumerate(emotions):
    folder = os.path.join(DATASET_PATH, emotion)
    for file in os.listdir(folder):
        if file.endswith('.wav'):
            path = os.path.join(folder, file)
            feature = extract_features(path)
            if feature is not None:
                X.append(feature)
                y.append(i)

# Convert to numpy arrays
X = np.array(X)
y = np.array(y)

# Reshape for CNN (add channel dimension)
X = X[..., np.newaxis]

# Normalize
X = X / np.max(X)

# One-hot encode labels
y = to_categorical(y, num_classes=len(emotions))

# Split dataset
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

print(f"✅ Data loaded: {X_train.shape[0]} training samples, {X_test.shape[0]} testing samples")

# 🧠 CNN Model
model = Sequential([
    Conv2D(32, (3, 3), activation='relu', input_shape=X_train[0].shape),
    MaxPooling2D((2, 2)),
    Dropout(0.2),

    Conv2D(64, (3, 3), activation='relu'),
    MaxPooling2D((2, 2)),
    Dropout(0.2),

    Flatten(),
    Dense(128, activation='relu'),
    Dropout(0.3),
    Dense(len(emotions), activation='softmax')
])

model.compile(optimizer='adam', loss='categorical_crossentropy', metrics=['accuracy'])
model.summary()

# 🏋️ Train
history = model.fit(
    X_train, y_train,
    epochs=30,
    batch_size=16,
    validation_data=(X_test, y_test)
)

# 💾 Save model
model.save("emotion_cnn_model.h5")
print("✅ Model saved as emotion_cnn_model.h5")
