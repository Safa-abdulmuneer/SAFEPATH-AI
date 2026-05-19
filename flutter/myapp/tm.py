import librosa
import numpy as np
import tensorflow as tf
from tensorflow.keras.models import load_model
import os
import random


def extract_features(file_path):
    """Feature extraction function"""
    SAMPLE_RATE = 22050
    DURATION = 3
    MAX_LENGTH = 130

    try:
        audio, sr = librosa.load(file_path, sr=SAMPLE_RATE, duration=DURATION)

        if len(audio) == 0:
            return None

        mel_spec = librosa.feature.melspectrogram(y=audio, sr=sr, n_mels=128, fmax=8000)
        mel_spec_db = librosa.power_to_db(mel_spec, ref=np.max)

        if mel_spec_db.shape[1] < MAX_LENGTH:
            pad_width = MAX_LENGTH - mel_spec_db.shape[1]
            mel_spec_db = np.pad(mel_spec_db, pad_width=((0, 0), (0, pad_width)), mode='constant')
        else:
            mel_spec_db = mel_spec_db[:, :MAX_LENGTH]

        return mel_spec_db
    except Exception as e:
        print(f"Error processing {file_path}: {e}")
        return None


def quick_test():
    """Ultra quick test with random files"""
    print("🚀 Starting quick model test...")

    model_path = r"C:\Users\VIPIN KARMA\Downloads\Telegram Desktop\shecare30-12-24\shecare30-12-24\SheCare (2)\SheCare\myapp\emotion_cnn_model.h5"
    test_path = r"C:\Projects 2025\DataSet\archive\dataset\train"

    # Check if paths exist
    if not os.path.exists(model_path):
        print(f"❌ Model not found at: {model_path}")
        return

    if not os.path.exists(test_path):
        print(f"❌ Test data not found at: {test_path}")
        return

    # Load model
    try:
        model = load_model(model_path)
        print("✅ Model loaded successfully!")
    except Exception as e:
        print(f"❌ Error loading model: {e}")
        return

    emotions = ['angry', 'disgust', 'fear', 'happy', 'neutral', 'sad', 'surprise']

    # Find all audio files
    all_files = []
    for emotion in emotions:
        emotion_path = os.path.join(test_path, emotion)
        if os.path.exists(emotion_path):
            files = [os.path.join(emotion_path, f) for f in os.listdir(emotion_path)
                     if f.endswith('.wav')]
            all_files.extend(files)
            print(f"📁 Found {len(files)} files in {emotion}")

    if not all_files:
        print("❌ No test files found!")
        return

    # Test random files
    num_files = min(20, len(all_files))
    test_files = random.sample(all_files, num_files)
    correct = 0

    print(f"\n🎯 Testing {num_files} random files...\n")

    for i, file_path in enumerate(test_files, 1):
        true_emotion = os.path.basename(os.path.dirname(file_path))

        # Predict
        feature = extract_features(file_path)
        if feature is None:
            print(f"⚠️  Skipping {os.path.basename(file_path)} - feature extraction failed")
            continue

        features = feature[np.newaxis, ..., np.newaxis]
        features_min = np.min(features)
        features_max = np.max(features)
        if features_max - features_min > 0:
            features = (features - features_min) / (features_max - features_min)

        prediction = model.predict(features, verbose=0)
        pred_idx = np.argmax(prediction)
        pred_emotion = emotions[pred_idx]
        confidence = np.max(prediction)

        status = "✅" if true_emotion == pred_emotion else "❌"
        if true_emotion == pred_emotion:
            correct += 1

        print(f"{status} [{i:2d}/{num_files}] {true_emotion:8s} -> {pred_emotion:8s} (conf: {confidence:.2f})")

    accuracy = correct / len(test_files)
    print(f"\n📊 FINAL RESULTS:")
    print(f"🎯 Accuracy: {accuracy:.1%} ({correct}/{len(test_files)})")

    # Performance assessment
    if accuracy > 0.7:
        print("💪 EXCELLENT - Model is performing well!")
    elif accuracy > 0.5:
        print("✅ GOOD - Model is performing decently")
    else:
        print("❌ POOR - Model needs improvement")


# Run the test directly
if __name__ == "__main__":
    quick_test()