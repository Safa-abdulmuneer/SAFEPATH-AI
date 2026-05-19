import datetime
from math import radians, sin, cos, atan2, sqrt

from django.contrib import messages
from django.contrib.auth import authenticate, login, logout
from django.contrib.auth.hashers import check_password, make_password
from django.contrib.auth.models import Group
from django.core.files.storage import FileSystemStorage
from django.http import HttpResponse, JsonResponse
from django.shortcuts import render, redirect
from django.views.decorators.csrf import csrf_exempt

from myapp.blockchain import update_user_credit_score, get_user_credit_score
from myapp.prediction_new import get_time_and_lighting, get_area_zone, get_nearby_places, check_known_location
from .models import *




uu=User.objects.get(username="admin@gmail.com")
uu.set_password("Admin@123")
uu.save()

# Create your views here.
# print(make_password("Rajesh@123"))
def logoutt(request):
    logout(request)
    return redirect("/")

def logg(request):
    return render(request, "index.html")



def login_post(request):
    username=request.POST['username']
    password=request.POST['password']
    res=authenticate(request, username=username, password=password)
    if res is not None:
        login(request, res)
        if res.is_superuser:
            return HttpResponse("<script>alert('Welcome admin');window.location='/admin_home';</script>")
        elif res.groups.filter(name="authority").exists():
            stat=police_officers.objects.get(LOGIN_id=request.user.id).status
            if stat == "pending":
                return HttpResponse("<script>alert('You cannot login now. Please wait for approval');window.location='/';</script>")
            elif stat == "Approved":
                request.session['pid'] = police_officers.objects.get(LOGIN_id=request.user.id).id
                return HttpResponse("<script>alert('Welcome authority');window.location='/police_home';</script>")
            else:
                return HttpResponse("<script>alert('Your account has been rejected');window.location='/';</script>")
        else:
            return HttpResponse("<script>alert('No access');window.location='/';</script>")
    else:
        return HttpResponse("<script>alert('Invalid details');window.location='/';</script>")





###########         ADMIN
def admin_home(request):
    return render(request, "admin/index.html")



def adm_add_police_station(request):
    return render(request, "admin/add_police_station.html")

def adm_add_police_station_post(request):
    name=request.POST['textfield']
    email=request.POST['textfield2']
    phone=request.POST['textfield3']
    place=request.POST['textfield4']
    post=request.POST['textfield5']
    pin=request.POST['textfield6']
    district=request.POST['textfield7']

    obj=police_station()
    obj.name=name
    obj.email=email
    obj.phone=phone
    obj.place=place
    obj.post=post
    obj.pin=pin
    obj.district=district
    obj.save()
    return HttpResponse("<script>alert('Police station added');window.location='/adm_add_police_station#content';</script>")

def adm_view_police_station(request):
    res=police_station.objects.all()
    return render(request, "admin/view_police_station.html", {'data' : res})

def adm_delete_police_station(request, id):
    obj=police_station.objects.get(id=id)
    obj.delete()
    return redirect("/adm_view_police_station#content")

def adm_edit_police_station(request, id):
    obj=police_station.objects.get(id=id)
    return render(request, "admin/edit_police_station.html", {'data' : obj})


def adm_edit_police_station_post(request, id):
    name = request.POST['textfield']
    email = request.POST['textfield2']
    phone = request.POST['textfield3']
    place = request.POST['textfield4']
    post = request.POST['textfield5']
    pin = request.POST['textfield6']
    district = request.POST['textfield7']

    police_station.objects.filter(id=id).update(name = name, email = email, phone = phone,
                        place=place, post=post, district=district, pin=pin)
    return HttpResponse("<script>alert('Police Station updated');window.location='/adm_view_police_station#content';</script>")

def adm_verify_police_officer(request):
    res=police_officers.objects.filter(status="pending")
    return render(request, "admin/verify_police_officers.html", {'data' : res})

def adm_approve_police_officer(request, id):
    police_officers.objects.filter(id=id).update(status="Approved")
    return HttpResponse(
        "<script>alert('Approved');window.location='/adm_verify_police_officer#content';</script>")

def adm_reject_police_officer(request, id):
    police_officers.objects.filter(id=id).update(status="Rejected")
    return HttpResponse(
        "<script>alert('Rejected');window.location='/adm_verify_police_officer#content';</script>")

def adm_view_verified_police_officer(request):
    res=police_officers.objects.filter(status="Approved")
    return render(request, "admin/verified_police_officers.html", {'data' : res})

def adm_view_users(request):
    res=users.objects.all()
    return render(request, "admin/view_users.html", {'data' : res})

def adm_view_false_reportings(request):
    res=false_report.objects.all().order_by("-id")
    return render(request, "admin/view_false_reportings.html", {'data' : res})

def adm_block_user(request, id):
    users.objects.filter(id=id).update(status="blocked")
    return HttpResponse(
        "<script>alert('Blocked');window.location='/adm_view_false_reportings#content';</script>")

def adm_unblock_user(request, id):
    users.objects.filter(id=id).update(status="approved")
    return HttpResponse(
        "<script>alert('Unblocked');window.location='/adm_view_false_reportings#content';</script>")





#################           POLICE STATION

def pol_register(request):
    data=police_station.objects.all()
    return render(request, "police_station/register.html", {"data":data})

def pol_register_post(request):
    name=request.POST['textfield']
    email=request.POST['textfield2']
    phone=request.POST['textfield3']
    lati=request.POST['textfield4']
    logi=request.POST['textfield5']
    ps_id=request.POST['select']
    password=request.POST['textfield6']

    obj2=User()
    obj2.username=email
    obj2.password=make_password(password)
    obj2.save()
    obj2.groups.add(Group.objects.get(name="authority"))

    obj=police_officers()
    obj.name=name
    obj.email=email
    obj.phone=phone
    obj.latitude=lati
    obj.longitude=logi
    obj.status="pending"
    obj.STATION_id=ps_id
    obj.LOGIN=obj2
    obj.save()

    lobj=Location()
    lobj.latitude=lati
    lobj.longitude=logi
    lobj.LOGIN=obj2
    lobj.save()

    return HttpResponse("<script>alert('Registered');window.location='/';</script>")

def haversine(lat1, lon1, lat2, lon2):
    lat1, lon1, lat2, lon2 = map(float, [lat1, lon1, lat2, lon2])
    R = 6371  # km

    dLat = radians(lat2 - lat1)
    dLon = radians(lon2 - lon1)

    a = sin(dLat/2)**2 + cos(radians(lat1)) * cos(radians(lat2)) * sin(dLon/2)**2
    c = 2 * atan2(sqrt(a), sqrt(1 - a))

    return R * c

def user_view_nearbyDangerosSpot(request):
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

        points = dangerous_spot.objects.filter(status="verified")

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
                    "place": p.place_name,
                    "latitude": p.latitude,
                    "longitude": p.longitude,
                    "landmark": "",   # or landmark field if exists
                    "distance": round(distance_km, 2)
                })
        print(data,'hhhhhhhhhhhhhh')
        return JsonResponse({"status": "ok", "data": data})


def police_home(request):
    return render(request, "police_station/index.html")

def pol_view_profile(request):
    data=police_officers.objects.get(id=request.session['pid'])
    data2=police_station.objects.all()
    return render(request, "police_station/profile.html", {"data":data, "data2":data2})

def pol_edit_profile(request):
    name=request.POST['textfield']
    email=request.POST['textfield2']
    phone=request.POST['textfield3']
    lati=request.POST['textfield4']
    logi=request.POST['textfield5']
    ps_id=request.POST['select']


    police_officers.objects.filter(id=request.session['pid']).update(name=name, email=email, phone=phone, latitude=lati,
            longitude=logi, STATION_id=ps_id)
    return HttpResponse("<script>alert('Profile updated');window.location='/pol_view_profile#content';</script>")


def pol_add_dangerous_spot(request):
    return render(request, "police_station/add_dangerous_spot.html")

def pol_add_dangerous_spot_post(request):
    name=request.POST['place_name']
    lati=request.POST['latitude']
    logi=request.POST['longitude']

    obj=dangerous_spot()
    obj.latitude=lati
    obj.place_name=name
    obj.longitude=logi
    obj.LOGIN_id=request.user.id
    obj.status="verified"
    obj.type="policestation"
    obj.save()
    return HttpResponse("<script>alert('Dangerous Spot added');window.location='/pol_add_dangerous_spot#content';</script>")

def pol_view_dangerous_spot(request):
    res=dangerous_spot.objects.filter(LOGIN__id=request.user.id)
    return render(request, "police_station/view_dangerous_spot.html", {'data' : res})

def pol_delete_dangerous_spot(request, id):
    obj=dangerous_spot.objects.get(id=id)
    obj.delete()
    return redirect("/pol_view_dangerous_spot#content")

def pol_edit_dangerous_spot(request, id):
    obj=dangerous_spot.objects.get(id=id)
    return render(request, "police_station/edit_dangerous_spot.html", {'data' : obj})


def pol_edit_dangerous_spot_post(request, id):
    name = request.POST['textfield']
    lati = request.POST['textfield2']
    logi = request.POST['textfield3']
    dangerous_spot.objects.filter(id=id).update(place_name = name, latitude = lati,
                            longitude=logi)
    return HttpResponse("<script>alert('Dangerous Spot updated');window.location='/pol_view_dangerous_spot#content';</script>")

def pol_add_safe_point(request):
    return render(request, "police_station/add_safe_point.html")

def pol_add_safe_point_post(request):
    name=request.POST['textfield']
    lati=request.POST['textfield2']
    logi=request.POST['textfield3']

    obj=safe_spot()
    obj.latitude=lati
    obj.place_name=name
    obj.longitude=logi
    obj.LOGIN_id=request.user.id
    obj.save()
    return HttpResponse("<script>alert('Safe Point added');window.location='/pol_add_safe_point#content';</script>")

