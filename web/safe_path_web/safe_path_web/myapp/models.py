from django.contrib.auth.models import User
from django.db import models

# Create your models here.
class police_station(models.Model):
    name=models.CharField(max_length=100)
    email=models.CharField(max_length=100)
    phone=models.CharField(max_length=100)
    place=models.CharField(max_length=100)
    post=models.CharField(max_length=100)
    district=models.CharField(max_length=100)
    pin=models.CharField(max_length=100)

class police_officers(models.Model):
    name=models.CharField(max_length=100)
    email=models.CharField(max_length=100)
    phone=models.CharField(max_length=100)
    status=models.CharField(max_length=100)
    STATION=models.ForeignKey(police_station, on_delete=models.CASCADE)
    LOGIN=models.ForeignKey(User, on_delete=models.CASCADE)

class users(models.Model):
    name=models.CharField(max_length=100)
    email=models.CharField(max_length=100)
    phone=models.CharField(max_length=100)
    place=models.CharField(max_length=100)
    post=models.CharField(max_length=100)
    district=models.CharField(max_length=100)
    pin=models.CharField(max_length=100)
    status=models.CharField(max_length=100)
    LOGIN=models.ForeignKey(User, on_delete=models.CASCADE)

class dangerous_spot(models.Model):
    place_name=models.CharField(max_length=100)
    latitude=models.CharField(max_length=100)
    longitude=models.CharField(max_length=100)
    status=models.CharField(max_length=100,default="pending")
    type=models.CharField(max_length=100,default="pending")
    LOGIN=models.ForeignKey(User, on_delete=models.CASCADE)

class safe_spot(models.Model):
    place_name=models.CharField(max_length=100)
    latitude=models.CharField(max_length=100)
    longitude=models.CharField(max_length=100)
    LOGIN=models.ForeignKey(User, on_delete=models.CASCADE)

class reported_spot(models.Model):
    place_name=models.CharField(max_length=100)
    latitude=models.CharField(max_length=100)
    longitude=models.CharField(max_length=100)
    date=models.CharField(max_length=100)
    time=models.CharField(max_length=100)
    status=models.CharField(max_length=100)
    USER=models.ForeignKey(users, on_delete=models.CASCADE)

class false_report(models.Model):
    date=models.CharField(max_length=100)
    time=models.CharField(max_length=100)
    REPORT_SPOT=models.ForeignKey(reported_spot, on_delete=models.CASCADE)
    OFFICER=models.ForeignKey(police_officers, on_delete=models.CASCADE)

class emergency_request(models.Model):
    latitude=models.CharField(max_length=100)
    longitude=models.CharField(max_length=100)
    date=models.CharField(max_length=100)
    time=models.CharField(max_length=100)
    status=models.CharField(max_length=100)
    USER=models.ForeignKey(users, on_delete=models.CASCADE)



class Location(models.Model):
    LOGIN=models.ForeignKey(User,on_delete=models.CASCADE)
    latitude=models.CharField(max_length=100)
    longitude=models.CharField(max_length=100)


class UserJourney(models.Model):
    fromplace=models.CharField(max_length=100)
    toplace=models.CharField(max_length=100)
    date=models.DateField()
    time=models.TimeField()
    USER=models.ForeignKey(users,on_delete=models.CASCADE)


class Journeyrequest(models.Model):
    JOURNEY=models.ForeignKey(UserJourney,on_delete=models.CASCADE)
    SENDERID=models.ForeignKey(users,on_delete=models.CASCADE)
    status=models.CharField(max_length=100)
    date=models.DateField()




class Chat(models.Model):
    FROM=models.ForeignKey(User,on_delete=models.CASCADE,related_name="fromid")
    TO=models.ForeignKey(User,on_delete=models.CASCADE,related_name="toid")
    message=models.CharField(max_length=500)
    date=models.DateField()


from django.db import models


class SOSAlert(models.Model):
    user = models.ForeignKey(users, on_delete=models.CASCADE, null=True)

    # Location
    latitude = models.CharField(max_length=50)
    longitude = models.CharField(max_length=50)

    # Alert details
    timestamp = models.DateTimeField()
    status = models.CharField(max_length=20, default='active')  # active/resolved



class Emergency_contact(models.Model):
    name=models.CharField(max_length=100)
    email=models.CharField(max_length=100)
    phone=models.CharField(max_length=100,default="")
    USER=models.ForeignKey(users,on_delete=models.CASCADE)