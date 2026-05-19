import os
import datetime
import numpy as np
import librosa
import soundfile
from tensorflow.keras.models import load_model

# ✅ Define the observed emotions
observed_emotions = ['neutral', 'calm', 'happy', 'sad', 'angry', 'fearful', 'disgust', 'surprised']


# ✅ Improved feature extraction function
def extract_feature(file_name, max_pad_length=130):
    try:
        # Load audio file
        X, sample_rate = librosa.load(file_name, sr=None, duration=3)  # Limit to 3 seconds for consistency

        # Extract Mel spectrogram
        mel_spec = librosa.feature.melspectrogram(y=X, sr=sample_rate, n_mels=40, fmax=8000)
        mel_spec = librosa.power_to_db(mel_spec, ref=np.max)

        # Pad or truncate to fixed length
        if mel_spec.shape[1] < max_pad_length:
            pad_width = max_pad_length - mel_spec.shape[1]
            mel_spec = np.pad(mel_spec, ((0, 0), (0, pad_width)), mode='constant')
        else:
            mel_spec = mel_spec[:, :max_pad_length]

        return mel_spec.T

    except Exception as e:
        print(f"Error processing audio file: {e}")
        return None


# ✅ Improved prediction function
def predict_emotion(file_path, model, observed_emotions):
    try:
        # Extract features
        feature = extract_feature(file_path)

        if feature is None:
            return "Error: Could not extract features from audio"

        # Reshape for model input (batch_size, timesteps, features, channels)
        feature = np.expand_dims(feature, axis=-1)  # Add channel dim
        feature = np.expand_dims(feature, axis=0)  # Add batch dim

        print(f"Feature shape: {feature.shape}")  # Debug info

        # Predict
        prediction = model.predict(feature, verbose=0)

        # Get confidence scores
        confidence = np.max(prediction)
        predicted_label = np.argmax(prediction, axis=1)[0]

        # Map index → emotion
        predicted_emotion = observed_emotions[predicted_label]

        return predicted_emotion, confidence

    except Exception as e:
        return f"Error during prediction: {e}", 0.0


# ✅ Main script
if __name__ == "__main__":
    print("🎤 Voice Emotion Recognition")

    # ✅ Fixed: Use direct path instead of input()
    audio_path = r"C:\Projects 2025\DataSet\Voice Emotion\TESS_Toronto_emotional_speech_set_data\train\neutral\OAF_bought_neutral.wav"
    print(f"📁 Audio file: {audio_path}")

    if not os.path.exists(audio_path):
        print("❌ Error: File not found!")
        print("Please check the file path and try again.")
        exit(1)

    try:
        # Load the trained model with better error handling
        model_path = os.path.join(os.getcwd(), "emotion_recognition_model.h5")
        print(f"📂 Looking for model at: {model_path}")

        if not os.path.exists(model_path):
            print("❌ Model file not found!")
            print("Please ensure 'emotion_recognition_model.h5' is in the same directory as this script.")
            exit(1)

        print("🔄 Loading model...")
        model = load_model(model_path)
        print("✅ Model loaded successfully!")

        # Check file duration and sample rate
        duration = librosa.get_duration(filename=audio_path)
        print(f"📊 Audio duration: {duration:.2f} seconds")

        # Predict emotion
        emotion, confidence = predict_emotion(audio_path, model, observed_emotions)

        print(f"\n🎯 Prediction Results:")
        print(f"✅ Predicted Emotion: {emotion}")
        print(f"📈 Confidence: {confidence:.2%}")

    except Exception as e:
        print(f"❌ Error during prediction: {e}")
        print("\n🔧 Troubleshooting tips:")
        print("1. Check if the model architecture matches the expected input")
        print("2. Verify the audio file format (should be WAV)")
        print("3. Ensure the model was trained with similar features")