def pol_view_safe_point(request):
    res=safe_spot.objects.filter(LOGIN_id=request.user.id)
    return render(request, "police_station/view_safe_point.html", {'data' : res})

def pol_delete_safe_point(request, id):
    obj=safe_spot.objects.get(id=id)
    obj.delete()
    return redirect("/pol_view_safe_point#content")

def pol_edit_safe_point(request, id):
    obj=safe_spot.objects.get(id=id)
    return render(request, "police_station/edit_safe_point.html", {'data' : obj})


def pol_edit_safe_point_post(request, id):
    name = request.POST['textfield']
    lati = request.POST['textfield2']
    logi = request.POST['textfield3']
    safe_spot.objects.filter(id=id).update(place_name = name, latitude = lati,
                            longitude=logi)
    return HttpResponse("<script>alert('Safe Point updated');window.location='/pol_view_safe_point#content';</script>")

def pol_view_reported_dangerous_spot(request):
    res=reported_spot.objects.filter(status="pending")
    return render(request, "police_station/view_reported_dangerous_spot.html", {'data' : res})

def pol_verify_spot(request, id):
    obj=reported_spot.objects.get(id=id)
    obj2=dangerous_spot()
    obj2.place_name=obj.place_name
    obj2.latitude=obj.latitude
    obj2.longitude=obj.longitude
    obj2.LOGIN=request.user.id
    obj2.save()
    obj.delete()
    return HttpResponse(
        "<script>alert('Verified');window.location='/pol_view_reported_dangerous_spot#content';</script>")

def pol_report_false_spot(request, id):
    reported_spot.objects.filter(id=id).update(status="reported")
    obj=false_report()
    obj.date=datetime.datetime.now().strftime("%Y-%m-%d")
    obj.time=datetime.datetime.now().strftime("%H:%M")
    obj.REPORT_SPOT_id=id
    obj.OFFICER_id=request.session['pid']
    obj.save()
    return HttpResponse(
        "<script>alert('Reported');window.location='/pol_view_reported_dangerous_spot#content';</script>")

def pol_view_emergency_request(request):
    res=emergency_request.objects.filter(status="pending").order_by("-id")
    ar=[]
    radius = float(request.POST.get('radius', 10))  # km

    # user current location
    try:
        current_loc = Location.objects.filter(LOGIN_id=request.user.id).latest('id')
    except Location.DoesNotExist:
        return JsonResponse({"status": "error", "message": "User location not found"})

    pol_lat = float(current_loc.latitude)
    pol_lon = float(current_loc.longitude)

    for p in res:
        if not p.latitude or not p.longitude:
            continue

        distance_km = haversine(
            pol_lat, pol_lon,
            float(p.latitude), float(p.longitude)
        )

        # ✅ FIX HERE
        if distance_km <= radius:
            ar.append(p)
    print(ar)
    return render(request, "police_station/view_emergency_request.html", {'data' : ar})

def pol_update_emergeny_request(request, id):
    emergency_request.objects.filter(id=id).update(status="helped")
    return HttpResponse(
        "<script>alert('Status updated');window.location='/pol_view_emergency_request#content';</script>")

def pol_change_password(request):
    return render(request, "police_station/change_password.html")
def pol_change_password_post(request):
    cur_p=request.POST['textfield']
    new_p=request.POST['textfield2']
    data=check_password(cur_p, request.user.password)
    if data:
        obj=request.user
        obj.password=make_password(new_p)
        obj.save()
        return HttpResponse(
            "<script>alert('Password changed');window.location='/';</script>")

    else:
        return HttpResponse(
            "<script>alert('Invalid password');window.location='/pol_change_password#content';</script>")





############################user !!!!!!!!!!!!!!!!!!!!!!!!!!!!




def user_registration(request):
    name = request.POST['name']
    phone = request.POST['phone']
    email = request.POST['email']
    place = request.POST['place']
    post = request.POST['post']
    district = request.POST['district']
    pin = request.POST['pin']
    password= request.POST['password']
    confirmp= request.POST['confirmp']

    v = User()


    if User.objects.filter(username=email).exists():
        return JsonResponse({'message':'Email already registered'})
    u = User.objects.create_user(username=email, password=password)
    u.groups.add(Group.objects.get(name='user'))
    v = users()
    v.name = name

    v.phone = phone
    v.email = email
    v.place = place
    v.post = post
    v.district = district
    v.pin = pin
    v.status = "pending"

    v.LOGIN_id = u.id
    v.save()
    return JsonResponse({"status": 'ok'})



def user_login(request):
    username=request.POST['username']
    password=request.POST['password']
    user = authenticate(username=username,password=password)
    if user is not None:
        login(request,user)
        if user.groups.filter(name='user').exists():
            return JsonResponse({"status": 'ok', "lid": user.id, "type": "user"})
        else:
            return JsonResponse({"status":'no'})
    else:
        return JsonResponse({"status":'no'})


def updatelocation(request):
    print(request.POST)
    lat = request.POST['lat']
    lon = request.POST['lon']
    did = request.POST['lid']
    print(lat, lon)
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


def add_dangerous_spot(request):
    try:
        place = request.POST.get("place")
        latitude = request.POST.get("latitude")
        longitude = request.POST.get("longitude")
        lid = request.POST.get("lid")

       # Save to database
        user = User.objects.get(id=lid)

        dangerous_spot.objects.create(
            place_name=place,
            latitude=latitude,
            longitude=longitude,
            LOGIN_id=lid,
            status="Pending",
            type="users"
        )

        return JsonResponse({"status": "ok", "message": "Uploaded successfully"})

    except Exception as e:
        return JsonResponse({"status": "error", "message": str(e)})


def user_view_dangerous_spot(request):
    try:
        lid = request.POST.get('lid')
        user = User.objects.get(id=lid)

        spots = dangerous_spot.objects.filter(LOGIN__id=lid).order_by('-id')

        data = []
        for s in spots:
            data.append({
                "id": s.id,
                "place": s.place_name,
                "latitude": s.latitude,
                "longitude": s.longitude,
                "photo": "",
                "status": s.status,
            })

        return JsonResponse({"status": "ok", "data": data})

    except Exception as e:
        return JsonResponse({"status": "error", "message": str(e)})


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

        user = User.objects.get(id=lid)
        spot = dangerous_spot.objects.get(id=spot_id)

        # ownership check
        if spot.LOGIN.id != user.id:
            return JsonResponse({"status":"error","message":"Not authorized"})

        # update fields only if provided
        if place is not None:
            spot.place_name = place
        if latitude is not None:
            spot.latitude = latitude

        if longitude is not None:
            spot.longitude = longitude



        spot.save()
        return JsonResponse({"status":"ok","message":"Spot updated","data":{
            "id": spot.id,
            "place": spot.place_name,
            "latitude": spot.latitude,
            "longitude": spot.longitude,
            "status": spot.status
        }})
    except dangerous_spot.DoesNotExist:
        return JsonResponse({"status":"error","message":"Spot not found"})
    except User.DoesNotExist:
        return JsonResponse({"status":"error","message":"User not found"})
    except Exception as e:
        return JsonResponse({"status":"error","message":str(e)})



def user_delete_dangerous_spot(request):
    try:
        if request.method != "POST":
            return JsonResponse({"status":"error","message":"POST required"})
        lid = request.POST.get('lid')
        spot_id = request.POST.get('id')

        user = User.objects.get(id=lid)
        spot = dangerous_spot.objects.get(id=spot_id)

        # ownership check
        if spot.LOGIN.id != user.id:
            return JsonResponse({"status":"error","message":"Not authorized"})

        spot.delete()
        return JsonResponse({"status":"ok","message":"Deleted successfully"})
    except dangerous_spot.DoesNotExist:
        return JsonResponse({"status":"error","message":"Spot not found"})
    except User.DoesNotExist:
        return JsonResponse({"status":"error","message":"User not found"})
    except Exception as e:
        return JsonResponse({"status":"error","message":str(e)})


def user_view_profile(request):
    if request.method == 'POST':
        lid = request.POST.get('lid')
        print("Login ID:", lid)

        try:
            # users എന്ന table-ൽ നിന്ന് data എടുക്കുക (ശ്രദ്ധിക്കുക: table name 'users' ആണോ?)
            user = users.objects.get(LOGIN_id=lid)

            return JsonResponse({
                "status": "ok",
                "name": user.name,
                "phone": user.phone,
                "email": user.email,
                "place": user.place,
                "post": user.post,
                "district": user.district,
                "pin": user.pin,
            })
        except users.DoesNotExist:
            return JsonResponse({
                "status": "error",
                "message": "User not found"
            })
        except Exception as e:
            return JsonResponse({
                "status": "error",
                "message": str(e)
            })
    else:
        return JsonResponse({
            "status": "error",
            "message": "Only POST method allowed"
        })


def update_profile(request):
    if request.method == 'POST':
        lid = request.POST.get('lid')
        name = request.POST.get('name')
        phone = request.POST.get('phone')
        email = request.POST.get('email')
        place = request.POST.get('place')
        post = request.POST.get('post')
        district = request.POST.get('district')
        pin = request.POST.get('pin')

        try:
            user = users.objects.get(LOGIN_id=lid)

            # Update fields
            user.name = name
            user.phone = phone
            user.email = email
            user.place = place
            user.post = post
            user.district = district
            user.pin = pin
            user.save()

            return JsonResponse({
                "status": "ok",
                "message": "Profile updated successfully"
            })
        except users.DoesNotExist:
            return JsonResponse({
                "status": "error",
                "message": "User not found"
            })
        except Exception as e:
            return JsonResponse({
                "status": "error",
                "message": str(e)
            })
    else:
        return JsonResponse({
            "status": "error",
            "message": "Only POST method allowed"
        })


