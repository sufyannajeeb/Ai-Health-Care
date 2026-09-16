from django.db import models
from django.utils import timezone
from datetime import timedelta

# Create your models here.


class Login(models.Model):
    username=models.CharField(max_length=100)
    password=models.CharField(max_length=100)
    type=models.CharField(max_length=100)

class Experts(models.Model):
    LOGIN = models.ForeignKey(Login, on_delete=models.CASCADE)
    image = models.CharField(max_length=500)
    idproof = models.CharField(max_length=500)
    name = models.CharField(max_length=100)
    place = models.CharField(max_length=100)
    post = models.CharField(max_length=100)
    district = models.CharField(max_length=100)
    phone = models.BigIntegerField()
    email = models.CharField(max_length=100)
    type = models.CharField(max_length=100)
    gender = models.CharField(max_length=100)  # Add this line
# class User(models.Model):
#     LOGIN=models.ForeignKey(Login,on_delete=models.CASCADE)
#     name=models.CharField(max_length=100)
#     place=models.CharField(max_length=100)
#     gender=models.CharField(max_length=20)
#     dob=models.CharField(max_length=30)
#     height=models.CharField(max_length=100)
#     weight=models.CharField(max_length=100)
#     post=models.CharField(max_length=100)
#     district=models.CharField(max_length=100)
#     email=models.CharField(max_length=100)
#     phone=models.CharField(max_length=100)
#     image=models.CharField(max_length=400)
#     bmi=models.CharField(max_length=400)
#     date=models.DateField()
#     calorie=models.FloatField()
#     type=models.CharField(max_length=40)



class User(models.Model):
    LOGIN = models.ForeignKey(Login, on_delete=models.CASCADE)
    Name = models.CharField(max_length=100)
    Dob = models.DateField()
    Gender = models.CharField(max_length=100)
    Place = models.CharField(max_length=100)
    Pin = models.CharField(max_length=100)
    Post = models.CharField(max_length=100)
    Bloodtype = models.CharField(max_length=100)
    Photo = models.FileField()
    Email = models.CharField(max_length=100)
    Phone = models.BigIntegerField()
    District = models.CharField(max_length=100)


class Complaints(models.Model):
    USER=models.ForeignKey(User,on_delete=models.CASCADE,default='')
    complaints=models.CharField(max_length=400)
    date=models.DateField()
    reply=models.CharField(max_length=400)


class Chat(models.Model):
    FROMID = models.ForeignKey(Login, on_delete=models.CASCADE, related_name='fromid')
    TOID = models.ForeignKey(Login, on_delete=models.CASCADE, related_name='toid')
    date = models.DateField()
    message = models.CharField(max_length=2000)
    msg_type = models.CharField(max_length=10, default='text')  # ← ADD THIS LINE



class Expertfeedback(models.Model):
    USER=models.ForeignKey(User,on_delete=models.CASCADE,default='')
    EXPERT=models.ForeignKey(Experts,on_delete=models.CASCADE,default='')
    feedback=models.CharField(max_length=400)
    rating=models.CharField(max_length=400)
    date=models.DateField()

class Food(models.Model):
    USER = models.ForeignKey(User, on_delete=models.CASCADE, default='')
    type = models.CharField(max_length=500)
    name = models.CharField(max_length=500)
    date = models.DateField()
    gram = models.FloatField()
    callorie=models.IntegerField()


class Water(models.Model):
    USER = models.ForeignKey(User, on_delete=models.CASCADE, default='')
    type = models.CharField(max_length=500)
    alert = models.CharField(max_length=500)
    status = models.CharField(max_length=500)
    date = models.DateField()


class Chatbot(models.Model):
    USER = models.ForeignKey(User, on_delete=models.CASCADE, default='')
    question = models.CharField(max_length=500)
    answer = models.CharField(max_length=500)
    date = models.DateField()

class Workassign(models.Model):
    EXPERT = models.ForeignKey(Experts, on_delete=models.CASCADE, default='')
    work = models.CharField(max_length=500)
    details = models.CharField(max_length=500)
    status = models.CharField(max_length=100)
    date = models.DateField()


class Diet(models.Model):
    bmi = models.CharField(max_length=500)
    age = models.IntegerField()
    gender = models.CharField(max_length=100)
    bp = models.CharField(max_length=100)
    cholestrol = models.CharField(max_length=100)
    sugar = models.CharField(max_length=100)
    healthcondition = models.CharField(max_length=100)
    type = models.CharField(max_length=100)
    dietplan = models.CharField(max_length=100)
    excersiseplan = models.CharField(max_length=100)


class Diet_chart(models.Model):
    Name = models.CharField(max_length=100, default=1)
    Date = models.DateField()
    Time = models.TimeField(max_length=100)
    Dietplan=models.CharField(max_length=500)
    Gender = models.CharField(max_length=100)
    Obicity = models.CharField(max_length=100)
    Bloodpressure = models.CharField(max_length=100)
    Diabetes = models.CharField(max_length=100)
    Cholestrol = models.CharField(max_length=100)
    Alcoholabuse = models.CharField(max_length=100)
    Druguse = models.CharField(max_length=100)
    Smoking = models.CharField(max_length=100)
    Headaches = models.CharField(max_length=100)
    Asthma = models.CharField(max_length=100)
    Heartproblem = models.CharField(max_length=100)
    Cancer = models.CharField(max_length=100)
    Stroke = models.CharField(max_length=100)
    Kidney = models.CharField(max_length=100)
    Liver = models.CharField(max_length=100)
    Depression = models.CharField(max_length=100)
    Allergies = models.CharField(max_length=100)
    Arthritis = models.CharField(max_length=100)
    Pregnancy = models.CharField(max_length=100)
    bmi = models.FloatField(max_length=100)
    
    
    
    
class PaymentAccess(models.Model):
    payer = models.ForeignKey(Login, on_delete=models.CASCADE, related_name='payments_made')
    expert = models.ForeignKey(Login, on_delete=models.CASCADE, related_name='payments_received')
    order_id = models.CharField(max_length=120, blank=True, null=True)
    payment_id = models.CharField(max_length=120, blank=True, null=True)
    signature = models.CharField(max_length=255, blank=True, null=True)
    amount = models.IntegerField(default=0)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = "mental_app_paymentaccess"

    def activate_for_days(self, days=1):
        now = timezone.now()
        self.expires_at = now + timedelta(days=days)
        self.is_active = True
        self.save()

    def is_valid_now(self):
        if not self.is_active:
            return False
        if self.expires_at is None:
            return True
        return timezone.now() <= self.expires_at

    
   
