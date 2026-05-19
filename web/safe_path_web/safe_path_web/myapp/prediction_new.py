
import joblib
import pandas as pd
import requests
from datetime import datetime
import os

# ── Hardcoded known locations ──────────────────────────────────────
# Add more locations here as needed
KNOWN_LOCATIONS = [
    {
        'name':             'College of Engineering Trikaripur - CS Dept',
        'lat':              12.24311711736057,
        'lon':              75.23460681724976,
        'radius_meters':    300,
        'area':             'Trikaripur',
        'zone':             'Cheemeni',
        'tier':             'Outer',
        'residence_level':  'Low',
        'is_police':        'Yes',
        'is_bar':           'No',
        'people_frequency': 'Low',
        'description':      'Educational zone, forested surroundings',
    },
    {
        'name':             'Andamkovval',
        'lat':              12.080575279858149,
        'lon':              75.24045288528447,
        'radius_meters':    400,
        'area':             'Andamkovval',
        'zone':             'Andamkovval',
        'tier':             'Outer',
        'residence_level':  'High',
        'is_police':        'No',
        'is_bar':           'No',
        'people_frequency': 'Medium',
        'description':      'Residential area with shops, busy mornings quiet nights',
    },
    # Add more locations below in same format
]

# ── Helper: calculate distance between two GPS points (meters) ─────
def gps_distance(lat1, lon1, lat2, lon2):
    from math import radians, sin, cos, sqrt, atan2
    R = 6371000
    a = (sin(radians(lat2 - lat1) / 2) ** 2 +
         cos(radians(lat1)) * cos(radians(lat2)) *
         sin(radians(lon2 - lon1) / 2) ** 2)
    return R * 2 * atan2(sqrt(a), sqrt(1 - a))

# ── Helper: check if GPS matches a known location ──────────────────
def check_known_location(lat, lon):
    for loc in KNOWN_LOCATIONS:
        dist = gps_distance(lat, lon, loc['lat'], loc['lon'])
        if dist <= loc['radius_meters']:
            print(f"📌 Matched known location: {loc['name']} ({dist:.0f}m away)")
            return loc
    return None

# ── Load model and encoders ────────────────────────────────────────
BASE = os.path.dirname(os.path.abspath(__file__))
model         = joblib.load(os.path.join(BASE, 'safety_model.pkl'))
encoders_data = joblib.load(os.path.join(BASE, 'label_encoders.pkl'))

label_encoders  = encoders_data['label_encoders']
target_encoder  = encoders_data['target_encoder']
feature_columns = encoders_data['feature_columns']

print("✅ Model loaded successfully!")
print(f"📊 Features: {feature_columns}")
print(f"🎯 Classes: {list(target_encoder.classes_)}")


# ── Helper: get time and lighting from current clock ──────────────
def get_time_and_lighting():
    hour = datetime.now().hour
    if 5 <= hour < 12:
        return 'Morning', 'Good'
    elif 12 <= hour < 17:
        return 'Afternoon', 'Good'
    elif 17 <= hour < 21:
        return 'Evening', 'Moderate'
    else:
        return 'Night', 'Poor'


# ── Helper: get area/zone from GPS using Nominatim ─────────────────
def get_area_zone(lat, lon):
    try:
        resp = requests.get(
            'https://nominatim.openstreetmap.org/reverse',
            params={'lat': lat, 'lon': lon, 'format': 'json',  'addressdetails': 1},
            headers={'User-Agent': 'SafePathAI/1.0'},
            timeout=5
        )
        print("Response : ", resp.status_code)
        if resp.status_code == 200:
            data    = resp.json()
            address = data.get('address', {})
            print(address)
            area = (address.get('suburb') or address.get('neighbourhood') or
                    address.get('city_district') or address.get('town') or
                    address.get('village') or address.get('county') or
                    address.get('city') or
                    'Ramapuram')

            # Try to get zone (most granular to least)
            zone = (address.get('state_district') or address.get('quarter') or address.get('residential') or
                    address.get('neighbourhood') or address.get('suburb') or
                    address.get('hamlet') or address.get('village') or area)
            rank = data.get('place_rank', 20)
            tier = 'Inner' if rank <= 16 else 'Middle' if rank <= 20 else 'Outer'
            return area, zone, tier
    except Exception as e:
        print(f"⚠️ Nominatim error: {e}")
    return 'Ramapuram', 'Amman Nagar', 'Middle'