def user_view_safepoints(request):
    try:
        points = safe_spot.objects.all()
        data = []

        for p in points:
            data.append({
                "id": p.id,
                "place": p.place_name,
                "latitude": p.latitude,
                "longitude": p.longitude,
            })

        return JsonResponse({"status": "ok", "data": data})

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
                profile = users.objects.get(LOGIN=usr)

                results.append({
                    "user_id": usr.id,
                    "name": profile.name,
                    "phone": profile.phone,
                    "latitude": float(loc.latitude),
                    "longitude": float(loc.longitude),
                    "distance_km": round(distance_km, 2),
                })

            except Location.DoesNotExist:
                continue
            except users.DoesNotExist:
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


import json
from django.views.decorators.csrf import csrf_exempt
from django.http import JsonResponse
from .models import UserJourney, users


@csrf_exempt
def add_user_journey(request):
    if request.method == 'POST':
        try:
            # Get data from request
            fromplace = request.POST.get('fromplace')
            toplace = request.POST.get('toplace')
            date = request.POST.get('date')
            time = request.POST.get('time')
            lid = request.POST.get('lid')  # Login ID

            print(f"📝 Adding journey: {fromplace} to {toplace}")
            print(f"User LID: {lid}")

            # Validation
            if not all([fromplace, toplace, date, time, lid]):
                return JsonResponse({
                    'status': 'error',
                    'message': 'All fields are required'
                })

            # Get user object
            try:
                user = users.objects.get(LOGIN_id=lid)
            except users.DoesNotExist:
                return JsonResponse({
                    'status': 'error',
                    'message': 'User not found'
                })

            # Save journey
            journey = UserJourney.objects.create(
                fromplace=fromplace,
                toplace=toplace,
                date=date,
                time=time,
                USER=user
            )

            return JsonResponse({
                'status': 'ok',
                'message': 'Journey added successfully',
                'journey_id': journey.id
            })

        except Exception as e:
            print(f"❌ Error: {str(e)}")
            return JsonResponse({
                'status': 'error',
                'message': str(e)
            })
    else:
        return JsonResponse({
            'status': 'error',
            'message': 'Only POST method allowed'
        })


@csrf_exempt
def view_user_journeys(request):
    if request.method == 'POST':
        try:
            lid = request.POST.get('lid')

            if not lid:
                return JsonResponse({
                    'status': 'error',
                    'message': 'User ID required'
                })

            # Get user journeys
            journeys = UserJourney.objects.filter(USER__LOGIN_id=lid).order_by('-date', '-time')

            journey_list = []
            for j in journeys:
                journey_list.append({
                    'id': j.id,
                    'fromplace': j.fromplace,
                    'toplace': j.toplace,
                    'date': j.date.strftime('%Y-%m-%d'),
                    'time': j.time.strftime('%H:%M:%S'),
                    'user_name': j.USER.name
                })

            return JsonResponse({
                'status': 'ok',
                'data': journey_list
            })

        except Exception as e:
            print(f"❌ Error: {str(e)}")
            return JsonResponse({
                'status': 'error',
                'message': str(e)
            })
    else:
        return JsonResponse({
            'status': 'error',
            'message': 'Only POST method allowed'
        })


@csrf_exempt
def delete_user_journey(request):
    if request.method == 'POST':
        try:
            journey_id = request.POST.get('journey_id')
            lid = request.POST.get('lid')

            if not journey_id or not lid:
                return JsonResponse({
                    'status': 'error',
                    'message': 'Journey ID and User ID required'
                })

            # Get and delete journey (ensure it belongs to user)
            journey = UserJourney.objects.get(id=journey_id, USER__LOGIN_id=lid)
            journey.delete()

            return JsonResponse({
                'status': 'ok',
                'message': 'Journey deleted successfully'
            })

        except UserJourney.DoesNotExist:
            return JsonResponse({
                'status': 'error',
                'message': 'Journey not found'
            })
        except Exception as e:
            print(f"❌ Error: {str(e)}")
            return JsonResponse({
                'status': 'error',
                'message': str(e)
            })
    else:
        return JsonResponse({
            'status': 'error',
            'message': 'Only POST method allowed'
        })


import json
from django.views.decorators.csrf import csrf_exempt
from django.http import JsonResponse
from .models import UserJourney, users


@csrf_exempt
def view_all_users_journeys(request):
    if request.method == 'POST':
        try:
            lid = request.POST.get('lid')  # Current user's login ID (optional)

            # Get all journeys with user details
            # journeys = UserJourney.objects.select_related('USER').all().order_by('-date', '-time')

            current_user = users.objects.get(LOGIN_id=lid)
            journeys = UserJourney.objects.select_related('USER').exclude(
                USER=current_user
            ).order_by('-date', '-time')


            journey_list = []
            for j in journeys:
                journey_list.append({
                    'id': j.id,
                    'fromplace': j.fromplace,
                    'toplace': j.toplace,
                    'date': j.date.strftime('%Y-%m-%d'),
                    'time': j.time.strftime('%H:%M:%S'),
                    'user': {
                        'id': j.USER.id,
                        'name': j.USER.name,
                        'phone': j.USER.phone,
                        'email': j.USER.email,
                        'place': j.USER.place,
                    }
                })

            return JsonResponse({
                'status': 'ok',
                'data': journey_list,
                'total_count': len(journey_list)
            })

        except Exception as e:
            print(f"❌ Error: {str(e)}")
            return JsonResponse({
                'status': 'error',
                'message': str(e)
            })
    else:
        return JsonResponse({
            'status': 'error',
            'message': 'Only POST method allowed'
        })


@csrf_exempt
def view_today_journeys(request):
    if request.method == 'POST':
        try:
            today = datetime.datetime.now().date()

            journeys = UserJourney.objects.select_related('USER').filter(
                date=today
            ).order_by('-time')

            journey_list = []
            for j in journeys:
                journey_list.append({
                    'id': j.id,
                    'fromplace': j.fromplace,
                    'toplace': j.toplace,
                    'date': j.date.strftime('%Y-%m-%d'),
                    'time': j.time.strftime('%H:%M:%S'),
                    'user': {
                        'name': j.USER.name,
                        'phone': j.USER.phone,
                        'place': j.USER.place,
                    }
                })

            return JsonResponse({
                'status': 'ok',
                'data': journey_list,
                'count': len(journey_list)
            })

        except Exception as e:
            return JsonResponse({
                'status': 'error',
                'message': str(e)
            })


@csrf_exempt
def search_user_journeys(request):
    if request.method == 'POST':
        try:
            search_term = request.POST.get('search', '')

            journeys = UserJourney.objects.select_related('USER').filter(
                models.Q(fromplace__icontains=search_term) |
                models.Q(toplace__icontains=search_term) |
                models.Q(USER__name__icontains=search_term) |
                models.Q(USER__place__icontains=search_term)
            ).order_by('-date', '-time')

            journey_list = []
            for j in journeys:
                journey_list.append({
                    'id': j.id,
                    'fromplace': j.fromplace,
                    'toplace': j.toplace,
                    'date': j.date.strftime('%Y-%m-%d'),
                    'time': j.time.strftime('%H:%M:%S'),
                    'user': {
                        'name': j.USER.name,
                        'phone': j.USER.phone,
                        'place': j.USER.place,
                    }
                })

            return JsonResponse({
                'status': 'ok',
                'data': journey_list,
                'count': len(journey_list)
            })

        except Exception as e:
            return JsonResponse({
                'status': 'error',
                'message': str(e)
            })


@csrf_exempt
def view_user_journeys_by_location(request):
    if request.method == 'POST':
        try:
            place = request.POST.get('place', '')

            journeys = UserJourney.objects.select_related('USER').filter(
                models.Q(fromplace__icontains=place) |
                models.Q(toplace__icontains=place)
            ).order_by('-date', '-time')

            journey_list = []
            for j in journeys:
                journey_list.append({
                    'id': j.id,
                    'fromplace': j.fromplace,
                    'toplace': j.toplace,
                    'date': j.date.strftime('%Y-%m-%d'),
                    'time': j.time.strftime('%H:%M:%S'),
                    'user': {
                        'name': j.USER.name,
                        'phone': j.USER.phone,
                        'place': j.USER.place,
                    }
                })

            return JsonResponse({
                'status': 'ok',
                'data': journey_list,
                'count': len(journey_list)
            })

        except Exception as e:
            return JsonResponse({
                'status': 'error',
                'message': str(e)
            })


import json
from django.views.decorators.csrf import csrf_exempt
from django.http import JsonResponse
from django.db.models import Q
from .models import UserJourney, users, Journeyrequest


# Send journey request
@csrf_exempt
def send_journey_request(request):
    if request.method == 'POST':
        try:
            journey_id = request.POST.get('journey_id')
            sender_lid = request.POST.get('sender_lid')  # Current user's login ID

            print(f"📝 Sending journey request: Journey ID={journey_id}, Sender LID={sender_lid}")

            # Validation
            if not journey_id or not sender_lid:
                return JsonResponse({
                    'status': 'error',
                    'message': 'Journey ID and Sender ID required'
                })

            # Get journey
            try:
                journey = UserJourney.objects.get(id=journey_id)
            except UserJourney.DoesNotExist:
                return JsonResponse({
                    'status': 'error',
                    'message': 'Journey not found'
                })

            # Get sender user
            try:
                sender = users.objects.get(LOGIN_id=sender_lid)
            except users.DoesNotExist:
                return JsonResponse({
                    'status': 'error',
                    'message': 'Sender user not found'
                })

            # Check if request already exists
            existing_request = Journeyrequest.objects.filter(
                JOURNEY=journey,
                SENDERID=sender,
                status='pending'
            ).first()

            if existing_request:
                return JsonResponse({
                    'status': 'error',
                    'message': 'Request already sent'
                })

            # Create request
            journey_request = Journeyrequest.objects.create(
                JOURNEY=journey,
                SENDERID=sender,
                status='pending',
                date=datetime.datetime.now().date()
            )

            return JsonResponse({
                'status': 'ok',
                'message': 'Request sent successfully',
                'request_id': journey_request.id
            })

        except Exception as e:
            print(f"❌ Error: {str(e)}")
            return JsonResponse({
                'status': 'error',
                'message': str(e)
            })
    else:
        return JsonResponse({
            'status': 'error',
            'message': 'Only POST method allowed'
        })


