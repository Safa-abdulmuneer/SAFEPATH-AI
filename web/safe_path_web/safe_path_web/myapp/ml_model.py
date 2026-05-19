import pandas as pd
import numpy as np
import joblib
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder
from sklearn.metrics import accuracy_score, classification_report
import os


class SafetyPredictor:
    def __init__(self):
        self.model = None
        self.label_encoders = {}
        self.feature_columns = ['Area', 'Zone', 'Time', 'People.Frequency', 'Is.Police_Station',
                                'Is.Bar', 'Tier', 'Residence.Level', 'Day_of_Week', 'Lighting']
        self.target_column = 'Class'

    def load_and_preprocess_data(self, csv_path):
        """Load and preprocess the dataset"""
        print("📊 Loading dataset...")
        df = pd.read_csv(csv_path)
        print(f"✅ Dataset loaded: {df.shape[0]} rows, {df.shape[1]} columns")

        # Separate features and target
        X = df[self.feature_columns]
        y = df[self.target_column]

        # Encode categorical variables
        for column in X.columns:
            if X[column].dtype == 'object':
                le = LabelEncoder()
                X[column] = le.fit_transform(X[column].astype(str))
                self.label_encoders[column] = le
                print(f"✅ Encoded {column}: {len(le.classes_)} classes")

        # Encode target variable
        self.target_encoder = LabelEncoder()
        y_encoded = self.target_encoder.fit_transform(y)
        print(f"✅ Target classes: {list(self.target_encoder.classes_)}")

        return X, y_encoded

    def train(self, X, y):
        """Train Random Forest model"""
        print("🌲 Training Random Forest model...")

        # Split data
        X_train, X_test, y_train, y_test = train_test_split(
            X, y, test_size=0.2, random_state=42, stratify=y
        )
        print(f"✅ Train size: {len(X_train)}, Test size: {len(X_test)}")

        # Train model
        self.model = RandomForestClassifier(
            n_estimators=100,
            max_depth=10,
            random_state=42,
            n_jobs=-1
        )
        self.model.fit(X_train, y_train)
        print("✅ Model training complete")

        # Evaluate
        y_pred = self.model.predict(X_test)
        accuracy = accuracy_score(y_test, y_pred)
        print(f"📊 Model Accuracy: {accuracy:.2%}")

        # Feature importance
        feature_importance = pd.DataFrame({
            'feature': self.feature_columns,
            'importance': self.model.feature_importances_
        }).sort_values('importance', ascending=False)
        print("\n📊 Feature Importance:")
        print(feature_importance)

        return accuracy

    def predict(self, features):
        """Predict safety class for given features"""
        if self.model is None:
            raise Exception("Model not trained yet")

        # Convert features to DataFrame
        df = pd.DataFrame([features])

        # Encode categorical features
        for column in self.feature_columns:
            if column in df.columns and column in self.label_encoders:
                try:
                    df[column] = self.label_encoders[column].transform([str(df[column].iloc[0])])[0]
                except:
                    # If value not seen during training, use most common class
                    df[column] = 0

        # Ensure correct feature order
        df = df[self.feature_columns]

        # Predict
        prediction_encoded = self.model.predict(df)[0]
        probabilities = self.model.predict_proba(df)[0]

        # Decode prediction
        prediction = self.target_encoder.inverse_transform([prediction_encoded])[0]

        # Get probability for predicted class
        prob_index = list(self.target_encoder.classes_).index(prediction)
        confidence = probabilities[prob_index]

        return {
            'prediction': prediction,
            'confidence': float(confidence),
            'probabilities': {
                class_name: float(prob)
                for class_name, prob in zip(self.target_encoder.classes_, probabilities)
            }
        }

    def save_model(self, model_path='safety_model.pkl', encoders_path='label_encoders.pkl'):
        """Save model and encoders"""
        joblib.dump(self.model, model_path)
        joblib.dump({
            'label_encoders': self.label_encoders,
            'target_encoder': self.target_encoder,
            'feature_columns': self.feature_columns
        }, encoders_path)
        print(f"✅ Model saved to {model_path}")
        print(f"✅ Encoders saved to {encoders_path}")

    def load_model(self, model_path='safety_model.pkl', encoders_path='label_encoders.pkl'):
        """Load model and encoders"""
        self.model = joblib.load(model_path)
        encoders_data = joblib.load(encoders_path)
        self.label_encoders = encoders_data['label_encoders']
        self.target_encoder = encoders_data['target_encoder']
        self.feature_columns = encoders_data['feature_columns']
        print(f"✅ Model loaded from {model_path}")
        return self


# Training script
def train_and_save_model():
    """Main function to train and save model"""
    # Get the directory of this script
    current_dir = r"C:\\Users\\sayan\\PycharmProjects\\safe_path_web\\myapp\\"
    # csv_path = os.path.join(current_dir, 'augmented_safety_dataset.csv')
    csv_path = r"C:\\Users\\sayan\\PycharmProjects\\safe_path_web\\augmented_safety_dataset.csv"
    # Initialize predictor
    predictor = SafetyPredictor()

    # Load and preprocess data
    X, y = predictor.load_and_preprocess_data(csv_path)

    # Train model
    accuracy = predictor.train(X, y)

    # Save model
    predictor.save_model(model_path=os.path.join(current_dir, 'safety_model_new.pkl'), encoders_path=os.path.join(current_dir, 'label_encoders_new.pkl'))

    return predictor, accuracy


if __name__ == "__main__":
    predictor, accuracy = train_and_save_model()
    print(f"\n🎯 Final Model Accuracy: {accuracy:.2%}")