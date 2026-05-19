import os
import numpy as np
import librosa
import joblib
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder, StandardScaler
from sklearn.metrics import classification_report, accuracy_score
from imblearn.over_sampling import SMOTE
from collections import Counter
import warnings

warnings.filterwarnings("ignore")

# === CONFIG ===
AUDIO_DIR = r"C:\Projects 2025\DataSet\Voice Emotion\TESS_Toronto_emotional_speech_set_data\train"

MODEL_PATH = "engine_model.pkl"
SCALER_PATH = "scaler.pkl"
ENCODER_PATH = "label_encoder.pkl"


# === Improved Feature Extraction ===
def extract_features(file_path):
    try:
        # Load audio with error handling
        audio, sr = librosa.load(file_path, sr=22050, duration=3)  # Reduced from 10 to 3 seconds

        # Check if audio is loaded properly
        if len(audio) == 0:
            print(f"❌ Empty audio file: {file_path}")
            return None

        # Check audio energy
        rms = librosa.feature.rms(y=audio)[0]
        if np.mean(rms) < 0.001:
            print(f"⚠️ Low energy audio: {file_path}")
            return None

        # Extract features with error handling
        mfccs = np.mean(librosa.feature.mfcc(y=audio, sr=sr, n_mfcc=13).T, axis=0)
        chroma = np.mean(librosa.feature.chroma_stft(y=audio, sr=sr).T, axis=0)
        mel = np.mean(librosa.feature.melspectrogram(y=audio, sr=sr).T, axis=0)
        contrast = np.mean(librosa.feature.spectral_contrast(y=audio, sr=sr).T, axis=0)

        return np.hstack([mfccs, chroma, mel, contrast])

    except Exception as e:
        print(f"❌ Error with {file_path}: {e}")
        return None


# === Load and Process Dataset ===
X, y, valid_files = [], [], []

print("🔍 Scanning audio directory...")
emotion_folders = [f for f in os.listdir(AUDIO_DIR) if os.path.isdir(os.path.join(AUDIO_DIR, f))]

if not emotion_folders:
    print(f"❌ No emotion folders found in {AUDIO_DIR}")
    print(f"📁 Contents: {os.listdir(AUDIO_DIR)}")
    exit()

print(f"🎭 Found emotion folders: {emotion_folders}")

for emotion in emotion_folders:
    emotion_path = os.path.join(AUDIO_DIR, emotion)

    if not os.path.isdir(emotion_path):
        continue

    for filename in os.listdir(emotion_path):
        if filename.endswith(".wav"):
            file_path = os.path.join(emotion_path, filename)
            features = extract_features(file_path)

            if features is not None:
                X.append(features)
                y.append(emotion)  # Use folder name as label
                valid_files.append(filename)

# Check if we have any data
if len(X) == 0:
    print("❌ No valid audio files found! Check:")
    print("   - File paths")
    print("   - Audio file formats")
    print("   - Audio file durations")
    exit()

# Convert to numpy arrays
X = np.array(X)
y = np.array(y)

print(f"\n✅ Successfully processed {len(X)} audio files")
print("📊 Label distribution in training set:")
label_counts = Counter(y)
for label, count in label_counts.items():
    print(f"   {label}: {count} samples")

# === Encode Labels ===
encoder = LabelEncoder()
y_encoded = encoder.fit_transform(y)

print(f"🎯 Encoded labels: {list(zip(encoder.classes_, range(len(encoder.classes_))))}")

# === Balance Data Using SMOTE ===
print("\n⚖️ Applying SMOTE for class balancing...")
try:
    smote = SMOTE(random_state=42)
    X_balanced, y_balanced = smote.fit_resample(X, y_encoded)

    print("📊 After SMOTE balancing:")
    balanced_counts = Counter(y_balanced)
    for label_idx, count in balanced_counts.items():
        label_name = encoder.inverse_transform([label_idx])[0]
        print(f"   {label_name}: {count} samples")

except Exception as e:
    print(f"❌ SMOTE failed: {e}")
    print("⚠️ Continuing without SMOTE...")
    X_balanced, y_balanced = X, y_encoded

# === Scale Features ===
scaler = StandardScaler()
X_scaled = scaler.fit_transform(X_balanced)

# === Train-Test Split ===
X_train, X_test, y_train, y_test = train_test_split(
    X_scaled, y_balanced, test_size=0.2, random_state=42, stratify=y_balanced
)

print(f"\n📊 Training set: {X_train.shape[0]} samples")
print(f"📊 Testing set: {X_test.shape[0]} samples")

# === Model Training ===
print("\n🏋️ Training Random Forest model...")
model = RandomForestClassifier(n_estimators=100, random_state=42, verbose=1)
model.fit(X_train, y_train)

# === Evaluation ===
y_pred = model.predict(X_test)
accuracy = accuracy_score(y_test, y_pred)

print(f"\n✅ Accuracy: {accuracy:.4f}")
print("🔍 Classification Report:")
print(classification_report(y_test, y_pred, target_names=encoder.classes_))

# Feature importance
feature_importance = model.feature_importances_
print(f"📈 Max feature importance: {np.max(feature_importance):.4f}")

# === Save Model & Tools ===
joblib.dump(model, MODEL_PATH)
joblib.dump(scaler, SCALER_PATH)
joblib.dump(encoder, ENCODER_PATH)
print(f"\n💾 Model saved as: {MODEL_PATH}")
print(f"💾 Scaler saved as: {SCALER_PATH}")
print(f"💾 Encoder saved as: {ENCODER_PATH}")

# === Test Prediction ===
print("\n🧪 Testing prediction on first sample...")
if len(X_test) > 0:
    test_pred = model.predict(X_test[:1])
    test_prob = model.predict_proba(X_test[:1])
    predicted_emotion = encoder.inverse_transform(test_pred)[0]

    print(f"🎯 Test prediction: {predicted_emotion}")
    print("📊 Confidence scores:")
    for i, emotion in enumerate(encoder.classes_):
        print(f"   {emotion}: {test_prob[0][i]:.4f}")