# View requests received by user (for journey owner)
@csrf_exempt
def view_received_requests(request):
    if request.method == 'POST':
        try:
            lid = request.POST.get('lid')  # Current user's login ID

            # Get all journeys created by this user
            user_journeys = UserJourney.objects.filter(USER__LOGIN_id=lid)

            # Get all requests for these journeys
            requests = Journeyrequest.objects.filter(
                JOURNEY__in=user_journeys
            ).select_related('JOURNEY', 'SENDERID').order_by('-date')

            request_list = []
            for req in requests:
                request_list.append({
                    'id': req.id,
                    'journey': {
                        'id': req.JOURNEY.id,
                        'fromplace': req.JOURNEY.fromplace,
                        'toplace': req.JOURNEY.toplace,
                        'date': req.JOURNEY.date.strftime('%Y-%m-%d'),
                        'time': req.JOURNEY.time.strftime('%H:%M:%S'),
                    },
                    'sender': {
                        'id': req.SENDERID.id,
                        'name': req.SENDERID.name,
                        'phone': req.SENDERID.phone,
                        'email': req.SENDERID.email,
                        'place': req.SENDERID.place,
                        'ulid': req.SENDERID.LOGIN.id,
                    },
                    'status': req.status,
                    'request_date': req.date.strftime('%Y-%m-%d')
                })

            return JsonResponse({
                'status': 'ok',
                'data': request_list,
                'count': len(request_list)
            })

        except Exception as e:
            print(f"❌ Error: {str(e)}")
            return JsonResponse({
                'status': 'error',
                'message': str(e)
            })
    else:
        return JsonResponse({
            'status': 'error',
            'message': 'Only POST method allowed'
        })


# View requests sent by user
@csrf_exempt
def view_sent_requests(request):
    if request.method == 'POST':
        try:
            lid = request.POST.get('lid')  # Current user's login ID

            # Get sender user
            sender = users.objects.get(LOGIN_id=lid)

            # Get all requests sent by this user
            requests = Journeyrequest.objects.filter(
                SENDERID=sender
            ).select_related('JOURNEY', 'JOURNEY__USER').order_by('-date')

            request_list = []
            for req in requests:
                request_list.append({
                    'id': req.id,
                    'journey': {
                        'id': req.JOURNEY.id,
                        'fromplace': req.JOURNEY.fromplace,
                        'toplace': req.JOURNEY.toplace,
                        'date': req.JOURNEY.date.strftime('%Y-%m-%d'),
                        'time': req.JOURNEY.time.strftime('%H:%M:%S'),
                        'owner': {
                            'name': req.JOURNEY.USER.name,
                            'phone': req.JOURNEY.USER.phone,
                        }
                    },
                    'status': req.status,
                    'request_date': req.date.strftime('%Y-%m-%d')
                })

            return JsonResponse({
                'status': 'ok',
                'data': request_list,
                'count': len(request_list)
            })

        except Exception as e:
            print(f"❌ Error: {str(e)}")
            return JsonResponse({
                'status': 'error',
                'message': str(e)
            })
    else:
        return JsonResponse({
            'status': 'error',
            'message': 'Only POST method allowed'
        })


# Update request status (accept/reject)
@csrf_exempt
def update_request_status(request):
    if request.method == 'POST':
        try:
            request_id = request.POST.get('request_id')
            status = request.POST.get('status')  # 'accepted' or 'rejected'
            lid = request.POST.get('lid')  # Journey owner's login ID

            print(f"📝 Updating request {request_id} to {status}")

            # Get request
            journey_request = Journeyrequest.objects.get(id=request_id)

            # Verify that this user owns the journey
            if journey_request.JOURNEY.USER.LOGIN_id != lid:
                return JsonResponse({
                    'status': 'error',
                    'message': 'You are not authorized to update this request'
                })

            # Update status
            journey_request.status = status
            journey_request.save()

            return JsonResponse({
                'status': 'ok',
                'message': f'Request {status} successfully'
            })

        except Journeyrequest.DoesNotExist:
            return JsonResponse({
                'status': 'error',
                'message': 'Request not found'
            })
        except Exception as e:
            print(f"❌ Error: {str(e)}")
            return JsonResponse({
                'status': 'error',
                'message': str(e)
            })
    else:
        return JsonResponse({
            'status': 'error',
            'message': 'Only POST method allowed'
        })


# Delete/cancel request
@csrf_exempt
def delete_request(request):
    if request.method == 'POST':
        try:
            request_id = request.POST.get('request_id')
            lid = request.POST.get('lid')

            # Get request
            journey_request = Journeyrequest.objects.get(id=request_id)

            # Verify that this user sent the request
            if journey_request.SENDERID.LOGIN_id != lid:
                return JsonResponse({
                    'status': 'error',
                    'message': 'You are not authorized to delete this request'
                })

            journey_request.delete()

            return JsonResponse({
                'status': 'ok',
                'message': 'Request cancelled successfully'
            })

        except Journeyrequest.DoesNotExist:
            return JsonResponse({
                'status': 'error',
                'message': 'Request not found'
            })
        except Exception as e:
            print(f"❌ Error: {str(e)}")
            return JsonResponse({
                'status': 'error',
                'message': str(e)
            })
    else:
        return JsonResponse({
            'status': 'error',
            'message': 'Only POST method allowed'
        })


@csrf_exempt
def update_request_status(request):
        # Get data from request
        request_id = request.POST.get('request_id')
        status = request.POST.get('status')  # 'accepted' or 'rejected'
        lid = request.POST.get('lid')  # Journey owner's login ID
        journey_request = Journeyrequest.objects.get(id=request_id)

        journey_request.status = status
        journey_request.save()

        print(f"✅ Request {request_id} {status}ed successfully")

        # Optional: You can add notification logic here
        # For example, send SMS or notification to the sender

        return JsonResponse({'status':'ok'})


@csrf_exempt
def view_sent_requests(request):
    if request.method == 'POST':
        try:
            lid = request.POST.get('lid')  # Current user's login ID

            print(f"📤 Fetching sent requests for user: {lid}")

            if not lid:
                return JsonResponse({
                    'status': 'error',
                    'message': 'User ID required'
                })

            # Get sender user
            try:
                sender = users.objects.get(LOGIN_id=lid)
            except users.DoesNotExist:
                return JsonResponse({
                    'status': 'error',
                    'message': 'User not found'
                })

            # Get all requests sent by this user with related data
            requests = Journeyrequest.objects.filter(
                SENDERID=sender
            ).select_related(
                'JOURNEY',
                'JOURNEY__USER'
            ).order_by('-date', '-id')

            print(f"Found {requests.count()} sent requests")

            request_list = []
            for req in requests:
                request_list.append({
                    'id': req.id,
                    'journey': {
                        'id': req.JOURNEY.id,
                        'fromplace': req.JOURNEY.fromplace,
                        'toplace': req.JOURNEY.toplace,
                        'date': req.JOURNEY.date.strftime('%Y-%m-%d'),
                        'time': req.JOURNEY.time.strftime('%H:%M:%S'),
                        'owner': {
                            'name': req.JOURNEY.USER.name,
                            'phone': req.JOURNEY.USER.phone,
                            'email': req.JOURNEY.USER.email,
                            'place': req.JOURNEY.USER.place,
                            'ulid': req.JOURNEY.USER.LOGIN.id,
                        }
                    },
                    'status': req.status,
                    'request_date': req.date.strftime('%Y-%m-%d')
                })

            return JsonResponse({
                'status': 'ok',
                'data': request_list,
                'count': len(request_list)
            })

        except Exception as e:
            print(f"❌ Error: {str(e)}")
            return JsonResponse({
                'status': 'error',
                'message': str(e)
            })
    else:
        return JsonResponse({
            'status': 'error',
            'message': 'Only POST method allowed'
        })



def chat_send(request):
    FROM_id=request.POST['from_id']
    TOID_id=request.POST['to_id']
    msg=request.POST['message']

    c=Chat()
    c.FROM_id=FROM_id
    c.TO_id=TOID_id
    c.message=msg
    c.date=datetime.datetime.now().date()
    c.save()
    return JsonResponse({'status':"ok"})

def chat_view_and(request):
    from_id=request.POST['from_id']
    to_id=request.POST['to_id']
    l=[]
    data1=Chat.objects.filter(FROM_id=from_id,TO_id=to_id).order_by('id')
    data2=Chat.objects.filter(FROM_id=to_id,TO_id=from_id).order_by('id')

    data= data1 | data2
    print(data)

    for res in data:
        l.append({'id':res.id,'from':res.FROM.id,'to':res.TO.id,'msg':res.message,'date':res.date})

    return JsonResponse({'status':"ok",'data':l})



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

#
# def sos_alert(request):
#     """
#     Receive SOS alert from mobile app and save to database
#     """
#     if request.method == 'POST':
#         try:
#             # Get data from request
#             lid = request.POST.get('lid')
#             phone_numbers = request.POST.get('phone_numbers')  # Optional
#             latitude = request.POST.get('latitude')
#             longitude = request.POST.get('longitude')
#             timestamp = request.POST.get('timestamp')  # Optional
#
#             print(f"🚨 SOS ALERT RECEIVED")
#             print(f"User LID: {lid}")
#             print(f"Location: {latitude}, {longitude}")
#
#             # Validation
#             if not all([lid, latitude, longitude]):
#                 return JsonResponse({
#                     'status': 'error',
#                     'message': 'lid, latitude and longitude are required'
#                 })
#
#             # Try to get user object (optional)
#             user = None
#             try:
#                 user = users.objects.get(LOGIN_id=lid)
#             except users.DoesNotExist:
#                 print(f"User not found for LID: {lid}")
#
#             # Create SOS alert in database
#             sos_alert = SOSAlert.objects.create(
#                 user=user,
#
#                 latitude=latitude,
#                 longitude=longitude,
#                 status='active'  # Default status
#             )
#
#
#
#
#             print(f"✅ SOS Alert saved with ID: {sos_alert.id}")
#
#             return JsonResponse({
#                 'status': 'ok',
#                 'message': 'SOS alert saved successfully',
#                 'alert_id': sos_alert.id,
#                 'timestamp': sos_alert.timestamp.strftime('%Y-%m-%d %H:%M:%S')
#             })
#
#         except Exception as e:
#             print(f"❌ Error saving SOS: {str(e)}")
#             return JsonResponse({
#                 'status': 'error',
#                 'message': str(e)
#             })
#     else:
#         return JsonResponse({
#             'status': 'error',
#             'message': 'Only POST method allowed'
#         })





