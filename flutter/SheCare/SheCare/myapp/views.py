import random
import smtplib


from django.contrib import messages
from django.contrib.auth import authenticate, login, logout
from django.contrib.auth.models import Group


# Create your views here..
from django.shortcuts import render, redirect

from myapp.gemini import generate_gemini_response
from myapp.models import *
from datetime import datetime

def logout_view(request):
    logout(request)
    return  redirect('/myapp/login/')

def user_registration(request):
    name = request.POST['name']
    dob = request.POST['dob']
    gender = request.POST['gender']
    phone = request.POST['phone']
    email = request.POST['email']
    place = request.POST['place']
    post = request.POST['post']
    district = request.POST['district']
    state = request.POST['state']
    photo = request.POST['photo']
    identification_mark = request.POST['identification_mark']
    fathers_name = request.POST['fathers_name']
    mothers_name= request.POST['mothers_name']
    blood_group= request.POST['blood_group']
    password= request.POST['password']
    confirmp= request.POST['confirmp']

    v = User()

    import base64
    d=datetime.now().strftime('%Y%m%d-%H%M%S')
    g=base64.b64decode(photo)
    fh=open('C:\\Users\\VIPIN KARMA\\Downloads\\Telegram Desktop\\shecare30-12-24\\shecare30-12-24\\SheCare (2)\\SheCare\\media\\'+ d +".jpg","wb")
    path='/media/'+ d + '.jpg'
    fh.write(g)
    fh.close()


    if User.objects.filter(username=email).exists():
        return JsonResponse({'message':'Email already registered'})
    u = User.objects.create_user(username=email, password=password)
    u.groups.add(Group.objects.get(name='user'))
    v = User_details()
    v.name = name
    v.dob = dob
    v.gender = gender
    v.phone = phone
    v.email = email
    v.place = place
    v.post = post
    v.district = district
    v.state = state

    v.photo = path
    v.identification_mark = identification_mark
    v.fathers_name = fathers_name
    v.mothers_name = mothers_name
    v.blood_group = blood_group
    v.LOGIN_id = u.id
    v.save()
    return JsonResponse({"status": 'ok'})






def user_view_profile(request):
    lid = request.POST['lid']
    print(lid)

    v=User.objects.get(LOGIN_id=lid)
    return JsonResponse({"status": 'ok',
                         'Name':v.name,
                         'Dob':v.dob,
                         'Gender':v.gender,
                         'Phone':v.phone,
                         'Email':v.email,
                         'Place':v.place,
                         'Post':v.post,
                         'District':v.district,
                         'State':v.state,
                         'Photo':v.photo,
                         'Identification Mark':v.identificationmark,
                         'Fathers Name':v.fathersname,
                         'Mothers Name':v.mothername,
                         'Blood Group':v.bloodgroup,
                         })
def user_edit_profile(request):
    name = request.POST['name']
    dob = request.POST['dob']
    gender = request.POST['gender']
    phone = request.POST['phone']
    email = request.POST['email']
    place = request.POST['place']
    post = request.POST['post']
    district = request.POST['district']
    state = request.POST['state']
    photo = request.POST['photo']
    identification_mark = request.POST['identification_mark']
    fathers_name = request.POST['fathers_name']
    mothers_name= request.POST['mothers_name']
    blood_group= request.POST['blood_group']
    lid = request.POST['lid']

    if len(photo)>0:

        import base64
        d=datetime.now().strftime('%Y%m%d-%H%M%S')
        g=base64.b64decode(photo)
        fh=open('C:\\Users\\VIPIN KARMA\\Downloads\\Telegram Desktop\\shecare30-12-24\\shecare30-12-24\\SheCare (2)\\SheCare\\media\\'+ d +".jpg","wb")
        path='/media/'+ d + '.jpg'
        fh.write(g)
        fh.close()

        # status = request.POST['status']


        v=User.objects.get(LOGIN__id=lid)
        v.name = name
        v.dob = dob
        v.gender = gender
        v.phone = phone
        v.email = email
        v.place = place
        v.post = post
        v.district = district
        v.state = state
        v.photo = path
        v.identification_mark = identification_mark
        v.fathersname = fathers_name
        v.mothername = mothers_name
        v.bloodgroup = blood_group
        v.LOGIN_id = lid
        v.save()
    v = User.objects.get(LOGIN__id=lid)
    v.name = name
    v.dob = dob
    v.gender = gender
    v.phone = phone
    v.email = email
    v.place = place
    v.post = post
    v.district = district
    v.state = state
    v.identification_mark = identification_mark
    v.fathersname = fathers_name
    v.mothername = mothers_name
    v.bloodgroup = blood_group
    v.LOGIN_id = lid
    v.save()
    return JsonResponse({"status": 'ok'})




def user_add_emergency_number(request):
    number = request.POST['number']
    name = request.POST['name']
    relation = request.POST['relation']
    lid = request.POST['lid']

    v = EmergnecyNumber()
    v.number = number
    v.name = name
    v.relation = relation
    v.USER=User_details.objects.get(LOGIN_id=lid)
    v.save()
    return JsonResponse({"status": 'ok'})

def user_view_emergency_number(request):
    lid=request.POST['lid']
    res = EmergnecyNumber.objects.filter(USER__LOGIN=lid)
    l = []
    for i in res :
        l.append({'id': i.id, 'name': i.name,
                  'number': i.number, 'relation': i.relation,
                  })


    return JsonResponse({"status": 'ok','data':l})



def user_edit_emergency_number(request):
    number = request.POST['number']
    name = request.POST['name']
    relation = request.POST['relation']
    id = request.POST['id']

    v = EmergnecyNumber.objects.get(id=id)
    v.number = number
    v.name = name
    v.relation = relation
    v.save()
    return JsonResponse({"status": 'ok'})

def delete_emergency_number(request):
    id = request.POST['id']
    EmergnecyNumber.objects.filter(id=id).delete()
    return JsonResponse({"status": 'ok'})



def pinkpolice_login(request):
    username=request.POST['username']
    password=request.POST['password']
    user = authenticate(username=username,password=password)
    if user is not None:
        login(request,user)
        if user.groups.filter(name='user').exists():
            e = EmergnecyNumber.objects.filter(USER_id__LOGIN_id=user.id).values()
            return JsonResponse({"status": 'ok', "lid": user.id, "type": "user", 'phone': list(e)})
        elif user.groups.filter(name='pinkpolice').exists():
            return JsonResponse({"status": 'ok', "lid": user.id, "type": "pinkpolice"})
        else:
            return JsonResponse({"status":'no'})
    else:
        return JsonResponse({"status":'no'})





def updatelocation(request):
    print(request.POST)
    lat = request.POST['lat']
    lon = request.POST['lon']
    did = request.POST['lid']
    ob = Location.objects.filter(LOGIN_id=did)

    if ob.exists():
        ob = Location.objects.filter(LOGIN_id=did)[0]
        ob.latitude = lat
        ob.longitude = lon
        ob.save()
        print("===============")
        return JsonResponse({"status": "ok"})

    else:
        ob = Location()
        ob.latitude = lat
        ob.longitude = lon
        ob.LOGIN_id=did
        ob.save()
        print("+++++++++++++++++")
        return JsonResponse({"status": "ok"})













from django.core.files.storage import FileSystemStorage
import os, subprocess
import numpy as np
import librosa
from tensorflow.keras.models import load_model

# Observed emotions
observed_emotions = ['neutral', 'calm', 'happy', 'sad', 'angry', 'fearful', 'disgust', 'surprised']


def extract_feature(file_name, mfcc=True, chroma=True, mel=True, max_pad_length=130):
    # Load audio
    X, sample_rate = librosa.load(file_name, sr=None, mono=True)
    result = np.array([])

    if mel:
        mel_spec = librosa.feature.melspectrogram(y=X, sr=sample_rate, n_mels=40, fmax=8000)
        mel_spec = librosa.power_to_db(mel_spec, ref=np.max)
        if mel_spec.shape[1] < max_pad_length:
            pad_width = max_pad_length - mel_spec.shape[1]
            mel_spec = np.pad(mel_spec, ((0, 0), (0, pad_width)), mode='constant')
        elif mel_spec.shape[1] > max_pad_length:
            mel_spec = mel_spec[:, :max_pad_length]
        result = mel_spec.T

    return result


def predict_emotion(file_path, model):
    feature = extract_feature(file_path, mel=True)
    feature = np.expand_dims(feature, axis=-1)  # channel dimension
    feature = np.expand_dims(feature, axis=0)  # batch dimension
    prediction = model.predict(feature)
    predicted_label = np.argmax(prediction, axis=1)[0]
    return observed_emotions[predicted_label]


def recordings(request):
    if request.method != "POST" or not request.FILES.get("audio"):
        return JsonResponse({"error": "No audio data received"}, status=400)

    audio_file = request.FILES["audio"]
    fs = FileSystemStorage(location='audio_recordings')

    # Fix datetime usage
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    original_filename = f"recording_{timestamp}_{audio_file.name}"
    saved_filename = fs.save(original_filename, audio_file)
    original_path = fs.path(saved_filename)

    print(f"Audio file saved at: {original_path}")

    # Convert to WAV using ffmpeg
    wav_filename = f"recording_{timestamp}.wav"
    wav_path = fs.path(wav_filename)
    try:
        subprocess.run(
            ["ffmpeg", "-y", "-i", original_path, "-ar", "22050", "-ac", "1", wav_path],
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE
        )
        print(f"✅ Converted to WAV: {wav_path}")
    except subprocess.CalledProcessError as e:
        print(f"❌ FFmpeg conversion error: {e.stderr.decode()}")
        return JsonResponse({"error": "Audio conversion failed"}, status=500)
    finally:
        # Delete original file to save space
        if os.path.exists(original_path):
            os.remove(original_path)

    # Load model and predict emotion
    try:
        from django.conf import settings
        model_path = os.path.join(settings.BASE_DIR, 'myapp', 'emotion_recognition_model.h5')
        model = load_model(model_path)
        predicted_emotion = predict_emotion(wav_path, model)
        print(f"🎯 Predicted emotion: {predicted_emotion}")

        # Check if emotion is fearful or angry
        sos_triggered = predicted_emotion in ['fearful', 'angry']

        return JsonResponse({
            "prediction": predicted_emotion,
            "sos_triggered": sos_triggered,  # Add this flag
            "sos_reason": f"Voice emotion detected: {predicted_emotion}" if sos_triggered else "No dangerous emotion detected",
            "file_saved_at": wav_path
        })
    except Exception as e:
        print(f"❌ Model processing failed: {e}")
        return JsonResponse({"error": "Model processing failed"}, status=500)


