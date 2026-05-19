# import librosa
# import numpy as np
# import tensorflow as tf
# from tensorflow.keras.models import load_model
# import os
#
#
# def load_trained_model(model_path):
#     """Load your pre-trained model"""
#     try:
#         model = load_model(model_path)
#         print(f"✅ Model loaded successfully from {model_path}")
#         return model
#     except Exception as e:
#         print(f"❌ Error loading model: {e}")
#         return None
#
#
# def extract_features(file_path):
#     """Use the EXACT same function as during training with proper error handling"""
#     SAMPLE_RATE = 22050
#     DURATION = 3  # seconds
#     MAX_LENGTH = 130  # Must match your training parameter
#
#     try:
#         # Load audio with proper error handling
#         audio, sr = librosa.load(file_path, sr=SAMPLE_RATE, duration=DURATION)
#
#         # Check if audio is loaded properly
#         if len(audio) == 0:
#             print(f"❌ Empty audio file: {file_path}")
#             return None
#
#         # Check audio energy (avoid silent files)
#         audio_energy = np.sum(audio ** 2)
#         if audio_energy < 0.001:  # Threshold for silent audio
#             print(f"⚠️  Very low audio energy: {file_path}")
#
#         mel_spec = librosa.feature.melspectrogram(y=audio, sr=sr, n_mels=128, fmax=8000)
#         mel_spec_db = librosa.power_to_db(mel_spec, ref=np.max)
#
#         # Pad or trim to MAX_LENGTH (same as training)
#         if mel_spec_db.shape[1] < MAX_LENGTH:
#             pad_width = MAX_LENGTH - mel_spec_db.shape[1]
#             mel_spec_db = np.pad(mel_spec_db, pad_width=((0, 0), (0, pad_width)), mode='constant')
#         else:
#             mel_spec_db = mel_spec_db[:, :MAX_LENGTH]
#
#         print(
#             f"📊 Feature stats - Min: {np.min(mel_spec_db):.2f}, Max: {np.max(mel_spec_db):.2f}, Mean: {np.mean(mel_spec_db):.2f}")
#         return mel_spec_db
#
#     except Exception as e:
#         print(f"❌ Error processing {file_path}: {e}")
#         return None
#
#
# def predict_emotion(audio_file, model):
#     """Predict emotion from audio file"""
#     # Extract features using the same function as training
#     feature = extract_features(audio_file)
#
#     if feature is None:
#         return "error", 0.0
#
#     # Reshape for CNN (add channel dimension and batch dimension)
#     features = feature[np.newaxis, ..., np.newaxis]
#
#     # Safe normalization - avoid division by zero
#     max_val = np.max(features)
#     if max_val > 0:
#         features = features / max_val
#     else:
#         print("⚠️  All-zero features detected, skipping normalization")
#
#     print(f"🎯 Input shape for model: {features.shape}")
#     print(f"📈 Normalized feature range: [{np.min(features):.3f}, {np.max(features):.3f}]")
#
#     # Make prediction
#     prediction = model.predict(features, verbose=0)
#     emotion_idx = np.argmax(prediction)
#     confidence = np.max(prediction)
#
#     # Print all confidence scores for debugging
#     emotions = ['angry', 'disgust', 'fear', 'happy', 'neutral', 'sad', 'surprise']
#     print("📊 Confidence scores:")
#     for i, (emotion, score) in enumerate(zip(emotions, prediction[0])):
#         print(f"   {emotion}: {score:.3f}")
#
#     return emotions[emotion_idx], confidence
#
#
# # Load your trained model
# model_path = r"C:\Users\VIPIN KARMA\Downloads\Telegram Desktop\shecare30-12-24\shecare30-12-24\SheCare (2)\SheCare\myapp\emotion_cnn_model.h5"
# model = load_trained_model(model_path)
#
# if model is not None:
#     print("✅ Model loaded successfully!")
#     print(f"📐 Model expects input shape: {model.input_shape}")
#
#     # Test prediction
#     audio_file = r"C:\Projects 2025\DataSet\Voice Emotion\TESS_Toronto_emotional_speech_set_data\train\happy\OAF_bone_happy.wav"
#
#     if os.path.exists(audio_file):
#         print(f"🎵 Processing audio file: {audio_file}")
#         emotion, confidence = predict_emotion(audio_file, model)
#         print(f"🎯 Final prediction: {emotion} (confidence: {confidence:.2f})")
#
#         # Confidence interpretation
#         if confidence < 0.3:
#             print("⚠️  Low confidence - model is uncertain")
#         elif confidence < 0.6:
#             print("✅ Moderate confidence")
#         else:
#             print("🎉 High confidence prediction!")
#
#     else:
#         print(f"❌ Audio file not found: {audio_file}")
# else:
#     print("❌ Failed to load model")