import smtplib
import ssl
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from .models import SOSAlert, users, Emergency_contact

# Email configuration
SMTP_SERVER = "smtp.gmail.com"
SMTP_PORT = 587
SENDER_EMAIL = "trainingstarted@gmail.com"
APP_PASSWORD = "nlxasujxgazlbmgz"  # Use App Password, not regular password


def send_emergency_email(contact_name, contact_email, user_name, latitude, longitude, timestamp):
    """Send emergency email to a contact"""
    try:
        # Create email content
        subject = f"🚨 EMERGENCY SOS ALERT - {user_name}"

        # Google Maps link
        maps_link = f"https://www.google.com/maps?q={latitude},{longitude}"

        body = f"""
        <html>
        <body style="font-family: Arial, sans-serif; padding: 20px;">
            <div style="background-color: #ffebee; border-left: 6px solid #f44336; padding: 20px; border-radius: 5px;">
                <h2 style="color: #d32f2f; margin-top: 0;">🚨 EMERGENCY SOS ALERT</h2>

                <p><strong>Dear {contact_name},</strong></p>

                <p>This is an automated emergency alert from <strong>{user_name}</strong>.</p>

                <div style="background-color: white; padding: 15px; border-radius: 5px; margin: 15px 0;">
                    <h3 style="color: #333; margin-top: 0;">📍 Location Details:</h3>
                    <p><strong>Latitude:</strong> {latitude}</p>
                    <p><strong>Longitude:</strong> {longitude}</p>
                    <p><strong>Time:</strong> {timestamp}</p>

                    <p style="margin-top: 15px;">
                        <a href="{maps_link}" 
                           style="background-color: #4CAF50; color: white; padding: 10px 20px; 
                                  text-decoration: none; border-radius: 5px; display: inline-block;">
                           📱 View on Google Maps
                        </a>
                    </p>
                </div>

                <p><strong>⚠️ Please contact them immediately or alert authorities if needed.</strong></p>

                <hr style="border: 1px solid #eee; margin: 20px 0;">

                <p style="color: #666; font-size: 12px;">
                    This is an automated emergency message from the SheCare Safety App.<br>
                    Please do not reply to this email.
                </p>
            </div>
        </body>
        </html>
        """

        # Create message
        message = MIMEMultipart("alternative")
        message["From"] = SENDER_EMAIL
        message["To"] = contact_email
        message["Subject"] = subject

        # Attach HTML content
        message.attach(MIMEText(body, "html"))

        # Also attach plain text version for email clients that don't support HTML
        plain_text = f"""
        🚨 EMERGENCY SOS ALERT

        Dear {contact_name},

        This is an automated emergency alert from {user_name}.

        Location:
        Latitude: {latitude}
        Longitude: {longitude}
        Time: {timestamp}

        View on Google Maps: {maps_link}

        ⚠️ Please contact them immediately or alert authorities if needed.

        This is an automated message from the SheCare Safety App.
        """
        message.attach(MIMEText(plain_text, "plain"))

        # Send email
        context = ssl.create_default_context()
        server = smtplib.SMTP(SMTP_SERVER, SMTP_PORT)
        server.starttls(context=context)
        server.login(SENDER_EMAIL, APP_PASSWORD)
        server.send_message(message)
        server.quit()

        print(f"✅ Emergency email sent to {contact_name} at {contact_email}")
        return True

    except Exception as e:
        print(f"❌ Failed to send email to {contact_email}: {str(e)}")
        return False


@csrf_exempt
def sos_alert(request):
    """
    Receive SOS alert from mobile app, save to database, and notify emergency contacts
    """
    if request.method == 'POST':
        try:
            # Get data from request
            lid = request.POST.get('lid')
            phone_numbers = request.POST.get('phone_numbers')  # Optional
            latitude = request.POST.get('latitude')
            longitude = request.POST.get('longitude')
            timestamp = request.POST.get('timestamp')  # Optional

            print(f"🚨 SOS ALERT RECEIVED")
            print(f"User LID: {lid}")
            print(f"Location: {latitude}, {longitude}")

            # Validation
            if not all([lid, latitude, longitude]):
                return JsonResponse({
                    'status': 'error',
                    'message': 'lid, latitude and longitude are required'
                })

            # Try to get user object (optional)
            user = None
            user_name = "Unknown User"
            try:
                user = users.objects.get(LOGIN_id=lid)
                user_name = user.name
                print(f"✅ User found: {user_name}")
            except users.DoesNotExist:
                print(f"User not found for LID: {lid}")

            # Create SOS alert in database
            sos_alert = SOSAlert.objects.create(
                user=user,
                latitude=latitude,
                longitude=longitude,
                timestamp=datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
                status='active'  # Default status
            )

            print(f"✅ SOS Alert saved with ID: {sos_alert.id}")

            # Get emergency contacts for this user
            emergency_contacts = []
            if user:
                emergency_contacts = Emergency_contact.objects.filter(USER=user)
                print(f"📞 Found {emergency_contacts.count()} emergency contacts")

            # Send emails to all emergency contacts
            email_results = []
            for contact in emergency_contacts:
                if contact.email and contact.email.strip():  # Only if email exists
                    success = send_emergency_email(
                        contact_name=contact.name,
                        contact_email=contact.email,
                        user_name=user_name,
                        latitude=latitude,
                        longitude=longitude,
                        timestamp=sos_alert.timestamp
                    )
                    email_results.append({
                        'name': contact.name,
                        'email': contact.email,
                        'sent': success
                    })

            # Prepare response
            response_data = {
                'status': 'ok',
                'message': 'SOS alert saved successfully',
                'alert_id': sos_alert.id,
                'timestamp': sos_alert.timestamp,
                'emergency_contacts_notified': len(email_results)
            }

            # Add email results to response (optional)
            response_data['email_results'] = email_results

            return JsonResponse(response_data)

        except Exception as e:
            print(f"❌ Error saving SOS: {str(e)}")
            return JsonResponse({
                'status': 'error',
                'message': str(e)
            })
    else:
        return JsonResponse({
            'status': 'error',
            'message': 'Only POST method allowed'
        })


################# police verify dangerspot ########



def pol_view_users_addded_dangerous_spot(request):
        # Filter only spots where type is "users"
        # spots = dangerous_spot.objects.filter(type='users').select_related('LOGIN')
        radius = float(request.POST.get('radius', 2))  # km

        # user current location
        try:
            current_loc = Location.objects.filter(LOGIN_id=request.user.id).latest('id')
        except Location.DoesNotExist:
            return JsonResponse({"status": "error", "message": "User location not found"})

        pol_lat = float(current_loc.latitude)
        pol_lon = float(current_loc.longitude)


        points = dangerous_spot.objects.filter(status__icontains="pending").select_related('LOGIN')
        spot_data=[]
        for p in points:
            if not p.latitude or not p.longitude:
                continue

            distance_km = haversine(
                pol_lat, pol_lon,
                float(p.latitude), float(p.longitude)
            )

            # ✅ FIX HERE
            if distance_km <= radius:

                spot_data.append({
                    'id': p.id,
                    'place_name': p.place_name,
                    'latitude': p.latitude,
                    'longitude': p.longitude,
                    'status': p.status,
                    'type': p.type,
                    'user_name': p.LOGIN.username if p.LOGIN else 'Unknown',
                    'user_email': p.LOGIN.email if p.LOGIN else '',
                })

        return render(
            request,
            "police_station/users_add_view_dangerous_spot.html",
            {'data': spot_data}
        )


# Approve dangerous spot
from django.shortcuts import render, redirect, get_object_or_404
from django.contrib import messages
from .models import dangerous_spot, users


# def pol_approve_dangerous_spot(request, spot_id):
#     try:
#         # Get the spot
#         spot = get_object_or_404(dangerous_spot, id=spot_id)
#
#         # Get the user who added this spot
#         user = spot.LOGIN
#
#         # Update spot status
#         spot.status = 'verified'
#         spot.save()
#
#         # First, get current credit score from blockchain
#         current_user_data = get_user_credit_score(user.username)
#
#         if current_user_data:
#             # User exists in blockchain
#             current_score = current_user_data['credit_score']
#             current_spots = current_user_data['total_spots']
#             new_score = current_score + 10
#             new_spots = current_spots + 1
#
#             print(f"📊 User {user.username}: Blockchain score {current_score} -> {new_score}")
#         else:
#             # New user in blockchain
#             current_score = 0
#             current_spots = 0
#             new_score = 10
#             new_spots = 1
#
#             print(f"📊 User {user.username}: New user in blockchain, score: {new_score}")
#
#         # Update blockchain
#         tx_hash = update_user_credit_score(
#             user.username,
#             new_score,
#             new_spots
#         )
#
#         if tx_hash:
#             messages.success(
#                 request,
#                 f'✅ Verified "{spot.place_name}". '
#                 f'{user.username} earned 10 points! '
#                 f'Total blockchain score: {new_score} | TX: {tx_hash[:10]}...'
#             )
#         else:
#             messages.warning(
#                 request,
#                 f'⚠️ Verified "{spot.place_name}" but blockchain update failed.'
#             )
#
#     except Exception as e:
#         print(f"❌ Error: {str(e)}")
#         messages.error(request, f'Error: {str(e)}')
#
#
#     return redirect('pol_view_users_addded_dangerous_spot/')