# import json
# import numpy as np
# from django.http import JsonResponse
# from django.views.decorators.csrf import csrf_exempt
# from tensorflow.keras.models import load_model
# import time
# from collections import deque
#
# # Load your trained model (but we'll use heuristic as fallback)
# try:
#     model = load_model(
#         r"C:\Users\VIPIN KARMA\Downloads\Telegram Desktop\shecare30-12-24\shecare30-12-24\SheCare (2)\SheCare\myapp\phone_motion_cnn.h5")
#     model_loaded = True
# except:
#     model_loaded = False
#     print("Model failed to load, using heuristic detection only")
#
# labels = ["rest", "shake", "rapid_shake", "throw", "fall"]
#
# # Store motion history with timestamps
# motion_history = deque(maxlen=100)  # Store last 100 motions
# current_motion_start = None
# current_motion_type = None
#
#
# def heuristic_motion_detection(sample):
#     """
#     Rule-based motion detection based on your dataset patterns
#     """
#     ax, ay, az, gx, gy, gz = sample
#
#     # Calculate magnitude of acceleration and gyroscope
#     acc_magnitude = np.sqrt(ax ** 2 + ay ** 2 + az ** 2)
#     gyro_magnitude = np.sqrt(gx ** 2 + gy ** 2 + gz ** 2)
#
#     print(f"Acc magnitude: {acc_magnitude:.2f}, Gyro magnitude: {gyro_magnitude:.2f}")
#
#     # THROW: High acceleration with unusual Z-axis (not ~9.8)
#     if (abs(ax) > 2.5 or abs(ay) > 2.5) and (abs(az) < 5 or abs(az) > 15):
#         return "throw", 0.95
#
#     # FALL: Very low Z acceleration (free fall)
#     elif abs(az) < 2:
#         return "fall", 0.90
#
#     # RAPID_SHAKE: Very high gyroscope values
#     elif gyro_magnitude > 1.5:
#         return "rapid_shake", 0.85
#
#     # SHAKE: Moderate acceleration and gyroscope
#     elif (acc_magnitude > 12 or acc_magnitude < 8) and gyro_magnitude > 0.8:
#         return "shake", 0.80
#
#     # REST: Normal gravity with low movement
#     elif 8 < acc_magnitude < 12 and gyro_magnitude < 0.5:
#         return "rest", 0.90
#
#     else:
#         return "rest", 0.70
#
#
# def calculate_motion_timing():
#     """
#     Calculate start time, end time, and middle time for current motion
#     """
#     global current_motion_start, current_motion_type
#
#     current_time = time.time()
#
#     # If this is the start of a new motion (not rest)
#     if current_motion_type and current_motion_type != "rest":
#         if current_motion_start is None:
#             # Start of motion
#             current_motion_start = current_time
#             return {
#                 "start_time": current_time,
#                 "end_time": None,
#                 "middle_time": None,
#                 "duration": 0,
#                 "motion_type": current_motion_type
#             }
#         else:
#             # Motion continuing, update end time
#             duration = current_time - current_motion_start
#             middle_time = current_motion_start + (duration / 2)
#             return {
#                 "start_time": current_motion_start,
#                 "end_time": current_time,
#                 "middle_time": middle_time,
#                 "duration": duration,
#                 "motion_type": current_motion_type
#             }
#     else:
#         # Motion ended or rest state
#         if current_motion_start is not None:
#             # Motion just ended, calculate final timing
#             end_time = current_time
#             duration = end_time - current_motion_start
#             middle_time = current_motion_start + (duration / 2)
#
#             timing_info = {
#                 "start_time": current_motion_start,
#                 "end_time": end_time,
#                 "middle_time": middle_time,
#                 "duration": duration,
#                 "motion_type": current_motion_type
#             }
#
#             # Store in history
#             motion_history.append(timing_info)
#
#             # Reset for next motion
#             current_motion_start = None
#             current_motion_type = None
#
#             return timing_info
#
#         return {
#             "start_time": None,
#             "end_time": None,
#             "middle_time": None,
#             "duration": 0,
#             "motion_type": "rest"
#         }
#
#
# @csrf_exempt
# def predict_motion(request):
#     if request.method == "POST":
#         try:
#             data = json.loads(request.body)
#             sensor_data = data.get("data", [])
#             timestamp = data.get("timestamp", time.time())
#
#             if len(sensor_data) == 0:
#                 return JsonResponse({"error": "No sensor data received"})
#
#             # Use the most recent sample
#             latest_sample = sensor_data[-1]
#
#             # Extract values
#             ordered_data = [
#                 latest_sample.get("ax", 0),
#                 latest_sample.get("ay", 0),
#                 latest_sample.get("az", 0),
#                 latest_sample.get("gx", 0),
#                 latest_sample.get("gy", 0),
#                 latest_sample.get("gz", 0),
#             ]
#
#             print(f"Raw sensor data: {ordered_data}")
#
#             # Use heuristic detection (since model is broken)
#             action, confidence = heuristic_motion_detection(ordered_data)
#
#             # Update current motion type for timing calculation
#             global current_motion_type
#             current_motion_type = action
#
#             # Calculate motion timing
#             timing_info = calculate_motion_timing()
#
#             print(f"Heuristic detection: {action} (confidence: {confidence:.2f})")
#
#             # Return ONLY heuristic detection result
#             return JsonResponse({
#                 "heuristic_detection": action,
#                 "confidence": confidence,
#                 "motion_type": action
#             })
#
#         except Exception as e:
#             print(f"Error in prediction: {str(e)}")
#             return JsonResponse({"error": str(e)})
#
#     return JsonResponse({"error": "Invalid request method. Use POST."})
# @csrf_exempt
# def get_motion_history(request):
#     """
#     Endpoint to get motion history with start, middle, and end times
#     """
#     if request.method == "GET":
#         history_list = list(motion_history)
#
#         # Format timestamps for readability
#         formatted_history = []
#         for motion in history_list:
#             formatted_motion = {
#                 "motion_type": motion["motion_type"],
#                 "start_time": motion["start_time"],
#                 "end_time": motion["end_time"],
#                 "middle_time": motion["middle_time"],
#                 "duration": motion["duration"],
#                 "formatted_start": time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(motion["start_time"])) if motion[
#                     "start_time"] else None,
#                 "formatted_middle": time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(motion["middle_time"])) if motion[
#                     "middle_time"] else None,
#                 "formatted_end": time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(motion["end_time"])) if motion[
#                     "end_time"] else None
#             }
#             formatted_history.append(formatted_motion)
#
#         return JsonResponse({
#             "motion_history": formatted_history,
#             "total_motions": len(formatted_history)
#         })
#
#     return JsonResponse({"error": "Invalid request method. Use GET."})
#
#
# @csrf_exempt
# def clear_motion_history(request):
#     """
#     Endpoint to clear motion history
#     """
#     if request.method == "POST":
#         motion_history.clear()
#         return JsonResponse({"message": "Motion history cleared"})
#
#     return JsonResponse({"error": "Invalid request method. Use POST."})



import json
import numpy as np
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from tensorflow.keras.models import load_model
import time
from collections import deque

# Load your trained model (but we'll use heuristic as fallback)
try:
    model = load_model(
        r"C:\Users\VIPIN KARMA\Downloads\Telegram Desktop\shecare30-12-24\shecare30-12-24\SheCare (2)\SheCare\myapp\phone_motion_cnn.h5")
    model_loaded = True
except:
    model_loaded = False
    print("Model failed to load, using heuristic detection only")

labels = ["rest", "shake", "rapid_shake", "throw", "fall"]

# Store motion history with timestamps
motion_history = deque(maxlen=100)
current_motion_start = None
current_motion_type = None
first_3sec_captured = False
three_second_mark = None
cooldown_until = None  # Track when to start detecting again


def heuristic_motion_detection(sample):
    """
    Rule-based motion detection based on your dataset patterns
    """
    ax, ay, az, gx, gy, gz = sample

    # Calculate magnitude of acceleration and gyroscope
    acc_magnitude = np.sqrt(ax ** 2 + ay ** 2 + az ** 2)
    gyro_magnitude = np.sqrt(gx ** 2 + gy ** 2 + gz ** 2)

    print(f"Acc magnitude: {acc_magnitude:.2f}, Gyro magnitude: {gyro_magnitude:.2f}")

    # THROW: High acceleration with unusual Z-axis (not ~9.8)
    if (abs(ax) > 2.5 or abs(ay) > 2.5) and (abs(az) < 5 or abs(az) > 15):
        return "throw", 0.95

    # FALL: Very low Z acceleration (free fall)
    elif abs(az) < 2:
        return "fall", 0.90

    # RAPID_SHAKE: Very high gyroscope values
    elif gyro_magnitude > 1.5:
        return "rapid_shake", 0.85

    # SHAKE: Moderate acceleration and gyroscope
    elif (acc_magnitude > 12 or acc_magnitude < 8) and gyro_magnitude > 0.8:
        return "shake", 0.80

    # REST: Normal gravity with low movement
    elif 8 < acc_magnitude < 12 and gyro_magnitude < 0.5:
        return "rest", 0.90

    else:
        return "rest", 0.70


