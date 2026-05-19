import librosa
import numpy as np
import tensorflow as tf
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Conv2D, MaxPooling2D, Flatten, Dense, Dropout, BatchNormalization
from tensorflow.keras.optimizers import Adam
from tensorflow.keras.utils import to_categorical
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder
import os
import matplotlib.pyplot as plt
from tqdm import tqdm
import warnings

warnings.filterwarnings('ignore')


def extract_features(file_path):
    """Enhanced feature extraction function"""
    SAMPLE_RATE = 22050
    DURATION = 3
    MAX_LENGTH = 130

    try:
        # Load audio file
        audio, sr = librosa.load(file_path, sr=SAMPLE_RATE, duration=DURATION)

        if len(audio) == 0:
            print(f"Empty audio file: {file_path}")
            return None

        # Extract multiple features
        # 1. Mel Spectrogram
        mel_spec = librosa.feature.melspectrogram(y=audio, sr=sr, n_mels=128, fmax=8000)
        mel_spec_db = librosa.power_to_db(mel_spec, ref=np.max)

        # 2. MFCC features
        mfcc = librosa.feature.mfcc(y=audio, sr=sr, n_mfcc=13)
        mfcc_delta = librosa.feature.delta(mfcc)
        mfcc_delta2 = librosa.feature.delta(mfcc, order=2)

        # Combine features
        combined_features = np.vstack([mel_spec_db, mfcc, mfcc_delta, mfcc_delta2])

        # Pad or truncate to fixed size
        if combined_features.shape[1] < MAX_LENGTH:
            pad_width = MAX_LENGTH - combined_features.shape[1]
            combined_features = np.pad(combined_features,
                                       pad_width=((0, 0), (0, pad_width)),
                                       mode='constant')
        else:
            combined_features = combined_features[:, :MAX_LENGTH]

        return combined_features

    except Exception as e:
        print(f"Error processing {file_path}: {e}")
        return None


def load_dataset(data_path):
    """Load and preprocess the entire dataset"""
    emotions = ['angry', 'disgust', 'fear', 'happy', 'neutral', 'sad', 'surprise']

    features = []
    labels = []
    file_paths = []

    print("📂 Loading dataset...")

    for emotion in emotions:
        emotion_path = os.path.join(data_path, emotion)

        if not os.path.exists(emotion_path):
            print(f"⚠️  Directory not found: {emotion_path}")
            continue

        # Get all audio files
        audio_files = [f for f in os.listdir(emotion_path) if f.endswith('.wav')]

        print(f"🎵 Processing {len(audio_files)} files for {emotion}...")

        for audio_file in tqdm(audio_files, desc=f"{emotion}"):
            file_path = os.path.join(emotion_path, audio_file)

            # Extract features
            feature = extract_features(file_path)

            if feature is not None:
                features.append(feature)
                labels.append(emotion)
                file_paths.append(file_path)

    return np.array(features), np.array(labels), file_paths


def create_model(input_shape, num_classes):
    """Create a CNN model for emotion recognition"""
    model = Sequential([
        # First Conv Block
        Conv2D(32, (3, 3), activation='relu', input_shape=input_shape),
        BatchNormalization(),
        MaxPooling2D((2, 2)),
        Dropout(0.25),

        # Second Conv Block
        Conv2D(64, (3, 3), activation='relu'),
        BatchNormalization(),
        MaxPooling2D((2, 2)),
        Dropout(0.25),

        # Third Conv Block
        Conv2D(128, (3, 3), activation='relu'),
        BatchNormalization(),
        MaxPooling2D((2, 2)),
        Dropout(0.25),

        # Fourth Conv Block
        Conv2D(256, (3, 3), activation='relu'),
        BatchNormalization(),
        MaxPooling2D((2, 2)),
        Dropout(0.25),

        # Classifier
        Flatten(),
        Dense(512, activation='relu'),
        BatchNormalization(),
        Dropout(0.5),
        Dense(256, activation='relu'),
        Dropout(0.5),
        Dense(num_classes, activation='softmax')
    ])

    return model


def plot_training_history(history):
    """Plot training history"""
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(12, 4))

    # Plot accuracy
    ax1.plot(history.history['accuracy'], label='Training Accuracy')
    ax1.plot(history.history['val_accuracy'], label='Validation Accuracy')
    ax1.set_title('Model Accuracy')
    ax1.set_xlabel('Epoch')
    ax1.set_ylabel('Accuracy')
    ax1.legend()

    # Plot loss
    ax2.plot(history.history['loss'], label='Training Loss')
    ax2.plot(history.history['val_loss'], label='Validation Loss')
    ax2.set_title('Model Loss')
    ax2.set_xlabel('Epoch')
    ax2.set_ylabel('Loss')
    ax2.legend()

    plt.tight_layout()
    plt.savefig('training_history.png', dpi=300, bbox_inches='tight')
    plt.show()