def pol_approve_dangerous_spot(request, spot_id):
        # Get the spot
    spot = get_object_or_404(dangerous_spot, id=spot_id)
    print(f"📍 Approving spot: {spot.place_name} (ID: {spot_id})")

    # Get the user who added this spot
    user = spot.LOGIN
    print(f"👤 User: {user.username} (ID: {user.id})")

    # Update spot status
    spot.status = 'verified'
    spot.save()
    print(f"✅ Spot status updated to verified")

    # First, get current credit score from blockchain
    print(f"🔍 Checking blockchain for user: {user.username}")
    current_user_data = get_user_credit_score(user.username)
    print(f"📊 Blockchain response: {current_user_data}")

    if current_user_data:
        # User exists in blockchain
        current_score = current_user_data['credit_score']
        current_spots = current_user_data['total_spots']
        new_score = current_score + 10
        new_spots = current_spots + 1
        print(f"📊 User exists: Current score={current_score}, New score={new_score}")
    else:
        # New user in blockchain
        current_score = 0
        current_spots = 0
        new_score = 10
        new_spots = 1
        print(f"📊 New user: Setting score to {new_score}")

    # Update blockchain
    print(f"🚀 Updating blockchain: username={user.username}, score={new_score}, spots={new_spots}")
    tx_hash = update_user_credit_score(
        user.username,
        new_score,
        new_spots
    )
    print(f"📝 Transaction hash: {tx_hash}")

    if tx_hash:
        messages.success(
            request,
            f'✅ Verified "{spot.place_name}". '
            f'{user.username} earned 10 points! '
            f'Total blockchain score: {new_score} | TX: {tx_hash[:10]}...'
        )
        print(f"✅ Success! New score: {new_score}")
    else:
        messages.warning(
            request,
            f'⚠️ Verified "{spot.place_name}" but blockchain update failed.'
        )
        print(f"❌ Blockchain update failed!")

    return HttpResponse(
            "<script>alert('Approved');window.location='/police_home#content';</script>")


# Reject dangerous spot
def pol_reject_dangerous_spot(request, spot_id):
        spot=dangerous_spot.objects.get(id=spot_id)
        # Update status to rejected
        spot.status = 'rejected'
        spot.save()

        # Success message
        messages.success(request, f'Successfully rejected "{spot.place_name}".')
        return HttpResponse(
            "<script>alert('Rejected');window.location='/police_home#content';</script>")


# user view ############################################


from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
# from .web3_config import get_user_credit_score, get_all_users_with_scores
import json


@csrf_exempt
def get_user_blockchain_score(request):
    """Get user's credit score from blockchain"""
    if request.method == 'POST':
        try:
            # Get username from request
            username = request.POST.get('username')

            if not username:
                return JsonResponse({
                    'status': 'error',
                    'message': 'Username is required'
                })

            # Get user data from blockchain
            user_data = get_user_credit_score(username)

            if user_data:
                return JsonResponse({
                    'status': 'success',
                    'data': {
                        'user_id': user_data['user_id'],
                        'username': user_data['username'],
                        'credit_score': user_data['credit_score'],
                        'total_spots': user_data['total_spots'],
                        'last_updated': user_data['last_updated'],
                    }
                })
            else:
                # User not found in blockchain - return default values
                return JsonResponse({
                    'status': 'success',
                    'data': {
                        'username': username,
                        'credit_score': 0,
                        'total_spots': 0,
                        'message': 'New user - no blockchain record yet'
                    }
                })

        except Exception as e:
            print(f"❌ Error in get_user_blockchain_score: {str(e)}")
            return JsonResponse({
                'status': 'error',
                'message': str(e)
            })
    else:
        return JsonResponse({
            'status': 'error',
            'message': 'Only POST method allowed'
        })


@csrf_exempt
def get_user_score_by_lid(request):
    """Get user's credit score using lid (login ID)"""
    if request.method == 'POST':
        try:
            lid = request.POST.get('lid')
            print(f"🔍 Received request for lid: {lid}")

            if not lid:
                return JsonResponse({
                    'status': 'error',
                    'message': 'User ID is required'
                })

            # Get username from database using lid
            from .models import users
            try:
                user = users.objects.get(LOGIN_id=lid)
                username = user.email  # or user.username depending on your field
                print(f"👤 Found user: {username}")
            except users.DoesNotExist:
                print(f"❌ User not found for lid: {lid}")
                return JsonResponse({
                    'status': 'error',
                    'message': 'User not found'
                })

            # Get user data from blockchain
            print(f"🔍 Fetching blockchain data for username: {username}")
            user_data = get_user_credit_score(username)
            print(f"📊 Blockchain data: {user_data}")

            if user_data:
                return JsonResponse({
                    'status': 'success',
                    'data': {
                        'user_id': user_data['user_id'],
                        'username': user_data['username'],
                        'credit_score': user_data['credit_score'],
                        'total_spots': user_data['total_spots'],
                        'last_updated': user_data['last_updated'],
                    }
                })
            else:
                # User not found in blockchain
                return JsonResponse({
                    'status': 'success',
                    'data': {
                        'username': username,
                        'credit_score': 0,
                        'total_spots': 0,
                        'message': 'User not found in blockchain'
                    }
                })

        except Exception as e:
            print(f"❌ Error: {str(e)}")
            return JsonResponse({
                'status': 'error',
                'message': str(e)
            })
    else:
        return JsonResponse({
            'status': 'error',
            'message': 'Only POST method allowed'
        })

######################prediction ###############




import os
import joblib
import pandas as pd
import numpy as np
from django.shortcuts import render
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.conf import settings
import json

# Load model at startup
MODEL_PATH = os.path.join(settings.BASE_DIR, 'myapp', 'safety_model.pkl')
ENCODERS_PATH = os.path.join(settings.BASE_DIR, 'myapp', 'label_encoders.pkl')

# Global variables for model and encoders
model = None
label_encoders = None
target_encoder = None
feature_columns = None


def load_model():
    """Load the trained model and encoders"""
    global model, label_encoders, target_encoder, feature_columns

    try:
        # Load model
        model = joblib.load(MODEL_PATH)

        # Load encoders
        encoders_data = joblib.load(ENCODERS_PATH)
        label_encoders = encoders_data['label_encoders']
        target_encoder = encoders_data['target_encoder']
        feature_columns = encoders_data['feature_columns']

        print("✅ Model loaded successfully")
        print(f"📊 Features: {feature_columns}")
        print(f"🎯 Target classes: {list(target_encoder.classes_)}")
        return True
    except Exception as e:
        print(f"❌ Error loading model: {e}")
        return False


# Load model when Django starts
load_model()


@csrf_exempt
def predict_safety(request):
    """API endpoint for safety prediction"""
    if request.method == 'POST':
        try:
            # Get features from request
            data = json.loads(request.body) if request.body else request.POST

            lati= float(data.get('lati'))
            logi= float(data.get('logi'))


            print(f"Current location : http://maps.google.com/?q={lati},{logi}")
            time_of_day, lighting = get_time_and_lighting()
            day_of_week = datetime.datetime.now().strftime('%A')

            # Check known locations first
            known = check_known_location(lati, logi)
            if known:
                area        = known['area']
                zone        = known['zone']
                tier        = known['tier']
                residence   = known['residence_level']
                is_police   = known['is_police']
                is_bar      = known['is_bar']
                matched_name= known['name']

                # Smart people frequency — override based on time for some locations
                hour = datetime.datetime.now().hour
                if known['name'] == 'Andamkovval':
                    # Busy in morning (shops open), quiet at night
                    if 6 <= hour < 12:
                        people_freq = 'High'    # morning shops busy
                    elif 12 <= hour < 18:
                        people_freq = 'Medium'  # afternoon moderate
                    else:
                        people_freq = 'Low'     # night quiet residential
                else:
                    people_freq = known['people_frequency']

                features = {
                    'Area':             area,
                    'Zone':             zone,
                    'Time':             time_of_day,
                    'People.Frequency': people_freq,
                    'Is.Police_Station':is_police,
                    'Is.Bar':           is_bar,
                    'Tier':             tier,
                    'Residence.Level':  residence,
                    'Day_of_Week':      day_of_week,
                    'Lighting':         lighting,
                }
                print(f"📊 Features: {features}")

            else:
                area, zone, tier = get_area_zone(lati, logi)
                residence = 'Medium'
                is_police, is_bar, people_freq = get_nearby_places(lati, logi)

                # Extract features
                features = {
                    'Area': area,
                    'Zone': zone,
                    'Time': time_of_day,
                    'People.Frequency': people_freq,
                    'Is.Police_Station': is_police,
                    'Is.Bar': is_bar,
                    'Tier': tier,
                    'Residence.Level': residence,
                    'Day_of_Week': day_of_week,
                    'Lighting': lighting
                }

                print(f"📥 Received prediction request: {features}")

            # Validate features
            missing = [k for k, v in features.items() if v is None]
            if missing:
                return JsonResponse({
                    'status': 'error',
                    'message': f'Missing features: {missing}'
                })

            # Convert to DataFrame
            df = pd.DataFrame([features])

            # Encode categorical features
            for column in feature_columns:
                if column in label_encoders:
                    try:
                        df[column] = label_encoders[column].transform([str(df[column].iloc[0])])[0]
                    except:
                        # Use most common class if value not seen
                        df[column] = 0

            # Ensure correct feature order
            df = df[feature_columns]

            # Predict
            prediction_encoded = model.predict(df)[0]
            probabilities = model.predict_proba(df)[0]

            # Decode prediction
            prediction = target_encoder.inverse_transform([prediction_encoded])[0]

            # Get confidence
            prob_index = list(target_encoder.classes_).index(prediction)
            confidence = probabilities[prob_index]

            # Prepare response
            response = {
                'status': 'success',
                'prediction': prediction,
                'confidence': float(confidence),
                'probabilities': {
                    class_name: float(prob)
                    for class_name, prob in zip(target_encoder.classes_, probabilities)
                },
                'input_features': features
            }

            print(f"✅ Prediction: {prediction} (Confidence: {confidence:.2%})")
            return JsonResponse(response)

        except Exception as e:
            print(f"❌ Prediction error: {e}")
            return JsonResponse({
                'status': 'error',
                'message': str(e)
            })

    return JsonResponse({
        'status': 'error',
        'message': 'Only POST method allowed'
    })