def calculate_motion_timing():
    """
    Calculate start time, end time, and middle time for current motion
    Focus on first 3 seconds, then enter 5-second cooldown
    """
    global current_motion_start, current_motion_type, first_3sec_captured, three_second_mark, cooldown_until

    current_time = time.time()

    # Check if we're in cooldown period
    if cooldown_until and current_time < cooldown_until:
        remaining = cooldown_until - current_time
        if remaining > 0:
            print(f"⏸️  Cooldown: {remaining:.1f}s remaining...")
            return {
                "start_time": None,
                "end_time": None,
                "middle_time": None,
                "duration": 0,
                "motion_type": "rest",
                "first_3sec_completed": False,
                "in_cooldown": True,
                "cooldown_remaining": remaining
            }

    # Cooldown period over, reset
    if cooldown_until and current_time >= cooldown_until:
        print("✅ Cooldown period over - Ready for new movement detection")
        cooldown_until = None

    # If this is the start of a new motion (not rest) and not in cooldown
    if current_motion_type and current_motion_type != "rest" and cooldown_until is None:
        if current_motion_start is None:
            # Start of motion - reset flags
            current_motion_start = current_time
            first_3sec_captured = False
            three_second_mark = None
            print("🆕 NEW MOVEMENT STARTED - Tracking first 3 seconds...")
            return {
                "start_time": current_time,
                "end_time": None,
                "middle_time": None,
                "duration": 0,
                "motion_type": current_motion_type,
                "first_3sec_completed": False,
                "in_cooldown": False
            }
        else:
            # Motion continuing
            duration = current_time - current_motion_start

            # Check if we've reached 3 seconds
            if duration >= 3.0 and not first_3sec_captured:
                first_3sec_captured = True
                three_second_mark = current_time

                # Start 5-second cooldown
                cooldown_until = current_time + 5.0

                # Print first 3-second completion and cooldown start
                print("⏰" * 50)
                print(f"⏰ FIRST 3 SECONDS CAPTURED: {current_motion_type.upper()}")
                print(f"⏰ Start: {time.strftime('%H:%M:%S', time.localtime(current_motion_start))}")
                print(f"⏰ 3-Second Mark: {time.strftime('%H:%M:%S', time.localtime(three_second_mark))}")
                print(f"⏰ Starting 5-second cooldown...")
                print("⏰" * 50)

                # Store the 3-second motion event
                timing_info = {
                    "start_time": current_motion_start,
                    "end_time": three_second_mark,
                    "middle_time": current_motion_start + 1.5,  # Middle of first 3 seconds
                    "duration": 3.0,
                    "motion_type": current_motion_type,
                    "first_3sec_completed": True
                }
                motion_history.append(timing_info)

                # Reset current motion tracking
                current_motion_start = None
                current_motion_type = None

                return {
                    **timing_info,
                    "in_cooldown": True,
                    "cooldown_remaining": 5.0
                }

            # Still within first 3 seconds
            middle_time = current_motion_start + (duration / 2)
            return {
                "start_time": current_motion_start,
                "end_time": current_time,
                "middle_time": middle_time,
                "duration": duration,
                "motion_type": current_motion_type,
                "first_3sec_completed": False,
                "in_cooldown": False
            }
    else:
        # Motion ended or rest state
        if current_motion_start is not None and cooldown_until is None:
            # Motion ended before 3 seconds
            end_time = current_time
            duration = end_time - current_motion_start

            if not first_3sec_captured:
                # Start 5-second cooldown for short movements too
                cooldown_until = current_time + 5.0

                print("⚠️" * 50)
                print(f"⚠️ SHORT MOVEMENT: {current_motion_type.upper()} (Only {duration:.2f}s)")
                print(f"⚠️ Start: {time.strftime('%H:%M:%S', time.localtime(current_motion_start))}")
                print(f"⚠️ End: {time.strftime('%H:%M:%S', time.localtime(end_time))}")
                print(f"⚠️ Starting 5-second cooldown...")
                print("⚠️" * 50)

                timing_info = {
                    "start_time": current_motion_start,
                    "end_time": end_time,
                    "middle_time": current_motion_start + (duration / 2),
                    "duration": duration,
                    "motion_type": current_motion_type,
                    "first_3sec_completed": False
                }
                motion_history.append(timing_info)

            # Reset for next motion
            current_motion_start = None
            current_motion_type = None
            first_3sec_captured = False
            three_second_mark = None

            return {
                **timing_info,
                "in_cooldown": True,
                "cooldown_remaining": 5.0
            }

        return {
            "start_time": None,
            "end_time": None,
            "middle_time": None,
            "duration": 0,
            "motion_type": "rest",
            "first_3sec_completed": False,
            "in_cooldown": cooldown_until is not None,
            "cooldown_remaining": cooldown_until - current_time if cooldown_until else 0
        }


@csrf_exempt
@csrf_exempt
def predict_motion(request):
    if request.method == "POST":
        try:
            data = json.loads(request.body)
            sensor_data = data.get("data", [])
            timestamp = data.get("timestamp", time.time())

            if len(sensor_data) == 0:
                return JsonResponse({"error": "No sensor data received"})

            # Use the most recent sample
            latest_sample = sensor_data[-1]

            # Extract values
            ordered_data = [
                latest_sample.get("ax", 0),
                latest_sample.get("ay", 0),
                latest_sample.get("az", 0),
                latest_sample.get("gx", 0),
                latest_sample.get("gy", 0),
                latest_sample.get("gz", 0),
            ]

            # Use heuristic detection
            action, confidence = heuristic_motion_detection(ordered_data)

            # Print current detection to terminal (only if not in cooldown)
            global current_motion_start, first_3sec_captured, cooldown_until

            current_time = time.time()

            # If we're in cooldown, show status but don't process new movements
            if cooldown_until and current_time < cooldown_until:
                remaining = cooldown_until - current_time
                if remaining > 0 and remaining % 1 < 0.1:  # Show every second
                    print(f"⏸️  Cooldown: {remaining:.1f}s remaining - Movement detection paused")

            # If not in cooldown and we detect a new movement
            elif action != "rest" and cooldown_until is None:
                # If this is a new movement start
                if current_motion_start is None:
                    print("🚀" * 40)
                    print(f"🚀 NEW MOVEMENT DETECTED: {action.upper()}")
                    print(f"🚀 Confidence: {confidence:.2f}")
                    print(f"🚀 Start Time: {time.strftime('%H:%M:%S', time.localtime(current_time))}")
                    print(f"🚀 Tracking first 3 seconds...")
                    print("🚀" * 40)

                # If we're in the first 3 seconds, show progress
                elif not first_3sec_captured:
                    elapsed = current_time - current_motion_start
                    if elapsed <= 3.0:
                        print(f"⏳ Movement progress: {elapsed:.1f}s / 3.0s - {action.upper()}")

            # Update current motion type for timing calculation (only if not in cooldown)
            global current_motion_type
            if cooldown_until is None:
                current_motion_type = action
            else:
                # Force rest during cooldown
                current_motion_type = "rest"

            # Calculate motion timing (respects cooldown)
            timing_info = calculate_motion_timing()

            # Get the last captured motion (if any)
            last_captured_motion = None
            if motion_history:
                last_captured_motion = {
                    "motion_type": motion_history[-1]["motion_type"],
                    "start_time": motion_history[-1]["start_time"],
                    "end_time": motion_history[-1]["end_time"],
                    "duration": motion_history[-1]["duration"],
                    "first_3sec_completed": motion_history[-1].get("first_3sec_completed", False),
                    "formatted_start": time.strftime('%H:%M:%S', time.localtime(motion_history[-1]["start_time"])) if motion_history[-1]["start_time"] else None,
                    "formatted_end": time.strftime('%H:%M:%S', time.localtime(motion_history[-1]["end_time"])) if motion_history[-1]["end_time"] else None
                }

            response_data = {
                "current_detection": {
                    "action": action,
                    "confidence": confidence,
                    "class_index": labels.index(action),
                    "in_cooldown": timing_info.get('in_cooldown', False),
                    "cooldown_remaining": timing_info.get('cooldown_remaining', 0),
                },
                "last_captured_motion": last_captured_motion,
                "sensor_magnitude": {
                    "acceleration": float(np.sqrt(ordered_data[0] ** 2 + ordered_data[1] ** 2 + ordered_data[2] ** 2)),
                    "gyroscope": float(np.sqrt(ordered_data[3] ** 2 + ordered_data[4] ** 2 + ordered_data[5] ** 2))
                }
            }

            return JsonResponse(response_data)

        except Exception as e:
            print(f"❌ Error in prediction: {str(e)}")
            return JsonResponse({"error": str(e)})

    return JsonResponse({"error": "Invalid request method. Use POST."})


@csrf_exempt
def get_motion_history(request):
    """
    Endpoint to get motion history from memory (focus on 3-second captures)
    """
    if request.method == "GET":
        history_list = list(motion_history)

        # Format timestamps for readability
        formatted_history = []
        for motion in history_list:
            formatted_motion = {
                "motion_type": motion["motion_type"],
                "start_time": motion["start_time"],
                "end_time": motion["end_time"],
                "middle_time": motion["middle_time"],
                "duration": motion["duration"],
                "first_3sec_completed": motion.get("first_3sec_completed", False),
                "formatted_start": time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(motion["start_time"])) if motion[
                    "start_time"] else None,
                "formatted_end": time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(motion["end_time"])) if motion[
                    "end_time"] else None
            }
            formatted_history.append(formatted_motion)

        # Print history to terminal
        print("📜" * 50)
        print("📜 MOVEMENT HISTORY (with 5-second cooldowns):")
        print("📜" * 50)

        three_sec_movements = [m for m in formatted_history if m.get('first_3sec_completed', False)]
        short_movements = [m for m in formatted_history if not m.get('first_3sec_completed', False)]

        if three_sec_movements:
            print("✅ FULL 3-SECOND CAPTURES:")
            for i, motion in enumerate(three_sec_movements[-5:]):  # Show last 5
                print(f"   {i+1}. {motion['motion_type'].upper()} - {motion['formatted_start']}")

        if short_movements:
            print("⚠️  SHORT MOVEMENTS (<3s):")
            for i, motion in enumerate(short_movements[-3:]):  # Show last 3
                print(
                    f"   {i+1}. {motion['motion_type'].upper()} - {motion['duration']:.1f}s - {motion['formatted_start']}")

        return JsonResponse({
            "motion_history": formatted_history,
            "three_second_captures": three_sec_movements,
            "short_movements": short_movements,
            "total_motions": len(formatted_history)
        })

    return JsonResponse({"error": "Invalid request method. Use GET."})


@csrf_exempt
def clear_motion_history(request):
    """
    Endpoint to clear motion history from memory
    """
    if request.method == "POST":
        motion_history.clear()
        global cooldown_until
        cooldown_until = None
        print("🗑️ Motion history cleared from memory - Cooldown reset")
        return JsonResponse({"message": "Motion history cleared"})

    return JsonResponse({"error": "Invalid request method. Use POST."})





def login_get(request):
    return render(request,'login.html')

def login_post(request):
    uname=request.POST['textfield']
    password=request.POST['textfield2']
    u = authenticate(username= uname,password=password)
    if u is not None:
        login(request,u)
        if u.groups.filter(name='admin').exists():
            return redirect('/myapp/admin_main_home/')
        elif u.groups.filter(name='subadmin').exists():
            return redirect('/myapp/subadminhome/')
        else:
            return redirect('/myapp/login/')
    else:
        return redirect('/myapp/login/')



############################## ADMIN #########################
def admin_main_home(request):
    return render(request,'ADMIN/Admin_index.html')


### POLICE STATION
def view_police_station(request):
    res = PoliceStation.objects.all()
    return render(request, 'ADMIN/view police station.html', {"data": res})


def view_police_station_post(request):
    s = request.POST["textfield"]
    if not s:
        messages.error(request, "Please enter a search term")
        return redirect('/myapp/view_police_station/')
    res = PoliceStation.objects.filter(name__icontains=s)
    if not res:
        messages.warning(request, "No police stations found matching your search")
    return render(request, 'ADMIN/view police station.html', {"data": res})