# ── Helper: check nearby police/bar using Overpass ─────────────────
def get_nearby_places(lat, lon):
    try:
        query = f"""
        [out:json][timeout:10];
        (
          node["amenity"="police"](around:1000,{lat},{lon});
          node["amenity"="bar"](around:500,{lat},{lon});
          node["amenity"="pub"](around:500,{lat},{lon});
          node["amenity"="restaurant"](around:300,{lat},{lon});
          node["amenity"="cafe"](around:300,{lat},{lon});
          node["shop"](around:300,{lat},{lon});
        );
        out body;
        """
        resp = requests.post(
            'https://overpass-api.de/api/interpreter',
            data=query, timeout=10
        )
        if resp.status_code == 200:
            elements       = resp.json().get('elements', [])
            print(elements)
            police_count   = sum(1 for e in elements if e.get('tags',{}).get('amenity') == 'police')
            bar_count      = sum(1 for e in elements if e.get('tags',{}).get('amenity') in ['bar','pub'])
            activity_count = sum(1 for e in elements if e.get('tags',{}).get('amenity') in ['restaurant','cafe'] or 'shop' in e.get('tags',{}))

            is_police = 'Yes' if police_count > 0 else 'No'
            is_bar    = 'Yes' if bar_count > 0 else 'No'
            total     = activity_count + bar_count
            people    = 'High' if total > 5 else 'Medium' if total > 2 else 'Low'
            return is_police, is_bar, people
    except Exception as e:
        print(f"⚠️ Overpass error: {e}")
    return 'No', 'No', 'Medium'


# ── Main prediction endpoint ───────────────────────────────────────
# @app.route('/predict-by-location/', methods=['POST'])
# def predict_by_location():
#     try:
#         data = request.get_json()
#         lat  = float(data.get('latitude'))
#         lon  = float(data.get('longitude'))
#         print(f"\n📍 Request received: {lat}, {lon}")
#
#         # Auto-fetch all features
#         time_of_day, lighting = get_time_and_lighting()
#         day_of_week           = datetime.now().strftime('%A')
#
#         # Check known locations first
#         known = check_known_location(lat, lon)
#         if known:
#             area        = known['area']
#             zone        = known['zone']
#             tier        = known['tier']
#             residence   = known['residence_level']
#             is_police   = known['is_police']
#             is_bar      = known['is_bar']
#             matched_name= known['name']
#
#             # Smart people frequency — override based on time for some locations
#             hour = datetime.now().hour
#             if known['name'] == 'Andamkovval':
#                 # Busy in morning (shops open), quiet at night
#                 if 6 <= hour < 12:
#                     people_freq = 'High'    # morning shops busy
#                 elif 12 <= hour < 18:
#                     people_freq = 'Medium'  # afternoon moderate
#                 else:
#                     people_freq = 'Low'     # night quiet residential
#             else:
#                 people_freq = known['people_frequency']
#         else:
#             area, zone, tier               = get_area_zone(lat, lon)
#             residence                      = 'Medium'
#             is_police, is_bar, people_freq = get_nearby_places(lat, lon)
#             matched_name                   = None
#
#         features = {
#             'Area':             area,
#             'Zone':             zone,
#             'Time':             time_of_day,
#             'People.Frequency': people_freq,
#             'Is.Police_Station':is_police,
#             'Is.Bar':           is_bar,
#             'Tier':             tier,
#             'Residence.Level':  residence,
#             'Day_of_Week':      day_of_week,
#             'Lighting':         lighting,
#         }
#         print(f"📊 Features: {features}")
#
#         # Encode and predict
#         df = pd.DataFrame([features])
#         for col in feature_columns:
#             if col in label_encoders:
#                 try:
#                     df[col] = label_encoders[col].transform([str(df[col].iloc[0])])[0]
#                 except:
#                     df[col] = 0
#         df = df[feature_columns]
#
#         pred_encoded  = model.predict(df)[0]
#         probabilities = model.predict_proba(df)[0]
#         prediction    = target_encoder.inverse_transform([pred_encoded])[0]
#         prob_index    = list(target_encoder.classes_).index(prediction)
#         confidence    = probabilities[prob_index]
#
#         print(f"✅ Result: {prediction} ({confidence:.2%})")
#
#         return jsonify({
#             'status':        'success',
#             'prediction':    prediction,
#             'confidence':    round(float(confidence) * 100, 1),
#             'matched_place': matched_name,
#             'auto_features': {
#                 'time':             time_of_day,
#                 'day':              day_of_week,
#                 'lighting':         lighting,
#                 'police_nearby':    is_police,
#                 'bar_nearby':       is_bar,
#                 'people_frequency': people_freq,
#                 'area':             area,
#                 'zone':             zone,
#             }
#         })
#
#     except Exception as e:
#         print(f"❌ Error: {e}")
#         return jsonify({'status': 'error', 'message': str(e)}), 500