@csrf_exempt
def get_feature_options(request):
    """Get all possible values for categorical features"""
    if request.method == 'GET':
        try:
            options = {}
            for column, encoder in label_encoders.items():
                options[column] = encoder.classes_.tolist()

            return JsonResponse({
                'status': 'success',
                'options': options,
                'target_classes': target_encoder.classes_.tolist()
            })
        except Exception as e:
            return JsonResponse({
                'status': 'error',
                'message': str(e)
            })

    return JsonResponse({
        'status': 'error',
        'message': 'Only GET method allowed'
    })


@csrf_exempt
def retrain_model(request):
    """API to retrain the model with new data"""
    if request.method == 'POST':
        try:
            from .ml_model import train_and_save_model

            predictor, accuracy = train_and_save_model()

            # Reload model
            load_model()

            return JsonResponse({
                'status': 'success',
                'message': 'Model retrained successfully',
                'accuracy': float(accuracy)
            })
        except Exception as e:
            return JsonResponse({
                'status': 'error',
                'message': str(e)
            })

    return JsonResponse({
        'status': 'error',
        'message': 'Only POST method allowed'
    })



######################### sos alert #############




from django.shortcuts import get_object_or_404
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.utils import timezone
from .models import SOSAlert, users
import json


@csrf_exempt
def get_user_sos_alerts(request):
    """Get all SOS alerts for a specific user"""
    if request.method == 'POST':
        try:
            lid = request.POST.get('lid')

            if not lid:
                return JsonResponse({
                    'status': 'error',
                    'message': 'User ID required'
                })

            # Get user
            try:
                user = users.objects.get(LOGIN_id=lid)
            except users.DoesNotExist:
                return JsonResponse({
                    'status': 'error',
                    'message': 'User not found'
                })

            # Get all SOS alerts for this user
            alerts = SOSAlert.objects.filter(user=user).order_by('-timestamp')

            alert_list = []
            for alert in alerts:
                alert_list.append({
                    'id': alert.id,
                    'latitude': alert.latitude,
                    'longitude': alert.longitude,
                    'timestamp': alert.timestamp.strftime('%Y-%m-%d %H:%M:%S'),
                    'status': alert.status,
                    'google_maps_link': f"https://www.google.com/maps?q={alert.latitude},{alert.longitude}"
                })

            return JsonResponse({
                'status': 'success',
                'data': alert_list,
                'count': len(alert_list)
            })

        except Exception as e:
            print(f"❌ Error: {str(e)}")
            return JsonResponse({
                'status': 'error',
                'message': str(e)
            })

    return JsonResponse({
        'status': 'error',
        'message': 'Only POST method allowed'
    })


@csrf_exempt
def delete_sos_alert(request, alert_id):

    alert_id=alert_id
    ss=SOSAlert.objects.filter(id=alert_id).delete()

    return JsonResponse({
                'status': 'success',
                'message': 'SOS alert deleted successfully',
                'deleted_id': alert_id
            })




@csrf_exempt
def resolve_sos_alert(request, alert_id):
    """Mark SOS alert as resolved"""
    if request.method == 'POST':
        try:
            lid = request.POST.get('lid')

            if not lid:
                return JsonResponse({
                    'status': 'error',
                    'message': 'User ID required'
                })

            # Get the alert
            alert = get_object_or_404(SOSAlert, id=alert_id)

            # Check ownership
            if alert.user and alert.user.LOGIN_id != lid:
                return JsonResponse({
                    'status': 'error',
                    'message': 'You are not authorized to modify this alert'
                })

            # Update status
            alert.status = 'resolved'
            alert.save()

            return JsonResponse({
                'status': 'success',
                'message': 'SOS alert marked as resolved',
                'alert_id': alert.id
            })

        except SOSAlert.DoesNotExist:
            return JsonResponse({
                'status': 'error',
                'message': 'Alert not found'
            })
        except Exception as e:
            return JsonResponse({
                'status': 'error',
                'message': str(e)
            })

    return JsonResponse({
        'status': 'error',
        'message': 'Only POST method allowed'
    })


@csrf_exempt
def get_sos_alert_details(request, alert_id):
    """Get details of a specific SOS alert"""
    if request.method == 'GET':
        try:
            alert = get_object_or_404(SOSAlert, id=alert_id)

            data = {
                'id': alert.id,
                'latitude': alert.latitude,
                'longitude': alert.longitude,
                'timestamp': alert.timestamp.strftime('%Y-%m-%d %H:%M:%S'),
                'status': alert.status,
                'user_name': alert.user.name if alert.user else 'Unknown',
                'user_email': alert.user.email if alert.user else '',
                'google_maps_link': f"https://www.google.com/maps?q={alert.latitude},{alert.longitude}"
            }

            return JsonResponse({
                'status': 'success',
                'data': data
            })

        except SOSAlert.DoesNotExist:
            return JsonResponse({
                'status': 'error',
                'message': 'Alert not found'
            })
        except Exception as e:
            return JsonResponse({
                'status': 'error',
                'message': str(e)
            })

    return JsonResponse({
        'status': 'error',
        'message': 'Only GET method allowed'
    })

################### police_view_sos ####################

from math import radians, sin, cos, sqrt, atan2
from django.contrib import messages
from django.shortcuts import render, redirect, get_object_or_404
from .models import SOSAlert, police_station, Location, users


# Helper function to calculate distance between two coordinates
def calculate_distance(lat1, lon1, lat2, lon2):
    """Calculate distance between two points in kilometers using Haversine formula"""
    try:
        R = 6371  # Earth's radius in kilometers

        # Convert to float
        lat1, lon1, lat2, lon2 = float(lat1), float(lon1), float(lat2), float(lon2)

        # Convert to radians
        lat1_rad = radians(lat1)
        lon1_rad = radians(lon1)
        lat2_rad = radians(lat2)
        lon2_rad = radians(lon2)

        # Haversine formula
        dlat = lat2_rad - lat1_rad
        dlon = lon2_rad - lon1_rad
        a = sin(dlat / 2) ** 2 + cos(lat1_rad) * cos(lat2_rad) * sin(dlon / 2) ** 2
        c = 2 * atan2(sqrt(a), sqrt(1 - a))
        distance = R * c

        return round(distance, 2)  # Return distance in km with 2 decimal places
    except (ValueError, TypeError) as e:
        print(f"Error calculating distance: {e}")
        return 999.99  # Return large distance on error


# def police_view_nearby_sos_alerts(request):
#     """View for police officer to see SOS alerts sorted by distance"""
#     # Get logged in police officer ID from session
#     lid = request.user.id
#
#     try:
#         # Get police officer details
#         officer = police_officers.objects.get(LOGIN_id=lid)
#         station = officer.STATION  # Get the police station this officer belongs to
#     except police_officers.DoesNotExist:
#         messages.error(request, 'Police officer not found')
#         return redirect('police_login')
#
#     # Get police officer's location from Location table
#     try:
#         officer_location = Location.objects.get(LOGIN_id=lid)
#         officer_lat = officer_location.latitude
#         officer_lon = officer_location.longitude
#     except Location.DoesNotExist:
#         messages.error(request, 'Your location not found. Please update your location first.')
#         return redirect('police_officer_update_location')
#
#     # Get all SOS alerts (active and resolved)
#     sos_alerts = SOSAlert.objects.all().order_by('-timestamp')
#
#     # Calculate distance for each alert and add to list
#     alerts_with_distance = []
#     for alert in sos_alerts:
#         # Calculate distance from police officer to alert location
#         distance = calculate_distance(
#             officer_lat, officer_lon,
#             alert.latitude, alert.longitude
#         )
#
#         # Get user details if available
#         user_name = "Unknown"
#         user_phone = ""
#         if alert.user:
#             user_name = alert.user.name
#             user_phone = alert.user.phone
#
#         # Create alert dictionary with all details
#         alert_data = {
#             'id': alert.id,
#             'user_name': user_name,
#             'user_phone': user_phone,
#             'latitude': alert.latitude,
#             'longitude': alert.longitude,
#             'timestamp': alert.timestamp,
#             'distance': round(distance, 2),
#             'status': alert.status,
#             'google_maps_link': f"https://www.google.com/maps?q={alert.latitude},{alert.longitude}"
#         }
#         alerts_with_distance.append(alert_data)
#
#     # Sort alerts by distance (nearest first)
#     alerts_with_distance.sort(key=lambda x: x['distance'])
#
#     # Count statistics
#     total_active = len([a for a in alerts_with_distance if a['status'] == 'active'])
#     total_resolved = len([a for a in alerts_with_distance if a['status'] == 'resolved'])
#     nearby_active = len([a for a in alerts_with_distance if a['distance'] <= 5 and a['status'] == 'active'])
#
#     context = {
#         'alerts': alerts_with_distance,
#         'officer_name': officer.name,
#         'station_name': station.name if station else 'Unknown Station',
#         'officer_lat': officer_lat,
#         'officer_lon': officer_lon,
#         'total_alerts': len(alerts_with_distance),
#         'total_active': total_active,
#         'total_resolved': total_resolved,
#         'nearby_active': nearby_active,
#     }
#
#     return render(request, 'police_station/police_nearby_sos.html', context)