def add_policestation(request):
    return render(request, 'ADMIN/add_police station.html')


def add_policestation_post(request):
    sname = request.POST['textfield']
    place = request.POST['textfield2']
    post = request.POST['textfield3']
    district = request.POST['select']
    state = request.POST['textfield5']
    since = request.POST['textfield6']
    phone = request.POST['textfield7']
    email = request.POST['textfield8']

    # Validation
    if User.objects.filter(username=email).exists():
        messages.error(request, "Email already exists in user accounts")
        return redirect('/myapp/add_policestation/')
    elif PoliceStation.objects.filter(email=email).exists():
        messages.error(request, "Email already exists in police stations")
        return redirect('/myapp/add_policestation/')
    elif PoliceStation.objects.filter(name=sname).exists():
        messages.error(request, "Police station already exists")
        return redirect('/myapp/add_policestation/')

    try:
        obj = PoliceStation()
        obj.name = sname
        obj.place = place
        obj.post = post
        obj.district = district
        obj.state = state
        obj.since = since
        obj.phone = phone
        obj.email = email
        obj.save()
        messages.success(request, "Police station added successfully")
        return redirect('/myapp/view_police_station/')
    except Exception as e:
        messages.error(request, f"Error adding police station: {str(e)}")
        return redirect('/myapp/add_policestation/')


def edit_policestation(request, id):
    try:
        res = PoliceStation.objects.get(id=id)
        return render(request, 'ADMIN/edit police station.html', {"data": res})
    except PoliceStation.DoesNotExist:
        messages.error(request, "Police station not found")
        return redirect('/myapp/view_police_station/')


def edit_policestation_post(request):
    sname = request.POST['textfield']
    place = request.POST['textfield2']
    post = request.POST['textfield3']
    district = request.POST['select']
    state = request.POST['textfield5']
    since = request.POST['textfield6']
    phone = request.POST['textfield7']
    email = request.POST['textfield8']
    id = request.POST['id']

    # Check if email already exists in user table except current id
    if User.objects.filter(username=email).exclude(id=id).exists():
        messages.error(request, "Email already exists in users")
        return redirect('/myapp/view_police_station/')

    # Check if email exists in PoliceStation except current record
    if PoliceStation.objects.filter(email=email).exclude(id=id).exists():
        messages.error(request, "Email already exists in police stations")
        return redirect('/myapp/view_police_station/')

    # Check if police station name already exists except current one
    if PoliceStation.objects.filter(name=sname).exclude(id=id).exists():
        messages.error(request, "Police station name already exists")
        return redirect('/myapp/view_police_station/')

    try:
        # Update
        obj = PoliceStation.objects.get(id=id)
        obj.name = sname
        obj.place = place
        obj.post = post
        obj.district = district
        obj.state = state
        obj.since = since
        obj.phone = phone
        obj.email = email
        obj.save()
        messages.success(request, "Police station updated successfully")
        return redirect('/myapp/view_police_station/')
    except Exception as e:
        messages.error(request, f"Error updating police station: {str(e)}")
        return redirect('/myapp/view_police_station/')

from django.http import JsonResponse

def delete_police_station(request, id):
    try:
        PoliceStation.objects.filter(id=id).delete()

        if request.headers.get("x-requested-with") == "XMLHttpRequest":
            return JsonResponse({"status": "ok", "message": "Deleted successfully"})

        messages.success(request, "Police station deleted successfully")
        return redirect('/myapp/view_police_station/')

    except Exception as e:
        if request.headers.get("x-requested-with") == "XMLHttpRequest":
            return JsonResponse({"status": "error", "message": str(e)})

        messages.error(request, f"Error deleting police station: {str(e)}")
        return redirect('/myapp/view_police_station/')


### SUB ADMIN
def add_subadmin(request):
    return render(request, 'ADMIN/subadmin add.html')


def add_subadmin_post(request):
    name = request.POST['textfield']
    gender = request.POST['RadioGroup1']
    email = request.POST['textfield2']
    phone = request.POST['textfield3']
    photo = request.FILES['fileField']

    # VALIDATIONS
    if User.objects.filter(username=email).exists():
        messages.error(request, 'Email already exists in User table')
        return redirect('/myapp/add_subadmin')

    if SubAdmin.objects.filter(email=email).exists():
        messages.error(request, 'Email already exists as SubAdmin')
        return redirect('/myapp/add_subadmin')

    try:
        # FILE UPLOAD
        fs = FileSystemStorage()
        filename = datetime.now().strftime('%Y%m%d-%H%M%S') + ".jpg"
        fs.save(filename, photo)
        path = fs.url(filename)

        # GENERATE PASSWORD
        pwd = random.randint(10000, 99999)

        # SEND EMAIL
        server = smtplib.SMTP('smtp.gmail.com', 587)
        server.starttls()
        server.login("leagaladvisorteam@gmail.com", "eugnxtyylwtqwlav")

        subject = "Sub Admin Registration - Login Credentials"
        body = f"""
Dear {name},

You have been registered as a Sub Admin.

Your Login Details:
Username: {email}
Password: {pwd}

Please change your password after your first login.
"""

        message = f"Subject: {subject}\n\n{body}"
        server.sendmail("leagaladvisorteam@gmail.com", email, message)
        server.quit()

        # CREATE USER LOGIN
        u = User.objects.create_user(username=email, password=str(pwd))
        u.groups.add(Group.objects.get(name='subadmin'))
        u.save()

        # SAVE SUBADMIN
        obj = SubAdmin()
        obj.name = name
        obj.gender = gender
        obj.email = email
        obj.phone = phone
        obj.photo = path
        obj.LOGIN = u
        obj.save()

        messages.success(request, "Sub-admin added successfully and credentials sent via email")
        return redirect('/myapp/view_subadmin/')

    except Exception as e:
        messages.error(request, f"Error adding sub-admin: {str(e)}")
        return redirect('/myapp/add_subadmin')


def view_subadmin(request):
    res = SubAdmin.objects.all()
    return render(request, 'ADMIN/subadmin view.html', {"data": res})


def view_subadmin_post(request):
    search = request.POST["textfield"]
    if not search:
        messages.error(request, "Please enter a search term")
        return redirect('/myapp/view_subadmin/')
    res = SubAdmin.objects.filter(name__icontains=search)
    if not res:
        messages.warning(request, "No sub-admins found matching your search")
    return render(request, 'ADMIN/subadmin view.html', {"data": res})


def edit_subadmin(request, id):
    try:
        res = SubAdmin.objects.get(LOGIN_id=id)
        return render(request, 'ADMIN/subadmin edit.html', {"data": res})
    except SubAdmin.DoesNotExist:
        messages.error(request, "Sub-admin not found")
        return redirect('/myapp/view_subadmin/')


def edit_subadmin_post(request):
    name = request.POST['textfield']
    gender = request.POST['RadioGroup1']
    email = request.POST['textfield2']
    phone = request.POST['textfield3']
    id = request.POST['id']

    # Check duplicate email in User table
    if User.objects.filter(username=email).exclude(id=id).exists():
        messages.error(request, "Email already exists in main User accounts")
        return redirect('/myapp/edit_subadmin/' + id)

    # Check duplicate email inside SubAdmin table
    if SubAdmin.objects.filter(email=email).exclude(LOGIN_id=id).exists():
        messages.error(request, "Email already exists in SubAdmin")
        return redirect('/myapp/edit_subadmin/' + id)

    try:
        obj = SubAdmin.objects.get(LOGIN_id=id)

        if 'fileField' in request.FILES:
            photo = request.FILES['fileField']
            if photo != "":
                fs = FileSystemStorage()
                date = datetime.now().strftime('%Y%m%d%H%M%S') + ".jpg"
                fs.save(date, photo)
                path = fs.url(date)
                obj.photo = path

        obj.name = name
        obj.gender = gender
        obj.email = email
        obj.phone = phone
        obj.save()

        messages.success(request, "Sub-admin updated successfully")
        return redirect('/myapp/view_subadmin/')
    except Exception as e:
        messages.error(request, f"Error updating sub-admin: {str(e)}")
        return redirect('/myapp/edit_subadmin/' + id)


def deleteSubAdmin(request, id):
    try:
        s= SubAdmin.objects.get(id=id)
        User.objects.get(id=s.LOGIN_id).delete()
        s.delete()

        messages.success(request, "Sub-admin deleted successfully")
    except Exception as e:
        messages.error(request, f"Error deleting sub-admin: {str(e)}")
    return redirect('/myapp/view_subadmin/')


###### PINK POLICE
def add_pinkpolice(request):
    res = PoliceStation.objects.all()
    return render(request, 'ADMIN/Add pinkpolice.html', {"data": res})


def add_pinkpolice_post(request):
    vno = request.POST['textfield']
    oname = request.POST['textfield2']
    place = request.POST['textfield3']
    post = request.POST['textfield4']
    district = request.POST['textfield5']
    state = request.POST['textfield6']
    email = request.POST['textfield7']
    phoneno = request.POST['textfield8']
    gender = request.POST['RadioGroup1']
    dob = request.POST['textfield9']
    policestation = request.POST['policestation']

    # 🔍 Validate duplicate email
    if User.objects.filter(username=email).exists():
        messages.error(request, "Email already exists in User accounts")
        return redirect('/myapp/add_pinkpolice/')

    if PinkPolice.objects.filter(email=email).exists():
        messages.error(request, "Email already exists in Pink Police")
        return redirect('/myapp/add_pinkpolice/')

    try:
        # GENERATE PASSWORD
        pwd = random.randint(10000, 99999)

        # SEND EMAIL
        server = smtplib.SMTP('smtp.gmail.com', 587)
        server.starttls()
        server.login("leagaladvisorteam@gmail.com", "eugnxtyylwtqwlav")

        subject = "Pink Police Registration - Login Credentials"
        body = f"""
Dear {oname},

You have been registered as a Pink Police Officer.

Your Login Details:
Username: {email}
Password: {pwd}

Please change your password after your first login.
"""

        message = f"Subject: {subject}\n\n{body}"
        server.sendmail("leagaladvisorteam@gmail.com", email, message)
        server.quit()

        # CREATE USER LOGIN
        u = User.objects.create_user(username=email, password=str(pwd))
        u.groups.add(Group.objects.get(name='pinkpolice'))
        u.save()

        # SAVE PINK POLICE DATA
        obj = PinkPolice()
        obj.vechileno = vno
        obj.officername = oname
        obj.place = place
        obj.post = post
        obj.district = district
        obj.state = state
        obj.email = email
        obj.phone = phoneno
        obj.gender = gender
        obj.dob = dob
        obj.POLICESTATION_id = policestation
        obj.LOGIN = u
        obj.save()

        messages.success(request, "Pink police officer added successfully and credentials sent via email")
        return redirect('/myapp/view_pink_police/')

    except Exception as e:
        messages.error(request, f"Error adding pink police officer: {str(e)}")
        return redirect('/myapp/add_pinkpolice/')