import librosa
import numpy as np
import tensorflow as tf
from tensorflow.keras.models import load_model
import os


def load_trained_model(model_path):
    """Load your pre-trained model"""
    try:
        model = load_model(model_path)
        print(f"✅ Model loaded successfully from {model_path}")
        return model
    except Exception as e:
        print(f"❌ Error loading model: {e}")
        return None


def extract_features(file_path):
    """Use the EXACT same function as during training with proper error handling"""
    SAMPLE_RATE = 22050
    DURATION = 3  # seconds
    MAX_LENGTH = 130  # Must match your training parameter

    try:
        # Load audio with proper error handling
        audio, sr = librosa.load(file_path, sr=SAMPLE_RATE, duration=DURATION)

        # Check if audio is loaded properly
        if len(audio) == 0:
            print(f"❌ Empty audio file: {file_path}")
            return None

        # Check audio energy (avoid silent files)
        audio_energy = np.sum(audio ** 2)
        if audio_energy < 0.001:  # Threshold for silent audio
            print(f"⚠️  Very low audio energy: {file_path}")

        mel_spec = librosa.feature.melspectrogram(y=audio, sr=sr, n_mels=128, fmax=8000)
        mel_spec_db = librosa.power_to_db(mel_spec, ref=np.max)

        # Pad or trim to MAX_LENGTH (same as training)
        if mel_spec_db.shape[1] < MAX_LENGTH:
            pad_width = MAX_LENGTH - mel_spec_db.shape[1]
            mel_spec_db = np.pad(mel_spec_db, pad_width=((0, 0), (0, pad_width)), mode='constant')
        else:
            mel_spec_db = mel_spec_db[:, :MAX_LENGTH]

        print(
            f"📊 Feature stats - Min: {np.min(mel_spec_db):.2f}, Max: {np.max(mel_spec_db):.2f}, Mean: {np.mean(mel_spec_db):.2f}")
        return mel_spec_db

    except Exception as e:
        print(f"❌ Error processing {file_path}: {e}")
        return None


def predict_emotion(audio_file, model):
    """Predict emotion from audio file"""
    # Extract features using the same function as training
    feature = extract_features(audio_file)

    if feature is None:
        return "error", 0.0

    # Reshape for CNN (add channel dimension and batch dimension)
    features = feature[np.newaxis, ..., np.newaxis]

    # FIXED: Proper normalization for dB-scale mel spectrograms
    # Since mel_spec_db has negative values, we need to scale to [0, 1] range
    features_min = np.min(features)
    features_max = np.max(features)

    if features_max - features_min > 0:
        # Normalize to [0, 1] range
        features = (features - features_min) / (features_max - features_min)
        print(f"✅ Features normalized to range: [{np.min(features):.3f}, {np.max(features):.3f}]")
    else:
        # If all values are the same, set to zeros or handle appropriately
        print("⚠️  Constant features detected, setting to zeros")
        features = np.zeros_like(features)

    print(f"🎯 Input shape for model: {features.shape}")
    print(f"📈 Normalized feature range: [{np.min(features):.3f}, {np.max(features):.3f}]")

    # Make prediction
    prediction = model.predict(features, verbose=0)
    emotion_idx = np.argmax(prediction)
    confidence = np.max(prediction)

    # Print all confidence scores for debugging
    emotions = ['angry', 'disgust', 'fear', 'happy', 'neutral', 'sad', 'surprise']
    print("📊 Confidence scores:")
    for i, (emotion, score) in enumerate(zip(emotions, prediction[0])):
        print(f"   {emotion}: {score:.3f}")

    return emotions[emotion_idx], confidence


# Load your trained model
model_path = r"C:\Users\VIPIN KARMA\Downloads\Telegram Desktop\shecare30-12-24\shecare30-12-24\SheCare (2)\SheCare\myapp\emotion_cnn_model.h5"
model = load_trained_model(model_path)

if model is not None:
    print("✅ Model loaded successfully!")
    print(f"📐 Model expects input shape: {model.input_shape}")

    # Test prediction
    audio_file = r"C:\Projects 2025\DataSet\Voice Emotion\TESS_Toronto_emotional_speech_set_data\train\happy\OAF_bone_happy.wav"

    if os.path.exists(audio_file):
        print(f"🎵 Processing audio file: {audio_file}")
        emotion, confidence = predict_emotion(audio_file, model)
        print(f"🎯 Final prediction: {emotion} (confidence: {confidence:.2f})")

        # Confidence interpretation
        if confidence < 0.3:
            print("⚠️  Low confidence - model is uncertain")
        elif confidence < 0.6:
            print("✅ Moderate confidence")
        else:
            print("🎉 High confidence prediction!")

    else:
        print(f"❌ Audio file not found: {audio_file}")
else:
    print("❌ Failed to load model")