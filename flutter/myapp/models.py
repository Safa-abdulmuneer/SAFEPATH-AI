from django.db import models
from django.contrib.auth.models import User



class PoliceStation(models.Model):
    name=models.CharField(max_length=100)
    place=models.CharField(max_length=100)
    post=models.CharField(max_length=100)
    district=models.CharField(max_length=100)
    state=models.CharField(max_length=100)
    since=models.BigIntegerField()
    phone=models.BigIntegerField()
    email=models.CharField(max_length=100)

class SubAdmin(models.Model):
    LOGIN=models.ForeignKey(User,on_delete=models.CASCADE)
    name=models.CharField(max_length=100)
    gender=models.CharField(max_length=100)
    email= models.CharField(max_length=100)
    phone=models.BigIntegerField()
    photo= models.CharField(max_length=500)


class PinkPolice(models.Model):
    POLICESTATION=models.ForeignKey(PoliceStation,on_delete=models.CASCADE)
    LOGIN=models.ForeignKey(User,on_delete=models.CASCADE)
    vechileno=models.CharField(max_length=100)
    officername=models.CharField(max_length=100)
    place=models.CharField(max_length=100)
    post=models.CharField(max_length=100)
    district=models.CharField(max_length=100)
    state=models.CharField(max_length=100)
    email=models.CharField(max_length=100)
    phone=models.CharField(max_length=15)
    gender=models.CharField(max_length=100)
    dob=models.DateField()


class Notification(models.Model):
    date=models.DateField()
    description=models.CharField(max_length=500)

class Complaint(models.Model):
    USER=models.ForeignKey(User,on_delete=models.CASCADE)
    date=models.DateField()
    complaint=models.CharField(max_length=100)
    reply=models.CharField(max_length=100)
    status=models.CharField(max_length=100)
    PINKPOLICE=models.ForeignKey(PinkPolice,on_delete=models.CASCADE)

class Idea(models.Model):
    idea=models.CharField(max_length=100)
    image=models.CharField(max_length=500)
    date=models.DateField()
    USER=models.ForeignKey(User,on_delete=models.CASCADE)

class Feedback(models.Model):
    date=models.DateField()
    USER=models.ForeignKey(User,on_delete=models.CASCADE)
    feedback=models.CharField(max_length=100)


class SafePoint(models.Model):
    place=models.CharField(max_length=100)
    latitude=models.CharField(max_length=100)
    longitude=models.CharField(max_length=100)
    landmark=models.CharField(max_length=100)

class DangerousSpot(models.Model):
    place=models.CharField(max_length=100)
    photo=models.CharField(max_length=500)
    date=models.DateField()
    longitude=models.CharField(max_length=100)
    latitude=models.CharField(max_length=100)
    LOGIN=models.ForeignKey(User,on_delete=models.CASCADE)
    status=models.CharField(max_length=100)

class User_details(models.Model):
    name=models.CharField(max_length=100)
    dob=models.DateField()
    gender=models.CharField(max_length=100)
    phone=models.BigIntegerField()
    email=models.CharField(max_length=100)
    place=models.CharField(max_length=100)
    post=models.CharField(max_length=100)
    district=models.CharField(max_length=100)
    state=models.CharField(max_length=100)

    photo=models.CharField(max_length=1000)

    identificationmark=models.CharField(max_length=100)
    LOGIN = models.ForeignKey(User,on_delete=models.CASCADE)
    fathersname=models.CharField(max_length=100)
    mothername=models.CharField(max_length=100)
    bloodgroup=models.CharField(max_length=100)



class EmergnecyNumber(models.Model):
    number=models.BigIntegerField()
    name=models.CharField(max_length=100)
    relation=models.CharField(max_length=100,default='')
    USER=models.ForeignKey(User_details,on_delete=models.CASCADE,default='')

class Location(models.Model):
    LOGIN=models.ForeignKey(User,on_delete=models.CASCADE)
    latitude=models.CharField(max_length=100)
    longitude=models.CharField(max_length=100)

class EmergencyRequest(models.Model):
    USER=models.ForeignKey(User,on_delete=models.CASCADE)
    date=models.DateField()
    request=models.CharField(max_length=100)
    latitude=models.CharField(max_length=100,default='')
    longitude=models.CharField(max_length=100,default='')