def view_pink_police(request):
    res = PinkPolice.objects.all()
    return render(request, 'ADMIN/view pinkpolice.html', {"data": res})


def edit_pinkpolice(request, id):
    try:
        res = PinkPolice.objects.get(id=id)
        a = PoliceStation.objects.all()
        return render(request, 'ADMIN/Edit pink police.html', {"data": res, 'data1': a})
    except PinkPolice.DoesNotExist:
        messages.error(request, "Pink police officer not found")
        return redirect('/myapp/view_pink_police/')


def edit_pinkpolice_post(request):
    vno = request.POST['textfield']
    oname = request.POST['textfield2']
    place = request.POST['textfield3']
    post = request.POST['textfield4']
    district = request.POST['textfield4']
    state = request.POST['textfield6']
    email = request.POST['textfield7']
    phoneno = request.POST['textfield8']
    gender = request.POST['RadioGroup1']
    dob = request.POST['textfield9']
    policestation = request.POST['textfield10']
    id = request.POST['id']

    try:
        obj = PinkPolice.objects.get(id=id)
        obj.vechileno = vno
        obj.officername = oname
        obj.place = place
        obj.post = post
        obj.district = district
        obj.state = state
        obj.email = email
        obj.phone = phoneno
        obj.gender = gender
        obj.dob = dob
        obj.POLICESTATION_id = policestation
        obj.save()
        messages.success(request, "Pink police officer updated successfully")
        return redirect('/myapp/view_pink_police/')
    except Exception as e:
        messages.error(request, f"Error updating pink police officer: {str(e)}")
        return redirect('/myapp/edit_pinkpolice/' + id)


def delete_pinkpolice(request, id):
    try:
        p=PinkPolice.objects.get(id=id)
        User.objects.get(id=p.LOGIN_id).delete()
        p.delete()
        messages.success(request, "Pink police officer deleted successfully")
    except Exception as e:
        messages.error(request, f"Error deleting pink police officer: {str(e)}")
    return redirect('/myapp/view_pink_police/')


def search_pinkpolice(request):
    search = request.POST['search']
    if not search:
        messages.error(request, "Please enter a search term")
        return redirect('/myapp/view_pink_police/')
    p = PinkPolice.objects.filter(officername__icontains=search)
    if not p:
        messages.warning(request, "No pink police officers found matching your search")
    return render(request, 'ADMIN/view pinkpolice.html', {"data": p})


#### NOTIFICATION
def send_notification(request):
    return render(request, 'ADMIN/Send notification.html')


def send_notification_post(request):
    notification = request.POST['textfield']
    if not notification:
        messages.error(request, "Please enter notification description")
        return redirect('/myapp/send_notification/')
    try:
        obj = Notification()
        obj.description = notification
        obj.date = datetime.now()
        obj.save()
        messages.success(request, "Notification sent successfully")
    except Exception as e:
        messages.error(request, f"Error sending notification: {str(e)}")
    return redirect('/myapp/send_notification/')


def view_notification(request):
    res = Notification.objects.all()
    return render(request, 'ADMIN/view notification.html', {"data": res})


def deleteNotification(request, id):
    try:
        Notification.objects.filter(id=id).delete()
        messages.success(request, "Notification deleted successfully")
    except Exception as e:
        messages.error(request, f"Error deleting notification: {str(e)}")
    return redirect('/myapp/admin_view_notification/')


def edit_notification(request, id):
    try:
        res = Notification.objects.get(id=id)
        return render(request, 'ADMIN/edit notification.html', {"data": res})
    except Notification.DoesNotExist:
        messages.error(request, "Notification not found")
        return redirect('/myapp/admin_view_notification/')


def edit_notification_post(request):
    notifications = request.POST['textfield']
    id = request.POST['id']

    if not notifications:
        messages.error(request, "Please enter notification description")
        return redirect('/myapp/edit_notification/' + id)

    try:
        Notification.objects.filter(id=id).update(description=notifications)
        messages.success(request, "Notification updated successfully")
    except Exception as e:
        messages.error(request, f"Error updating notification: {str(e)}")
    return redirect('/myapp/admin_view_notification/')


def admin_view_notification(request):
    res = Notification.objects.all()
    return render(request, 'ADMIN/view notification.html', {"data": res})


def admin_view_notification_post(request):
    fdate = request.POST['textfield']
    tdate = request.POST['textfield2']

    if not fdate or not tdate:
        messages.error(request, "Please select both from and to dates")
        return redirect('/myapp/admin_view_notification/')

    res = Notification.objects.filter(date__range=[fdate, tdate])
    if not res:
        messages.warning(request, "No notifications found in the selected date range")
    return render(request, 'ADMIN/view notification.html', {"data": res})


#### FEEDBACK
def view_publicfeedback(request):
    f = Feedback.objects.all()
    return render(request, 'ADMIN/view public feedback.html', {'data': f})


def view_publicfeedback_post(request):
    fdate = request.POST['textfield']
    tdate = request.POST['textfield2']

    if not fdate or not tdate:
        messages.error(request, "Please select both from and to dates")
        return redirect('/myapp/view_publicfeedback/')

    f = Feedback.objects.filter(date__range=[fdate, tdate])
    if not f:
        messages.warning(request, "No feedback found in the selected date range")
    return render(request, 'ADMIN/view public feedback.html', {'data': f})


#### USERS
def view_reg_users(request):
    res = User_details.objects.all()
    return render(request, 'ADMIN/registered users.html', {"data": res})


def view_reg_users_post(request):
    search = request.POST['textfield']
    if not search:
        messages.error(request, "Please enter a search term")
        return redirect('/myapp/view_reg_users/')
    res = User_details.objects.filter(name__icontains=search)
    if not res:
        messages.warning(request, "No users found matching your search")
    return render(request, 'ADMIN/registered users.html', {"data": res})


###################### SUBADMIN ##################
def subadminhome(request):
    return render(request, 'SUBADMIN/Admin_index.html')


### SAFEPOINT
def add_safepoint(request):
    return render(request, 'SUBADMIN/Add safepoint.html')


def add_safepoint_post(request):
    place = request.POST['textfield']
    Latitude = request.POST['textfield2']
    Longitude = request.POST['textfield3']
    landmark = request.POST['textfield4']

    if not all([place, Latitude, Longitude]):
        messages.error(request, "Please fill all required fields")
        return redirect('/myapp/add_safepoint/')

    try:
        sobj = SafePoint()
        sobj.place = place
        sobj.latitude = Latitude
        sobj.longitude = Longitude
        sobj.landmark = landmark
        sobj.save()
        messages.success(request, "Safepoint added successfully")
    except Exception as e:
        messages.error(request, f"Error adding safepoint: {str(e)}")
    return redirect('/myapp/add_safepoint/')


def view_safepoint(request):
    q = SafePoint.objects.all()
    return render(request, 'SUBADMIN/view safepoint.html', {"data": q})


def edit_safepoint(request, id):
    try:
        d = SafePoint.objects.get(id=id)
        return render(request, 'SUBADMIN/edit safepoint.html', {"data": d})
    except SafePoint.DoesNotExist:
        messages.error(request, "Safepoint not found")
        return redirect('/myapp/view_safepoint/')


def edit_safepoint_post(request):
    place = request.POST['textfield']
    Latitude = request.POST['textfield2']
    Longitude = request.POST['textfield3']
    landmark = request.POST['textfield4']
    id = request.POST['id']

    if not all([place, Latitude, Longitude]):
        messages.error(request, "Please fill all required fields")
        return redirect('/myapp/edit_safepoint/' + id)

    try:
        sobj = SafePoint.objects.get(id=id)
        sobj.place = place
        sobj.latitude = Latitude
        sobj.longitude = Longitude
        sobj.landmark = landmark
        sobj.save()
        messages.success(request, "Safepoint updated successfully")
        return redirect('/myapp/view_safepoint/')
    except Exception as e:
        messages.error(request, f"Error updating safepoint: {str(e)}")
        return redirect('/myapp/edit_safepoint/' + id)


def delete_safepoint(request, id):
    try:
        d = SafePoint.objects.get(id=id).delete()
        messages.success(request, "Safepoint deleted successfully")
    except Exception as e:
        messages.error(request, f"Error deleting safepoint: {str(e)}")
    return redirect('/myapp/view_safepoint/')


#### DANGEROUS SPOT
def view_dangerous_spot_sub(request):
    # Fetch only pending dangerous spots
    pending_spots = DangerousSpot.objects.filter(status='pending')

    if not pending_spots:
        messages.info(request, "No pending dangerous spots")
        return render(request, 'SUBADMIN/View dangerous spot.html', {'data': []})

    result = []

    for spot in pending_spots:
        login_user = spot.LOGIN  # FK user

        # Check if user is Pink Police
        is_pink_police = login_user.groups.filter(name="pinkpolice").exists()

        if is_pink_police:
            # Get officer name
            try:
                officer = PinkPolice.objects.get(LOGIN=login_user)
                name = officer.officername
            except PinkPolice.DoesNotExist:
                name = "Unknown Officer"
        else:
            # Normal user → fetch from User_details
            try:
                user_det = User_details.objects.get(LOGIN=login_user)
                name = user_det.name
            except User_details.DoesNotExist:
                name = "Unknown User"

        result.append({
            'id': spot.id,
            'place': spot.place,
            'photo': spot.photo,
            'date': spot.date,
            'longitude': spot.longitude,
            'latitude': spot.latitude,
            'status': spot.status,
            'name': name,
        })

    return render(request, 'SUBADMIN/View dangerous spot.html', {'data': result})


def view_dangerous_spot(request):
    search=request.POST['search']
    v=DangerousSpot.objects.filter(status='approved',place__icontains=search).order_by('-date')
    l=[]
    for i in v:
        l.append({'id':i.id,
                  'place':i.place,
                  'date':i.date,
                  'latitude':i.latitude,
                  'longitude':i.longitude,
                  'status':i.status,
                  'photo':i.photo})
    return JsonResponse({"status": 'ok','data':l})