def police_view_nearby_sos_alerts(request):
    """View for police officer to see only nearby SOS alerts"""

    lid = request.user.id

    try:
        officer = police_officers.objects.get(LOGIN_id=lid)
        station = officer.STATION
    except police_officers.DoesNotExist:
        messages.error(request, 'Police officer not found')
        return redirect('police_login')

    # Get latest police location
    try:
        officer_location = Location.objects.filter(LOGIN_id=lid).last()

        if not officer_location:
            messages.error(request, 'Your location not found')
            return redirect('police_officer_update_location')

        officer_lat = float(officer_location.latitude)
        officer_lon = float(officer_location.longitude)

    except:
        messages.error(request, 'Location error')
        return redirect('police_officer_update_location')

    # Only ACTIVE alerts
    sos_alerts = SOSAlert.objects.filter(status='active').order_by('-timestamp')

    alerts_with_distance = []

    for alert in sos_alerts:

        distance = calculate_distance(
            officer_lat, officer_lon,
            float(alert.latitude), float(alert.longitude)
        )

        # 🔴 Only alerts within 5km
        if distance <= 5:

            user_name = "Unknown"
            user_phone = ""

            if alert.user:
                user_name = alert.user.name
                user_phone = alert.user.phone

            alert_data = {
                'id': alert.id,
                'user_name': user_name,
                'user_phone': user_phone,
                'latitude': alert.latitude,
                'longitude': alert.longitude,
                'timestamp': alert.timestamp,
                'distance': round(distance, 2),
                'status': alert.status,
                'google_maps_link': f"https://www.google.com/maps?q={alert.latitude},{alert.longitude}"
            }

            alerts_with_distance.append(alert_data)

    # Sort by nearest
    alerts_with_distance.sort(key=lambda x: x['distance'])

    context = {
        'alerts': alerts_with_distance,
        'officer_name': officer.name,
        'station_name': station.name if station else 'Unknown Station',
        'officer_lat': officer_lat,
        'officer_lon': officer_lon,
        'total_alerts': len(alerts_with_distance),
    }

    return render(request, 'police_station/police_nearby_sos.html', context)




def update_sos_status(request, alert_id):
    """Update SOS alert status"""
    # Change this line: Remove POST restriction
    # if request.method == 'POST':  # Remove this

    try:
        alert = get_object_or_404(SOSAlert, id=alert_id)
        # Get status from GET parameters (since you're using GET links)
        new_status = request.GET.get('status', 'resolved')
        alert.status = new_status
        alert.save()
        messages.success(request, f'SOS Alert #{alert_id} marked as {new_status}')
    except Exception as e:
        messages.error(request, f'Error: {str(e)}')

    return redirect('police_view_nearby_sos_alerts')


def get_nearby_sos_api(request):
    """API endpoint to get nearby SOS alerts in JSON format"""
    lid = request.session.get('lid')

    try:
        # Get police station location
        station_location = Location.objects.get(LOGIN_id=lid)
        station_lat = station_location.latitude
        station_lon = station_location.longitude

        # Get radius from request (default 10km)
        radius = float(request.GET.get('radius', 10))

        # Get all active SOS alerts
        sos_alerts = SOSAlert.objects.filter(status='active')

        nearby_alerts = []
        for alert in sos_alerts:
            distance = calculate_distance(
                station_lat, station_lon,
                alert.latitude, alert.longitude
            )

            if distance <= radius:
                user_name = "Unknown"
                if alert.user:
                    user_name = alert.user.name

                nearby_alerts.append({
                    'id': alert.id,
                    'user_name': user_name,
                    'latitude': alert.latitude,
                    'longitude': alert.longitude,
                    'distance': distance,
                    'timestamp': alert.timestamp.strftime('%Y-%m-%d %H:%M:%S'),
                    'status': alert.status,
                })

        # Sort by distance
        nearby_alerts.sort(key=lambda x: x['distance'])

        return JsonResponse({
            'status': 'success',
            'alerts': nearby_alerts,
            'count': len(nearby_alerts)
        })

    except Exception as e:
        return JsonResponse({
            'status': 'error',
            'message': str(e)
        }, status=500)


def police_update_location(request):
    """View for police station to update their location"""
    lid = request.session.get('lid')

    if request.method == 'POST':
        latitude = request.POST.get('latitude')
        longitude = request.POST.get('longitude')

        try:
            location, created = Location.objects.update_or_create(
                LOGIN_id=lid,
                defaults={
                    'latitude': latitude,
                    'longitude': longitude
                }
            )
            messages.success(request, 'Location updated successfully')
            return redirect('police_view_nearby_sos_alerts')
        except Exception as e:
            messages.error(request, f'Error updating location: {str(e)}')

    return render(request, 'police_station/update_location.html')


from django.shortcuts import get_object_or_404
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from .models import Emergency_contact, users
import json


@csrf_exempt
def add_emergency_contact(request):
    """Add new emergency contact for user"""
    if request.method == 'POST':
        try:
            # Get data from request
            lid = request.POST.get('lid')
            name = request.POST.get('name')
            email = request.POST.get('email')
            phone = request.POST.get('phone')

            print(f"📝 Adding emergency contact for lid: {lid}")
            print(f"Name: {name}, Email: {email}, Phone: {phone}")

            # Validation
            if not all([lid, name, phone]):
                return JsonResponse({
                    'status': 'error',
                    'message': 'LID, name and phone are required'
                })

            # Get user
            try:
                user = users.objects.get(LOGIN_id=lid)
            except users.DoesNotExist:
                return JsonResponse({
                    'status': 'error',
                    'message': 'User not found'
                })

            # Check if contact already exists with same phone
            existing = Emergency_contact.objects.filter(USER=user, phone=phone).first()
            if existing:
                return JsonResponse({
                    'status': 'error',
                    'message': 'Contact with this phone number already exists'
                })

            # Create contact
            contact = Emergency_contact.objects.create(
                name=name,
                email=email,
                phone=phone,
                USER=user
            )

            return JsonResponse({
                'status': 'success',
                'message': 'Emergency contact added successfully',
                'contact': {
                    'id': contact.id,
                    'name': contact.name,
                    'email': contact.email,
                    'phone': contact.phone
                }
            })

        except Exception as e:
            print(f"❌ Error: {str(e)}")
            return JsonResponse({
                'status': 'error',
                'message': str(e)
            })

    return JsonResponse({
        'status': 'error',
        'message': 'Only POST method allowed'
    })


@csrf_exempt
def get_emergency_contacts(request):
    """Get all emergency contacts for a user"""
    if request.method == 'POST':
        try:
            lid = request.POST.get('lid')

            if not lid:
                return JsonResponse({
                    'status': 'error',
                    'message': 'User ID required'
                })

            # Get user
            try:
                user = users.objects.get(LOGIN_id=lid)
            except users.DoesNotExist:
                return JsonResponse({
                    'status': 'error',
                    'message': 'User not found'
                })

            # Get contacts
            contacts = Emergency_contact.objects.filter(USER=user).order_by('name')

            contact_list = []
            for contact in contacts:
                contact_list.append({
                    'id': contact.id,
                    'name': contact.name,
                    'email': contact.email,
                    'phone': contact.phone,
                })

            return JsonResponse({
                'status': 'success',
                'data': contact_list,
                'count': len(contact_list)
            })

        except Exception as e:
            print(f"❌ Error: {str(e)}")
            return JsonResponse({
                'status': 'error',
                'message': str(e)
            })

    return JsonResponse({
        'status': 'error',
        'message': 'Only POST method allowed'
    })


@csrf_exempt
def delete_emergency_contact(request, contact_id):
    """Delete an emergency contact"""
    if request.method == 'POST':
        try:
            lid = request.POST.get('lid')

            if not lid:
                return JsonResponse({
                    'status': 'error',
                    'message': 'User ID required'
                })

            # Get contact and verify ownership
            contact = get_object_or_404(Emergency_contact, id=contact_id)

            # Check if this contact belongs to the user
            if contact.USER.LOGIN_id != int(lid):
                return JsonResponse({
                    'status': 'error',
                    'message': 'You are not authorized to delete this contact'
                })

            # Store info before deletion
            contact_name = contact.name

            # Delete the contact
            contact.delete()

            return JsonResponse({
                'status': 'success',
                'message': f'Contact "{contact_name}" deleted successfully'
            })

        except Emergency_contact.DoesNotExist:
            return JsonResponse({
                'status': 'error',
                'message': 'Contact not found'
            })
        except Exception as e:
            print(f"❌ Error: {str(e)}")
            return JsonResponse({
                'status': 'error',
                'message': str(e)
            })

    return JsonResponse({
        'status': 'error',
        'message': 'Only POST method allowed'
    })


@csrf_exempt
def update_emergency_contact(request, contact_id):
    """Update an emergency contact"""
    if request.method == 'POST':
        try:
            lid = request.POST.get('lid')
            name = request.POST.get('name')
            email = request.POST.get('email')
            phone = request.POST.get('phone')

            if not lid:
                return JsonResponse({
                    'status': 'error',
                    'message': 'User ID required'
                })

            # Get contact and verify ownership
            contact = get_object_or_404(Emergency_contact, id=contact_id)

            if contact.USER.LOGIN_id != lid:
                return JsonResponse({
                    'status': 'error',
                    'message': 'You are not authorized to update this contact'
                })

            # Update fields
            if name:
                contact.name = name
            if email:
                contact.email = email
            if phone:
                contact.phone = phone

            contact.save()

            return JsonResponse({
                'status': 'success',
                'message': 'Contact updated successfully',
                'contact': {
                    'id': contact.id,
                    'name': contact.name,
                    'email': contact.email,
                    'phone': contact.phone
                }
            })

        except Emergency_contact.DoesNotExist:
            return JsonResponse({
                'status': 'error',
                'message': 'Contact not found'
            })
        except Exception as e:
            print(f"❌ Error: {str(e)}")
            return JsonResponse({
                'status': 'error',
                'message': str(e)
            })

    return JsonResponse({
        'status': 'error',
        'message': 'Only POST method allowed'
    })