def train_model():
    """Main training function"""
    # Configuration
    DATA_PATH = r"C:\Projects 2025\DataSet\archive\dataset\train"
    MODEL_SAVE_PATH = "emotion_cnn_model_improved.h5"

    print("🚀 Starting Model Training...")

    # Check if data path exists
    if not os.path.exists(DATA_PATH):
        print(f"❌ Data path not found: {DATA_PATH}")
        return

    # Load dataset
    X, y, file_paths = load_dataset(DATA_PATH)

    if len(X) == 0:
        print("❌ No features extracted. Check your data path and audio files.")
        return

    print(f"\n📊 Dataset Summary:")
    print(f"   Total samples: {len(X)}")
    print(f"   Feature shape: {X[0].shape}")
    print(f"   Classes: {np.unique(y)}")

    # Encode labels
    label_encoder = LabelEncoder()
    y_encoded = label_encoder.fit_transform(y)
    y_categorical = to_categorical(y_encoded)

    print(f"   Encoded classes: {label_encoder.classes_}")

    # Reshape data for CNN (add channel dimension)
    X_reshaped = X[..., np.newaxis]

    # Split data
    X_train, X_test, y_train, y_test = train_test_split(
        X_reshaped, y_categorical, test_size=0.2, random_state=42, stratify=y_encoded
    )

    X_train, X_val, y_train, y_val = train_test_split(
        X_train, y_train, test_size=0.2, random_state=42, stratify=np.argmax(y_train, axis=1)
    )

    print(f"\n📈 Data Split:")
    print(f"   Training samples: {X_train.shape[0]}")
    print(f"   Validation samples: {X_val.shape[0]}")
    print(f"   Test samples: {X_test.shape[0]}")

    # Normalize features
    X_train = (X_train - np.min(X_train)) / (np.max(X_train) - np.min(X_train))
    X_val = (X_val - np.min(X_val)) / (np.max(X_val) - np.min(X_val))
    X_test = (X_test - np.min(X_test)) / (np.max(X_test) - np.min(X_test))

    # Create model
    input_shape = X_train[0].shape
    num_classes = len(label_encoder.classes_)

    print(f"\n🤖 Creating Model...")
    print(f"   Input shape: {input_shape}")
    print(f"   Number of classes: {num_classes}")

    model = create_model(input_shape, num_classes)

    # Compile model
    model.compile(
        optimizer=Adam(learning_rate=0.001),
        loss='categorical_crossentropy',
        metrics=['accuracy']
    )

    print("\n📋 Model Architecture:")
    model.summary()

    # Callbacks
    callbacks = [
        tf.keras.callbacks.EarlyStopping(
            monitor='val_loss',
            patience=15,
            restore_best_weights=True
        ),
        tf.keras.callbacks.ReduceLROnPlateau(
            monitor='val_loss',
            factor=0.5,
            patience=10,
            min_lr=1e-7
        ),
        tf.keras.callbacks.ModelCheckpoint(
            MODEL_SAVE_PATH,
            monitor='val_accuracy',
            save_best_only=True,
            mode='max'
        )
    ]

    # Train model
    print("\n🎯 Starting Training...")
    history = model.fit(
        X_train, y_train,
        batch_size=32,
        epochs=100,
        validation_data=(X_val, y_val),
        callbacks=callbacks,
        verbose=1
    )

    # Evaluate model
    print("\n📊 Evaluating Model...")
    train_loss, train_accuracy = model.evaluate(X_train, y_train, verbose=0)
    val_loss, val_accuracy = model.evaluate(X_val, y_val, verbose=0)
    test_loss, test_accuracy = model.evaluate(X_test, y_test, verbose=0)

    print(f"\n🎯 Final Results:")
    print(f"   Training Accuracy: {train_accuracy:.4f}")
    print(f"   Validation Accuracy: {val_accuracy:.4f}")
    print(f"   Test Accuracy: {test_accuracy:.4f}")

    # Plot training history
    plot_training_history(history)

    # Save the final model
    model.save(MODEL_SAVE_PATH)
    print(f"\n💾 Model saved as: {MODEL_SAVE_PATH}")

    # Save label encoder
    np.save('label_encoder_classes.npy', label_encoder.classes_)
    print("💾 Label encoder saved as: label_encoder_classes.npy")

    return model, history, label_encoder


def quick_test_trained_model():
    """Test the newly trained model"""
    print("\n🧪 Testing Trained Model...")

    model_path = "emotion_cnn_model_improved.h5"
    label_encoder_path = "label_encoder_classes.npy"
    test_path = r"C:\Projects 2025\DataSet\archive\dataset\train"

    if not os.path.exists(model_path):
        print("❌ Trained model not found. Please train the model first.")
        return

    # Load model and label encoder
    model = tf.keras.models.load_model(model_path)
    label_encoder_classes = np.load(label_encoder_path, allow_pickle=True)

    emotions = list(label_encoder_classes)

    # Find all audio files
    all_files = []
    for emotion in emotions:
        emotion_path = os.path.join(test_path, emotion)
        if os.path.exists(emotion_path):
            files = [os.path.join(emotion_path, f) for f in os.listdir(emotion_path)
                     if f.endswith('.wav')]
            all_files.extend(files)

    if not all_files:
        print("❌ No test files found!")
        return

    # Test random files
    import random
    num_files = min(20, len(all_files))
    test_files = random.sample(all_files, num_files)
    correct = 0

    print(f"🎯 Testing {num_files} random files...\n")

    for i, file_path in enumerate(test_files, 1):
        true_emotion = os.path.basename(os.path.dirname(file_path))

        # Predict
        feature = extract_features(file_path)
        if feature is None:
            continue

        features = feature[np.newaxis, ..., np.newaxis]
        features = (features - np.min(features)) / (np.max(features) - np.min(features))

        prediction = model.predict(features, verbose=0)
        pred_idx = np.argmax(prediction)
        pred_emotion = emotions[pred_idx]
        confidence = np.max(prediction)

        status = "✅" if true_emotion == pred_emotion else "❌"
        if true_emotion == pred_emotion:
            correct += 1

        print(f"{status} [{i:2d}/{num_files}] {true_emotion:8s} -> {pred_emotion:8s} (conf: {confidence:.2f})")

    accuracy = correct / num_files
    print(f"\n📊 TEST RESULTS:")
    print(f"🎯 Accuracy: {accuracy:.1%} ({correct}/{num_files})")


# Run training
if __name__ == "__main__":
    # Train the model
    model, history, label_encoder = train_model()

    # Test the trained model
    quick_test_trained_model()