def view_dangerous_spot_post(request):
    fdate = request.POST['textfield']
    tdate = request.POST['textfield2']

    if not fdate or not tdate:
        messages.error(request, "Please select both from and to dates")
        return redirect('/myapp/view_dangerous_spot_sub/')

    t = DangerousSpot.objects.filter(date__range=[fdate, tdate], status='pending')
    if not t:
        messages.warning(request, "No pending dangerous spots found in the selected date range")
    l = []
    for i in t:
        n = User.objects.get(LOGIN_id=i.LOGIN.id)
        l.append({'id': i.id, 'place': i.place, 'photo': i.photo, 'date': i.date, 'longitude': i.longitude,
                  'latitude': i.latitude, 'status': i.status, 'name': n.name})

    return render(request, 'SUBADMIN/View dangerous spot.html', {'data': l})


def approve_dangerous_spot(request, id):
    try:
        DangerousSpot.objects.filter(id=id).update(status='approved')
        messages.success(request, "Dangerous spot approved successfully")
    except Exception as e:
        messages.error(request, f"Error approving dangerous spot: {str(e)}")
    return redirect('/myapp/view_approved_dangerous_spot/')


def reject_dangerous_spot(request, id):
    try:
        DangerousSpot.objects.filter(id=id).update(status='rejected')
        messages.success(request, "Dangerous spot rejected successfully")
    except Exception as e:
        messages.error(request, f"Error rejecting dangerous spot: {str(e)}")
    return redirect('/myapp/view_rejected_dangerous_spot/')

def get_user_name(user):
    # Check if user is PinkPolice
    if user.groups.filter(name="pinkpolice").exists():
        try:
            return PinkPolice.objects.get(LOGIN=user).officername
        except PinkPolice.DoesNotExist:
            return "Unknown Officer"
    else:
        # Normal user
        try:
            return User_details.objects.get(LOGIN=user).name
        except User_details.DoesNotExist:
            return "Unknown User"



def view_approved_dangerous_spot(request):
    spots = DangerousSpot.objects.filter(status='approved')

    if not spots:
        messages.info(request, "No approved dangerous spots")

    data = []
    for spot in spots:
        name = get_user_name(spot.LOGIN)

        data.append({
            'id': spot.id,
            'place': spot.place,
            'photo': spot.photo,
            'date': spot.date,
            'longitude': spot.longitude,
            'latitude': spot.latitude,
            'status': spot.status,
            'name': name
        })

    return render(request, 'SUBADMIN/View approved dangerous spot.html', {'data': data})


def view_approved_dangerous_spot_post(request):
    fdate = request.POST.get('textfield')
    tdate = request.POST.get('textfield2')

    if not fdate or not tdate:
        messages.error(request, "Please select both from and to dates")
        return redirect('/myapp/view_approved_dangerous_spot/')

    spots = DangerousSpot.objects.filter(
        date__range=[fdate, tdate],
        status='approved'
    )

    if not spots:
        messages.warning(request, "No approved dangerous spots in selected range")

    data = []
    for spot in spots:
        name = get_user_name(spot.LOGIN)

        data.append({
            'id': spot.id,
            'place': spot.place,
            'photo': spot.photo,
            'date': spot.date,
            'longitude': spot.longitude,
            'latitude': spot.latitude,
            'status': spot.status,
            'name': name
        })

    return render(request, 'SUBADMIN/View approved dangerous spot.html', {'data': data})



def view_rejected_dangerous_spot(request):
    spots = DangerousSpot.objects.filter(status='rejected')

    if not spots:
        messages.info(request, "No rejected dangerous spots")

    data = []
    for spot in spots:
        name = get_user_name(spot.LOGIN)

        data.append({
            'id': spot.id,
            'place': spot.place,
            'photo': spot.photo,
            'date': spot.date,
            'longitude': spot.longitude,
            'latitude': spot.latitude,
            'status': spot.status,
            'name': name
        })

    return render(request, 'SUBADMIN/View rejected dangerous spot.html', {'data': data})


def view_rejected_dangerous_spot_post(request):
    fdate = request.POST.get('textfield')
    tdate = request.POST.get('textfield2')

    if not fdate or not tdate:
        messages.error(request, "Please select both from and to dates")
        return redirect('/myapp/view_rejected_dangerous_spot/')

    spots = DangerousSpot.objects.filter(
        date__range=[fdate, tdate],
        status='rejected'
    )

    if not spots:
        messages.warning(request, "No rejected dangerous spots in selected date range")

    data = []
    for spot in spots:
        name = get_user_name(spot.LOGIN)

        data.append({
            'id': spot.id,
            'place': spot.place,
            'photo': spot.photo,
            'date': spot.date,
            'longitude': spot.longitude,
            'latitude': spot.latitude,
            'status': spot.status,
            'name': name
        })

    return render(request, 'SUBADMIN/View rejected dangerous spot.html', {'data': data})

#### FEEDBACK
def sub_view_public_feedback(request):
    f = Feedback.objects.all()
    return render(request, 'SUBADMIN/view public feedback.html', {'data': f})


def sub_view_publicfeedback_post(request):
    fdate = request.POST['textfield']
    tdate = request.POST['textfield2']

    if not fdate or not tdate:
        messages.error(request, "Please select both from and to dates")
        return redirect('/myapp/sub_view_public_feedback/')

    f = Feedback.objects.filter(date__range=[fdate, tdate])
    if not f:
        messages.warning(request, "No feedback found in the selected date range")
    return render(request, 'SUBADMIN/view public feedback.html', {'data': f})


#### VIEW USERS
def subadmin_view_reg_users(request):
    res = User_details.objects.all()
    return render(request, 'SUBADMIN/registered users.html', {"data": res})


def subadmin_view_reg_users_post(request):
    search = request.POST['textfield']
    if not search:
        messages.error(request, "Please enter a search term")
        return redirect('/myapp/subadmin_view_reg_users/')
    res = User_details.objects.filter(name__icontains=search)
    if not res:
        messages.warning(request, "No users found matching your search")
    return render(request, 'SUBADMIN/registered users.html', {"data": res})




##################### PINK POLICE #################
from django.http import JsonResponse
from myapp.models import User_details




#### ADD DANGEROUS SPOT
import datetime
import base64
import os
from django.http import JsonResponse
from myapp.models import DangerousSpot, User

def add_dangerous_spot(request):
    try:
        place = request.POST.get("place")
        latitude = request.POST.get("latitude")
        longitude = request.POST.get("longitude")
        lid = request.POST.get("lid")
        image_data = request.POST.get("photo")  # base64 image from Flutter

        # Decode base64 image
        img_name = f"dangerous_{lid}_{datetime.datetime.now().timestamp()}.jpg"
        img_path = f"media/dangerous/{img_name}"
        os.makedirs("media/dangerous", exist_ok=True)

        with open(img_path, "wb") as f:
            f.write(base64.b64decode(image_data))

        # Save to database
        user = User.objects.get(id=lid)

        DangerousSpot.objects.create(
            place=place,
            latitude=latitude,
            longitude=longitude,
            photo=img_path,
            date=datetime.date.today(),
            LOGIN=user,
            status="Pending"
        )

        return JsonResponse({"status": "ok", "message": "Uploaded successfully"})

    except Exception as e:
        return JsonResponse({"status": "error", "message": str(e)})


from django.http import JsonResponse
from myapp.models import DangerousSpot

def pinkpolice_view_dangerous_spot(request):
    try:
        spots = DangerousSpot.objects.all().order_by('-id')

        data = []
        for s in spots:
            data.append({
                "id": s.id,
                "place": s.place,
                "latitude": s.latitude,
                "longitude": s.longitude,
                "photo": s.photo,
                "date": str(s.date),
                "status": s.status,
            })
        print('gggggggggg',data)
        return JsonResponse({"status": "ok", "data": data})

    except Exception as e:
        return JsonResponse({"status": "error", "message": str(e)})



from django.http import JsonResponse
from myapp.models import Complaint

def view_complaint(request):
    try:
        complaints = Complaint.objects.all().order_by('-id')

        data = []
        for c in complaints:
            data.append({
                "id": c.id,
                "user": c.USER.username,
                "date": str(c.date),
                "complaint": c.complaint,
                "reply": c.reply,
                "status": c.status,
                "officer": c.PINKPOLICE.officername,
            })

        return JsonResponse({"status": "ok", "data": data})

    except Exception as e:
        return JsonResponse({"status": "error", "message": str(e)})
from django.http import JsonResponse
from myapp.models import Complaint

def send_reply(request):
    try:
        cid = request.POST.get('cid')   # complaint id
        reply = request.POST.get('reply')

        complaint = Complaint.objects.get(id=cid)
        complaint.reply = reply
        complaint.status = "Replied"
        complaint.save()

        return JsonResponse({"status": "ok", "message": "Reply sent successfully"})
    except Exception as e:
        return JsonResponse({"status": "error", "message": str(e)})
from django.http import JsonResponse
from django.contrib.auth.models import User

def pinkpolice_change_password(request):
    try:
        lid = request.POST.get('lid')
        old_pass = request.POST.get('old_password')
        new_pass = request.POST.get('new_password')

        user = User.objects.get(id=lid)

        # Check old password
        if not user.check_password(old_pass):
            return JsonResponse({"status": "error", "message": "Incorrect old password"})

        # Change password
        user.set_password(new_pass)
        user.save()

        return JsonResponse({"status": "ok", "message": "Password changed successfully"})

    except Exception as e:
        return JsonResponse({"status": "error", "message": str(e)})

from django.http import JsonResponse
from myapp.models import PinkPolice

def pinkpolice_view_profile(request):
    try:
        lid = request.POST.get("lid")
        print("hhhhhhhhhhhhh",lid)

        profile = PinkPolice.objects.get(LOGIN_id=lid)

        data = {
            "officername": profile.officername,
            "vechileno": profile.vechileno,
            "gender": profile.gender,
            "email": profile.email,
            "phone": str(profile.phone),
            "dob": str(profile.dob),

            "place": profile.place,
            "post": profile.post,
            "district": profile.district,
            "state": profile.state,

            "policestation": profile.POLICESTATION.name,
            "ps_place": profile.POLICESTATION.place,
            "ps_phone": str(profile.POLICESTATION.phone),

            # ❌ No photo stored, so return empty string
            "photo": "",
        }


        return JsonResponse({"status": "ok", "data": data})

    except PinkPolice.DoesNotExist:
        return JsonResponse({"status": "error", "message": "Profile not found"})

    except Exception as e:
        return JsonResponse({"status": "error", "message": str(e)})


import base64
import os
from django.views.decorators.csrf import csrf_exempt
from django.http import JsonResponse
from django.core.files.storage import FileSystemStorage
from django.core.files.base import ContentFile
from .models import Idea, User
from datetime import datetime


from django.views.decorators.csrf import csrf_exempt
from django.http import JsonResponse
from django.core.files.storage import FileSystemStorage
from datetime import datetime
from .models import Idea, User

@csrf_exempt
def add_idea(request):
    if request.method == "POST":
        try:
            lid = request.POST.get('lid')
            idea_text = request.POST.get('idea')

            user = User.objects.get(id=lid)

            # -----------------------------
            # IMAGE UPLOAD (your style)
            # -----------------------------
            photo = request.FILES.get('image')     # <-- important
            path = ""

            if photo:
                fs = FileSystemStorage()
                filename = datetime.now().strftime("%Y%m%d-%H%M%S") + ".jpg"
                fs.save(filename, photo)
                path = fs.url(filename)

            # SAVE IDEA
            Idea.objects.create(
                USER=user,
                idea=idea_text,
                image=path,
                date=datetime.now()
            )

            return JsonResponse({"status": "ok", "message": "Idea added successfully"})

        except Exception as e:
            return JsonResponse({"status": "error", "message": str(e)})

    return JsonResponse({"status": "error", "message": "POST request required"})


from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from .models import Idea

@csrf_exempt
def view_all_ideas(request):
    if request.method == "POST":
        lid = request.POST.get("lid")

        if not lid:
            return JsonResponse({
                "status": "error",
                "message": "User ID required"
            })

        ideas = Idea.objects.exclude(USER_id=lid).order_by('-date')

        data = []
        for i in ideas:
            data.append({
                "id": i.id,
                "idea": i.idea,
                "image": i.image,
                "date": i.date.strftime("%Y-%m-%d"),
                "user_id": i.USER.id,
                "username": i.USER.username,
            })

        return JsonResponse({
            "status": "ok",
            "data": data
        })

    return JsonResponse({
        "status": "error",
        "message": "POST request required"
    })

@csrf_exempt
def view_my_ideas(request):
    if request.method == "POST":
        lid = request.POST.get("lid")

        ideas = Idea.objects.filter(USER__id=lid).order_by('-date')

        data = []
        for i in ideas:
            data.append({
                "id": i.id,
                "idea": i.idea,
                "image": i.image,
                "date": i.date.strftime("%Y-%m-%d"),
            })

        return JsonResponse({"status": "ok", "data": data})

    return JsonResponse({"status": "error", "message": "POST required"})
@csrf_exempt
def edit_idea(request):
    if request.method == "POST":
        idea_id = request.POST.get("idea_id")
        new_text = request.POST.get("idea")

        idea = Idea.objects.get(id=idea_id)
        idea.idea = new_text
        idea.save()

        return JsonResponse({"status": "ok", "message": "Idea updated"})

    return JsonResponse({"status": "error"})
@csrf_exempt
def delete_idea(request):
    if request.method == "POST":
        idea_id = request.POST.get("idea_id")
        Idea.objects.filter(id=idea_id).delete()
        return JsonResponse({"status": "ok", "message": "Idea deleted"})

    return JsonResponse({"status": "error"})


from django.views.decorators.csrf import csrf_exempt
from django.http import JsonResponse
from datetime import datetime
from .models import Complaint, PinkPolice, User

@csrf_exempt
def send_complaint(request):
    try:
        lid = request.POST.get('lid')
        police_id = request.POST.get('police_id')   # selected Pink Police
        complaint_text = request.POST.get('complaint')

        user = User.objects.get(id=lid)
        police = PinkPolice.objects.get(id=police_id)

        Complaint.objects.create(
            USER=user,
            PINKPOLICE=police,
            complaint=complaint_text,
            reply="",
            status="pending",
            date=datetime.now()
        )

        return JsonResponse({"status": "ok", "message": "Complaint sent"})

    except Exception as e:
        return JsonResponse({"status": "error", "message": str(e)})

@csrf_exempt
def user_view_reply(request):
    try:
        lid = request.POST.get('lid')
        user = User.objects.get(id=lid)

        complaints = Complaint.objects.filter(USER=user).order_by('-id')

        data = []
        for c in complaints:
            data.append({
                "complaint": c.complaint,
                "date": str(c.date),
                "reply": c.reply,
                "status": c.status,
                "police_name": c.PINKPOLICE.officername
            })

        return JsonResponse({"status": "ok", "data": data})

    except Exception as e:
        return JsonResponse({"status": "error", "message": str(e)})

@csrf_exempt
def user_view_pink_police(request):
    try:
        police = PinkPolice.objects.all().order_by('-id')

        data = []
        for p in police:
            data.append({
                "id": p.id,
                "officername": p.officername,
                "vechileno": p.vechileno,
                "place": p.place,
                "post": p.post,
                "district": p.district,
                "state": p.state,
                "email": p.email,
                "phone": p.phone,
                "gender": p.gender,
                "dob": str(p.dob),
                "policestation": p.POLICESTATION.name,
            })

        return JsonResponse({"status": "ok", "data": data})

    except Exception as e:
        return JsonResponse({"status": "error", "message": str(e)})


from django.views.decorators.csrf import csrf_exempt
from django.http import JsonResponse
from django.contrib.auth.models import User

@csrf_exempt
def user_change_password(request):
    try:
        lid = request.POST.get('lid')
        old_password = request.POST.get('old_password')
        new_password = request.POST.get('new_password')

        user = User.objects.get(id=lid)

        # Check old password
        if not user.check_password(old_password):
            return JsonResponse({"status": "error", "message": "Incorrect old password"})

        # Set new password
        user.set_password(new_password)
        user.save()

        return JsonResponse({"status": "ok", "message": "Password changed successfully"})

    except Exception as e:
        return JsonResponse({"status": "error", "message": str(e)})

@csrf_exempt
def view_profile(request):
    try:
        lid = request.POST.get('lid')
        user = User.objects.get(id=lid)

        profile = User_details.objects.get(LOGIN=user)

        data = {
            "name": profile.name,
            "dob": str(profile.dob),
            "gender": profile.gender,
            "phone": profile.phone,
            "email": profile.email,
            "place": profile.place,
            "post": profile.post,
            "district": profile.district,
            "state": profile.state,
            "identificationmark": profile.identificationmark,
            "fathersname": profile.fathersname,
            "mothername": profile.mothername,
            "bloodgroup": profile.bloodgroup,
            "photo": profile.photo,
        }

        return JsonResponse({"status": "ok", "data": data})

    except Exception as e:
        return JsonResponse({"status": "error", "message": str(e)})

@csrf_exempt
def update_profile(request):
    try:
        lid = request.POST.get('lid')
        user = User.objects.get(id=lid)
        profile = User_details.objects.get(LOGIN=user)

        profile.name = request.POST.get('name')
        profile.gender = request.POST.get('gender')
        profile.phone = request.POST.get('phone')
        profile.email = request.POST.get('email')
        profile.place = request.POST.get('place')
        profile.post = request.POST.get('post')
        profile.district = request.POST.get('district')
        profile.state = request.POST.get('state')
        profile.identificationmark = request.POST.get('identificationmark')
        profile.fathersname = request.POST.get('fathersname')
        profile.mothername = request.POST.get('mothername')
        profile.bloodgroup = request.POST.get('bloodgroup')

        profile.save()

        return JsonResponse({"status": "ok", "message": "Profile updated"})

    except Exception as e:
        return JsonResponse({"status": "error", "message": str(e)})

@csrf_exempt
def update_profile_photo(request):
    try:
        lid = request.POST.get('lid')
        photo = request.FILES.get('photo')

        user = User.objects.get(id=lid)
        profile = User_details.objects.get(LOGIN=user)

        if photo:
            fs = FileSystemStorage()
            filename = datetime.now().strftime("%Y%m%d-%H%M%S") + ".jpg"
            fs.save(filename, photo)
            path = fs.url(filename)

            profile.photo = path
            profile.save()

        return JsonResponse({"status": "ok", "message": "Photo updated", "photo": profile.photo})

    except Exception as e:
        return JsonResponse({"status": "error", "message": str(e)})

@csrf_exempt
def update_location(request):
    try:
        lid = request.POST.get('lid')
        lat = request.POST.get('latitude')
        lon = request.POST.get('longitude')

        user = User.objects.get(id=lid)

        # If location already exists → update it
        loc, created = Location.objects.get_or_create(LOGIN=user)
        loc.latitude = lat
        loc.longitude = lon
        loc.save()

        return JsonResponse({"status": "ok", "message": "Location updated"})

    except Exception as e:
        return JsonResponse({"status": "error", "message": str(e)})

import math

def distance(lat1, lon1, lat2, lon2):
    R = 6371  # Radius of earth in KM
    dLat = math.radians(lat2 - lat1)
    dLon = math.radians(lon2 - lon1)
    a = (math.sin(dLat/2) ** 2 +
         math.cos(math.radians(lat1)) *
         math.cos(math.radians(lat2)) *
         math.sin(dLon/2) ** 2)
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))

from math import radians, sin, cos, sqrt, atan2

def haversine(lat1, lon1, lat2, lon2):
    lat1, lon1, lat2, lon2 = map(float, [lat1, lon1, lat2, lon2])
    R = 6371  # km

    dLat = radians(lat2 - lat1)
    dLon = radians(lon2 - lon1)

    a = sin(dLat/2)**2 + cos(radians(lat1)) * cos(radians(lat2)) * sin(dLon/2)**2
    c = 2 * atan2(sqrt(a), sqrt(1 - a))

    return R * c

@csrf_exempt
def view_nearby_users(request):
    try:
        lid = request.POST.get('lid')
        radius = float(request.POST.get('radius', 2))  # default = 2 km

        # Get current user location
        try:
            current_loc = Location.objects.filter(LOGIN_id=lid).latest('id')
        except Location.DoesNotExist:
            return JsonResponse({"status": "error", "message": "User location not found"})

        user_lat = float(current_loc.latitude)
        user_lon = float(current_loc.longitude)

        results = []

        # Get ALL users except current user
        all_users = User.objects.exclude(id=lid)

        for usr in all_users:
            try:
                # Latest location of each user
                loc = Location.objects.filter(LOGIN=usr).latest('id')

                # Distance calculation
                distance_km = haversine(user_lat, user_lon, loc.latitude, loc.longitude)

                # User must have profile
                profile = User_details.objects.get(LOGIN=usr)

                results.append({
                    "user_id": usr.id,
                    "name": profile.name,
                    "phone": profile.phone,
                    "photo": profile.photo,
                    "latitude": float(loc.latitude),
                    "longitude": float(loc.longitude),
                    "distance_km": round(distance_km, 2),
                })

            except Location.DoesNotExist:
                continue
            except User_details.DoesNotExist:
                continue
            except Exception as e:
                print(f"Error for user {usr.id}: {e}")
                continue

        # Sort by distance
        results.sort(key=lambda x: x["distance_km"])

        # Filter radius
        nearby = [u for u in results if u["distance_km"] <= radius]

        return JsonResponse({"status": "ok", "users": nearby})

    except Exception as e:
        return JsonResponse({"status": "error", "message": str(e)})

@csrf_exempt
def add_dangerous_spot(request):
    try:
        lid = request.POST.get('lid')
        place = request.POST.get('place')
        latitude = request.POST.get('latitude')
        longitude = request.POST.get('longitude')
        photo = request.FILES.get('photo')

        user = User.objects.get(id=lid)

        # Save image using FileSystemStorage
        fs = FileSystemStorage()
        filename = datetime.now().strftime("%Y%m%d-%H%M%S") + ".jpg"
        fs.save(filename, photo)
        path = fs.url(filename)

        DangerousSpot.objects.create(
            LOGIN=user,
            place=place,
            latitude=latitude,
            longitude=longitude,
            photo=path,
            date=datetime.now(),
            status="pending"
        )

        return JsonResponse({"status": "ok", "message": "Report submitted"})

    except Exception as e:
        return JsonResponse({"status": "error", "message": str(e)})

@csrf_exempt
def user_view_dangerous_spot(request):
    try:
        lid = request.POST.get('lid')
        user = User.objects.get(id=lid)

        spots = DangerousSpot.objects.filter(LOGIN=user).order_by('-id')

        data = []
        for s in spots:
            data.append({
                "id": s.id,
                "place": s.place,
                "latitude": s.latitude,
                "longitude": s.longitude,
                "photo": s.photo,
                "date": str(s.date),
                "status": s.status,
            })

        return JsonResponse({"status": "ok", "data": data})

    except Exception as e:
        return JsonResponse({"status": "error", "message": str(e)})
from django.views.decorators.csrf import csrf_exempt
from django.http import JsonResponse
from django.core.files.storage import FileSystemStorage
from datetime import datetime
from .models import DangerousSpot, User, User_details
import json

@csrf_exempt
def add_dangerous_spot(request):
    try:
        if request.method != "POST":
            return JsonResponse({"status":"error","message":"POST required"})

        lid = request.POST.get('lid')
        place = request.POST.get('place')
        latitude = request.POST.get('latitude')
        longitude = request.POST.get('longitude')
        photo = request.FILES.get('photo')

        user = User.objects.get(id=lid)

        path = ""
        if photo:
            fs = FileSystemStorage()
            filename = datetime.now().strftime("%Y%m%d-%H%M%S") + ".jpg"
            fs.save(filename, photo)
            path = fs.url(filename)

        DangerousSpot.objects.create(
            LOGIN=user,
            place=place or "",
            latitude=latitude or "",
            longitude=longitude or "",
            photo=path,
            date=datetime.now(),
            status="pending"
        )
        return JsonResponse({"status":"ok","message":"Report submitted"})
    except Exception as e:
        return JsonResponse({"status":"error","message":str(e)})

@csrf_exempt
def user_view_dangerous_spot(request):
    try:
        lid = request.POST.get('lid')
        user = User.objects.get(id=lid)

        spots = DangerousSpot.objects.filter(LOGIN=user).order_by('-id')
        data = []
        for s in spots:
            data.append({
                "id": s.id,
                "place": s.place,
                "latitude": s.latitude,
                "longitude": s.longitude,
                "photo": s.photo,
                "date": str(s.date),
                "status": s.status,
            })
        return JsonResponse({"status":"ok","data":data})
    except Exception as e:
        return JsonResponse({"status":"error","message":str(e)})

@csrf_exempt
def user_update_dangerous_spot(request):
    try:
        if request.method != "POST":
            return JsonResponse({"status":"error","message":"POST required"})
        lid = request.POST.get('lid')
        spot_id = request.POST.get('id')  # spot id to update
        place = request.POST.get('place')
        latitude = request.POST.get('latitude')
        longitude = request.POST.get('longitude')
        photo = request.FILES.get('photo')

        user = User.objects.get(id=lid)
        spot = DangerousSpot.objects.get(id=spot_id)

        # ownership check
        if spot.LOGIN.id != user.id:
            return JsonResponse({"status":"error","message":"Not authorized"})

        # update fields only if provided
        if place is not None:
            spot.place = place
        if latitude is not None:
            spot.latitude = latitude
        if longitude is not None:
            spot.longitude = longitude

        if photo:
            fs = FileSystemStorage()
            filename = datetime.now().strftime("%Y%m%d-%H%M%S") + ".jpg"
            fs.save(filename, photo)
            spot.photo = fs.url(filename)

        spot.save()
        return JsonResponse({"status":"ok","message":"Spot updated","data":{
            "id": spot.id,
            "place": spot.place,
            "latitude": spot.latitude,
            "longitude": spot.longitude,
            "photo": spot.photo,
            "date": str(spot.date),
            "status": spot.status
        }})
    except DangerousSpot.DoesNotExist:
        return JsonResponse({"status":"error","message":"Spot not found"})
    except User.DoesNotExist:
        return JsonResponse({"status":"error","message":"User not found"})
    except Exception as e:
        return JsonResponse({"status":"error","message":str(e)})

@csrf_exempt
def user_delete_dangerous_spot(request):
    try:
        if request.method != "POST":
            return JsonResponse({"status":"error","message":"POST required"})
        lid = request.POST.get('lid')
        spot_id = request.POST.get('id')

        user = User.objects.get(id=lid)
        spot = DangerousSpot.objects.get(id=spot_id)

        # ownership check
        if spot.LOGIN.id != user.id:
            return JsonResponse({"status":"error","message":"Not authorized"})

        spot.delete()
        return JsonResponse({"status":"ok","message":"Deleted successfully"})
    except DangerousSpot.DoesNotExist:
        return JsonResponse({"status":"error","message":"Spot not found"})
    except User.DoesNotExist:
        return JsonResponse({"status":"error","message":"User not found"})
    except Exception as e:
        return JsonResponse({"status":"error","message":str(e)})

def user_chatbot(request):
    messages=request.POST['message']
    result=generate_gemini_response(messages)

    return JsonResponse({'status': 'ok', "result": result})



from datetime import date
from django.http import JsonResponse

def user_send_emergency(request):
    try:
        lid = request.POST.get("lid")
        msg = request.POST.get("request")
        lat = request.POST.get("latitude")
        lon = request.POST.get("longitude")

        EmergencyRequest.objects.create(
            USER_id=lid,
            request=msg,
            latitude=lat,
            longitude=lon,
            date=date.today()
        )

        return JsonResponse({"status": "ok"})
    except Exception as e:
        return JsonResponse({"status": "error", "message": str(e)})


def pinkpolice_view_emergency(request):
    try:
        lid = request.POST.get("lid")
        radius = 5  # KM

        # ✅ Get latest pink police location
        my_loc = Location.objects.filter(LOGIN_id=lid).latest('id')
        my_lat = float(my_loc.latitude)
        my_lon = float(my_loc.longitude)

        result = []

        for req in EmergencyRequest.objects.all().order_by("-id"):
            if not req.latitude or not req.longitude:
                continue

            req_lat = float(req.latitude)
            req_lon = float(req.longitude)

            d = haversine(my_lat, my_lon, req_lat, req_lon)

            if d <= radius:
                user = User_details.objects.get(LOGIN=req.USER)

                result.append({
                    "id": req.id,
                    "name": user.name,
                    "phone": user.phone,
                    "request": req.request,
                    "distance": round(d, 2),
                    "latitude": req.latitude,
                    "longitude": req.longitude,
                    "date": str(req.date)
                })

        return JsonResponse({"status": "ok", "data": result})

    except Location.DoesNotExist:
        return JsonResponse({"status": "error", "message": "Location not found"})

    except Exception as e:
        return JsonResponse({"status": "error", "message": str(e)})


from django.http import JsonResponse
from .models import SafePoint

def user_view_safepoints(request):
    try:
        points = SafePoint.objects.all()
        data = []

        for p in points:
            data.append({
                "id": p.id,
                "place": p.place,
                "latitude": p.latitude,
                "longitude": p.longitude,
                "landmark": p.landmark
            })

        return JsonResponse({"status": "ok", "data": data})

    except Exception as e:
        return JsonResponse({"status": "error", "message": str(e)})


def user_view_nearbyDangerosSpot(request):
    try:
        lid = request.POST.get('lid')
        radius = float(request.POST.get('radius', 2))  # km

        if not lid:
            return JsonResponse({"status": "error", "message": "lid missing"})

        # user current location
        try:
            current_loc = Location.objects.filter(LOGIN_id=lid).latest('id')
        except Location.DoesNotExist:
            return JsonResponse({"status": "error", "message": "User location not found"})

        user_lat = float(current_loc.latitude)
        user_lon = float(current_loc.longitude)

        data = []

        points = DangerousSpot.objects.filter(status="approved")

        for p in points:
            if not p.latitude or not p.longitude:
                continue

            distance_km = haversine(
                user_lat, user_lon,
                float(p.latitude), float(p.longitude)
            )

            # ✅ FIX HERE
            if distance_km <= radius:
                data.append({
                    "id": p.id,
                    "place": p.place,
                    "latitude": p.latitude,
                    "longitude": p.longitude,
                    "landmark": p.photo,   # or landmark field if exists
                    "distance": round(distance_km, 2)
                })
        print(data,'hhhhhhhhhhhhhh')
        return JsonResponse({"status": "ok", "data": data})

    except Exception as e:
        return JsonResponse({"status": "error", "message": str(e)})

from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.contrib.auth.models import User

from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.contrib.auth.models import User
from .models import User_details, EmergnecyNumber

@csrf_exempt
def send_false_alarm(request):
    if request.method == "POST":
        lid = request.POST.get("lid")
        password = request.POST.get("password")

        if not lid or not password:
            return JsonResponse({
                "status": "error",
                "message": "Missing parameters"
            })

        try:
            # 🔐 Check user
            user = User.objects.get(id=lid)

            if not user.check_password(password):
                return JsonResponse({
                    "status": "error",
                    "message": "Incorrect password"
                })

            # ✅ Get user details
            try:
                user_details = User_details.objects.get(LOGIN=user)
            except User_details.DoesNotExist:
                return JsonResponse({
                    "status": "error",
                    "message": "User details not found"
                })

            # ✅ Fetch emergency numbers
            emergency_numbers = EmergnecyNumber.objects.filter(
                USER=user_details
            )

            numbers_list = []
            for e in emergency_numbers:
                numbers_list.append(str(e.number))

            return JsonResponse({
                "status": "ok",
                "message": "Password verified",
                "contacts": numbers_list
            })

        except User.DoesNotExist:
            return JsonResponse({
                "status": "error",
                "message": "User not found"
            })

    return JsonResponse({
        "status": "error",
        "message": "Invalid request"
    })

