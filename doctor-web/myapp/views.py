import datetime
from datetime import timedelta
import traceback
import hmac
import hashlib
import json
import numpy as np

from django.views.decorators.csrf import csrf_exempt
from django.core.files.storage import FileSystemStorage
from django.db.models import Q
from django.http import HttpResponse, JsonResponse
from django.shortcuts import render, redirect
from django.utils import timezone
from django.conf import settings

import razorpay

from myapp.models import *

def logout(request):
    request.session['lid']=''
    request.session['type']=''
    return HttpResponse('''<script>alert("Logouted ");window.location='/'</script>''')


def login(request):
    if 'submit' in request.POST:
        username = request.POST['username']
        password = request.POST['password']

        a=Login.objects.filter(username=username,password=password)
        if a.exists():
            b = Login.objects.get(username=username, password=password)
            request.session['lid']=b.id
            request.session['type']=b.type  # Added this line
            
            if b.type=='admin':
                return HttpResponse('''<script>alert("Login successfully ");window.location='/admin_home'</script>''')
            elif b.type == 'expert':
                try:
                    expert = Experts.objects.get(LOGIN_id=b.id)
                    request.session['expert_name'] = expert.name
                except Experts.DoesNotExist:
                    request.session['expert_name'] = 'Dr. Expert'
                
                return HttpResponse('''<script>alert("Login successfully ");window.location='/expert_home'</script>''')
            else:
                return HttpResponse('''<script>alert("Invalid ");window.location='/'</script>''')
        else:
            return HttpResponse('''<script>alert("Invalid ");window.location='/'</script>''')
    return  render(request,'loginindex.html')


def admin_home(request):
    if request.session.get('type') != 'admin':
        return HttpResponse('''<script>alert("Unauthorized Access");window.location='/'</script>''')
    
    # Calculate dashboard statistics
    total_experts = Experts.objects.count()
    total_users = User.objects.count()
    total_workassigns = Workassign.objects.count()
    total_complaints = Complaints.objects.count()
    
    # Assuming you have status fields, adjust if needed
    pending_experts = Experts.objects.filter(status='pending').count() if hasattr(Experts, 'status') else 1
    pending_complaints = Complaints.objects.filter(status='pending').count() if hasattr(Complaints, 'status') else 0
    replied_complaints = Complaints.objects.filter(status='replied').count() if hasattr(Complaints, 'status') else 0
    completed_works = Workassign.objects.filter(status='Completed').count() if hasattr(Workassign, 'status') else 0
    progress_works = Workassign.objects.filter(status='In Progress').count() if hasattr(Workassign, 'status') else 0
    
    context = {
        'total_experts': total_experts,
        'total_users': total_users,
        'total_workassigns': total_workassigns,
        'total_complaints': total_complaints,
        'pending_experts': pending_experts,
        'pending_complaints': pending_complaints,
        'replied_complaints': replied_complaints,
        'completed_works': completed_works,
        'progress_works': progress_works,
    }
    
    return render(request, 'admin/adminhome.html', context)


def expert_reg(request):
    if request.session.get('type') != 'admin':
        return HttpResponse('''<script>alert("Unauthorized Access");window.location='/'</script>''')
    
    if 'submit' in request.POST:
        name=request.POST['name']
        place=request.POST['place']
        post=request.POST['post']
        district=request.POST['district']
        phone=request.POST['phone']
        email=request.POST['email']
        type=request.POST['type']
        password=request.POST['password']

        image=request.FILES['image']
        fs=FileSystemStorage()

        fn=fs.save(image.name,image)
        path=fs.url(fn)

        proof=request.FILES['proof']
        fs1=FileSystemStorage()

        fn1=fs1.save(proof.name,proof)
        path1=fs1.url(fn1)

        b=Login()
        b.username=email
        b.password=password
        b.type='expert'
        b.save()

        a=Experts()
        a.LOGIN=b
        a.name=name
        a.type=type
        a.place=place
        a.post=post
        a.district=district
        a.phone=phone
        a.email=email
        a.idproof=path1
        a.image=path
        a.save()
        return HttpResponse('''<script>alert("Registered ");window.location='/admin_verify_expert'</script>''')

    return render(request,'admin/add_expert.html')


def admin_verify_expert(request):
    if request.session.get('lid','')=='':
        return HttpResponse('''<script>alert("Logouted ");window.location='/'</script>''')
    if request.session.get('type') != 'admin':
        return HttpResponse('''<script>alert("Unauthorized Access");window.location='/'</script>''')
    
    a=Experts.objects.all()
    return render(request,'admin/view expert.html',{'a':a})


def admin_delete_expert(request,id):
    if request.session.get('type') != 'admin':
        return HttpResponse('''<script>alert("Unauthorized Access");window.location='/'</script>''')
    
    a=Login.objects.get(id=id)
    a.delete()
    return HttpResponse('''<script>alert("Deleted ");window.location='/admin_verify_expert'</script>''')


def admin_verify_expert_post(request):
    if request.session.get('lid','')=='':
        return HttpResponse('''<script>alert("Logouted ");window.location='/'</script>''')
    if request.session.get('type') != 'admin':
        return HttpResponse('''<script>alert("Unauthorized Access");window.location='/'</script>''')
    
    f=request.POST['f']
    a=Experts.objects.filter(name__icontains=f)
    if not a:
        return HttpResponse('''<script>alert("Expert  not found");window.location='/admin_verify_expert'</script>''')

    return render(request,'admin/view expert.html',{'a':a})


def admin_view_expert_feedback(request,id):
    if request.session.get('type') != 'admin':
        return HttpResponse('''<script>alert("Unauthorized Access");window.location='/'</script>''')
    
    b=Expertfeedback.objects.filter(EXPERT_id=id).order_by('-id')
    return render(request,'admin/admin_view_expert_feedback.html',{'data':b})


def admin_view_user(request):
    if request.session.get('lid','')=='':
        return HttpResponse('''<script>alert("Logouted ");window.location='/'</script>''')
    if request.session.get('type') != 'admin':
        return HttpResponse('''<script>alert("Unauthorized Access");window.location='/'</script>''')
    
    a=User.objects.all()
    return render(request,'admin/admin_view_user.html',{'a':a})


def admin_view_complaints(request):
    if request.session.get('lid','')=='':
        return HttpResponse('''<script>alert("Logouted ");window.location='/'</script>''')
    if request.session.get('type') != 'admin':
        return HttpResponse('''<script>alert("Unauthorized Access");window.location='/'</script>''')
    
    a=Complaints.objects.all()
    return render(request,'admin/admin_view_complaints.html',{'a':a})


def assign_work(request):
    if request.session.get('type') != 'admin':
        return HttpResponse('''<script>alert("Unauthorized Access");window.location='/'</script>''')
    
    b=Experts.objects.all()
    if 'submit' in request.POST:
        work=request.POST['work']
        details=request.POST['details']
        EXPERT=request.POST['EXPERT']

        a=Workassign()
        a.work=work
        a.details=details
        a.EXPERT=Experts.objects.get(id=EXPERT)
        a.date=datetime.datetime.now().today().date()
        a.status='Assigned'
        a.save()
        return HttpResponse('''<script>alert("Assigned ");window.location='/admin_home'</script>''')
    return render(request,'admin/assign work.html',{'data':b})


def admin_view_assign(request):
    print("="*60)
    print("DEBUG admin_view_assign")
    print("="*60)
    print("Session LID:", request.session.get('lid', 'NOT SET'))
    print("Session TYPE:", request.session.get('type', 'NOT SET'))
    print("All session keys:", list(request.session.keys()))
    print("All session data:", dict(request.session))
    print("="*60)

    # 🔒 Check login
    if request.session.get('lid', '') == '':
        return HttpResponse(
            '''<script>alert("Logged out");window.location='/'</script>'''
        )

    # 🔒 Check admin role
    if request.session.get('type') != 'admin':
        return HttpResponse(
            '''<script>alert("Unauthorized Access - Type is: '''
            + str(request.session.get('type', 'NONE')) +
            '''");window.location='/'</script>'''
        )

    # 📋 Fetch assigned works
    a = Workassign.objects.all()

    # 📊 Status counts
    assigned_count = a.filter(status="Assigned").count()
    progress_count = a.filter(status="In Progress").count()
    completed_count = a.filter(status="Completed").count()

    context = {
        'data': a,
        'assigned_count': assigned_count,
        'progress_count': progress_count,
        'completed_count': completed_count,
    }

    return render(request, 'admin/view work.html', context)

def delete_assign_work(request,id):
    if request.session.get('type') != 'admin':
        return HttpResponse('''<script>alert("Unauthorized Access");window.location='/'</script>''')
    
    a=Workassign.objects.get(id=id)
    a.delete()
    return HttpResponse('''<script>alert("Deleted ");window.location='/admin_view_assign'</script>''')


def admin_reply(request,id):
    if request.session.get('type') != 'admin':
        return HttpResponse('''<script>alert("Unauthorized Access");window.location='/'</script>''')
    
    a=Complaints.objects.get(id=id)
    return render(request,'admin/reply.html',{'data':a})


def admin_reply_post(request):
    if request.session.get('type') != 'admin':
        return HttpResponse('''<script>alert("Unauthorized Access");window.location='/'</script>''')
    
    id=request.POST['id']
    reply=request.POST['c']
    c=Complaints.objects.get(id=id)
    c.reply=reply
    c.status="replied"
    c.save()
    return HttpResponse('''<script>alert("Replied ");window.location='/admin_view_complaints'</script>''')


def expert_home(request):
    """
    Enhanced expert home view with real-time dashboard statistics
    """
    if request.session.get('lid','') == '':
        return HttpResponse('''<script>alert("Logouted ");window.location='/'</script>''')
    if request.session.get('type') != 'expert':
        return HttpResponse('''<script>alert("Unauthorized Access");window.location='/'</script>''')
    
    expert_login_id = request.session.get('lid')
    expert_name = request.session.get('expert_name', 'Dr. Expert')
    
    # Get the expert object
    try:
        expert = Experts.objects.get(LOGIN_id=expert_login_id)
    except Experts.DoesNotExist:
        expert = None
    
    # Calculate dashboard statistics
    if expert:
        # Active Assignments - work assigned to this expert
        total_assignments = Workassign.objects.filter(EXPERT=expert).count()
        active_assignments = Workassign.objects.filter(
            EXPERT=expert,
            status__in=['Assigned', 'In Progress']
        ).count()
        completed_assignments = Workassign.objects.filter(
            EXPERT=expert,
            status='Completed'
        ).count()
        
        # Calculate percentage increase (comparing to previous week)
        week_ago = datetime.datetime.now().today().date() - timedelta(days=7)
        two_weeks_ago = datetime.datetime.now().today().date() - timedelta(days=14)
        
        this_week_assignments = Workassign.objects.filter(
            EXPERT=expert,
            date__gte=week_ago
        ).count()
        last_week_assignments = Workassign.objects.filter(
            EXPERT=expert,
            date__gte=two_weeks_ago,
            date__lt=week_ago
        ).count()
        
        if last_week_assignments > 0:
            assignments_increase = round(((this_week_assignments - last_week_assignments) / last_week_assignments) * 100)
        else:
            assignments_increase = 100 if this_week_assignments > 0 else 0
        
        # Total Patients - unique users this expert has interacted with
        total_patients = User.objects.count()
        
        # Calculate new patients (last 7 days)
        new_patients_count = User.objects.filter(
            id__in=Chat.objects.filter(
                TOID_id=expert_login_id,
                date__gte=week_ago
            ).values_list('FROMID_id', flat=True).distinct()
        ).count()
        
        # Diet Plans Created by this expert
        total_diet_plans = Diet_chart.objects.count()
        today_diet_plans = Diet_chart.objects.filter(
            Date=datetime.datetime.now().today().date()
        ).count()
        
        # Average Rating - from expert feedback
        feedbacks = Expertfeedback.objects.filter(EXPERT=expert)
        if feedbacks.exists():
            total_rating = sum([float(f.rating) for f in feedbacks])
            average_rating = round(total_rating / feedbacks.count(), 1)
            total_feedbacks = feedbacks.count()
            
            # Get recent feedbacks (last 7 days)
            recent_feedbacks = feedbacks.filter(date__gte=week_ago).count()
            
            # Determine rating quality text
            if average_rating >= 4.5:
                rating_quality = "Excellent"
            elif average_rating >= 4.0:
                rating_quality = "Very Good"
            elif average_rating >= 3.5:
                rating_quality = "Good"
            else:
                rating_quality = "Fair"
        else:
            average_rating = 0
            total_feedbacks = 0
            recent_feedbacks = 0
            rating_quality = "No Ratings"
        
        # Recent activities for the activity feed
        recent_assignments = Workassign.objects.filter(EXPERT=expert).order_by('-date')[:10]
        recent_expert_feedbacks = Expertfeedback.objects.filter(EXPERT=expert).order_by('-date')[:10]
        
        # Combine and sort recent activities
        activities = []
        
        for assignment in recent_assignments:
            time_diff = datetime.datetime.now().today().date() - assignment.date
            if time_diff.days == 0:
                time_str = "Today"
            elif time_diff.days == 1:
                time_str = "1 day ago"
            else:
                time_str = f"{time_diff.days} days ago"
            
            activities.append({
                'type': 'assignment',
                'icon': 'assignment_add',
                'title': 'New Work Assignment',
                'description': assignment.work,
                'time': time_str,
                'status': assignment.status,
                'date': assignment.date
            })
        
        for feedback in recent_expert_feedbacks:
            time_diff = datetime.datetime.now().today().date() - feedback.date
            if time_diff.days == 0:
                time_str = "Today"
            elif time_diff.days == 1:
                time_str = "1 day ago"
            else:
                time_str = f"{time_diff.days} days ago"
            
            activities.append({
                'type': 'feedback',
                'icon': 'grade',
                'title': f'New {feedback.rating}-Star Feedback Received',
                'description': feedback.feedback[:100] + '...' if len(feedback.feedback) > 100 else feedback.feedback,
                'time': time_str,
                'status': 'Reviewed',
                'date': feedback.date
            })
        
        # Sort activities by date
        activities.sort(key=lambda x: x['date'], reverse=True)
        activities = activities[:4]  # Keep only the 4 most recent
        
        # This week's performance
        week_completed = Workassign.objects.filter(
            EXPERT=expert,
            status='Completed',
            date__gte=week_ago
        ).count()
        week_pending = Workassign.objects.filter(
            EXPERT=expert,
            status__in=['Assigned', 'In Progress'],
            date__gte=week_ago
        ).count()
        week_feedbacks = Expertfeedback.objects.filter(
            EXPERT=expert,
            date__gte=week_ago
        ).count()
        week_diet_charts = Diet_chart.objects.filter(
            Date__gte=week_ago
        ).count()
        
    else:
        # Default values if expert not found
        total_assignments = 0
        active_assignments = 0
        completed_assignments = 0
        assignments_increase = 0
        total_patients = 0
        new_patients_count = 0
        total_diet_plans = 0
        today_diet_plans = 0
        average_rating = 0
        total_feedbacks = 0
        recent_feedbacks = 0
        rating_quality = "No Ratings"
        activities = []
        week_completed = 0
        week_pending = 0
        week_feedbacks = 0
        week_diet_charts = 0
    
    context = {
        'expert_name': expert_name,
        'active_assignments': active_assignments,
        'assignments_increase': assignments_increase,
        'total_patients': total_patients,
        'new_patients': new_patients_count,
        'total_diet_plans': total_diet_plans,
        'today_diet_plans': today_diet_plans,
        'average_rating': average_rating,
        'total_feedbacks': total_feedbacks,
        'recent_feedbacks': recent_feedbacks,
        'rating_quality': rating_quality,
        'activities': activities,
        'week_completed': week_completed,
        'week_pending': week_pending,
        'week_feedbacks': week_feedbacks,
        'week_diet_charts': week_diet_charts,
        'completed_assignments': completed_assignments,
    }
    
    return render(request, 'expert/expertindex.html', context)


def expertview_user(request):
    if request.session.get('lid','') == '':
        return HttpResponse('''<script>alert("Logouted ");window.location='/'</script>''')
    if request.session.get('type') != 'expert':
        return HttpResponse('''<script>alert("Unauthorized Access");window.location='/'</script>''')

    a=User.objects.all()
    return render(request,'expert/view user.html',{'data':a})


def chatwithuser(request):
    if request.session.get('type') != 'expert':
        return HttpResponse('''<script>alert("Unauthorized Access");window.location='/'</script>''')
    
    ob = User.objects.all()
    return render(request,"expert/fur_chat.html",{'val':ob})


def expert_chat_to_user(request, id):
    if request.session.get('type') != 'expert':
        return HttpResponse('''<script>alert("Unauthorized Access");window.location='/'</script>''')
    
    try:
        request.session["userid"] = id
        cid = str(id)
        user = User.objects.get(LOGIN_id=id)

        return render(request, "expert/Chat.html", {
            "name": user.Name,
            "toid": cid,
            "photo": user.Photo.url if user.Photo else ""
        })

    except User.DoesNotExist:
        return HttpResponse("User not found")


def expertchatview(request):
    users_with_accepted_requests = User.objects.all()

    data = []
    for user in users_with_accepted_requests:
        r = {
            "name": user.name,
            "image": user.image,
            "email": user.email,
            "loginid": user.LOGIN.id
        }
        data.append(r)
    print(data)
    return JsonResponse(data, safe=False)


def home(request):
    return render(request, 'home.html')


def expert_view_feedback(request):
    if request.session.get('lid','') == '':
        return HttpResponse('''<script>alert("Logouted ");window.location='/'</script>''')
    if request.session.get('type') != 'expert':
        return HttpResponse('''<script>alert("Unauthorized Access");window.location='/'</script>''')

    a=Expertfeedback.objects.filter(EXPERT__LOGIN_id=request.session['lid'])
    return render(request,'expert/view feedback.html',{'data':a})


def expert_view_assignedwork(request):
    """
    Expert views all work assigned to them
    This version tries multiple methods to find assignments
    """
    if request.session.get('lid', '') == '':
        return HttpResponse('''<script>alert("Logged out");window.location='/'</script>''')
    
    # Changed from 'admin' to 'expert'
    if request.session.get('type') != 'expert':
        return HttpResponse('''<script>alert("Unauthorized Access");window.location='/'</script>''')

    expert_login_id = request.session.get('lid')
    
    print("\n" + "="*60)
    print("EXPERT VIEW ASSIGNED WORK - DEBUG")
    print("="*60)
    print(f"Session LID: {expert_login_id}")
    print(f"Session LID type: {type(expert_login_id)}")
    
    try:
        expert = Experts.objects.get(LOGIN_id=int(expert_login_id))
        print(f"✓ Expert found: {expert.name} (Expert ID: {expert.id}, LOGIN_ID: {expert.LOGIN_id})")
    except (Experts.DoesNotExist, ValueError, TypeError):
        try:
            expert = Experts.objects.get(LOGIN_id=str(expert_login_id))
            print(f"✓ Expert found: {expert.name} (Expert ID: {expert.id}, LOGIN_ID: {expert.LOGIN_id})")
        except Experts.DoesNotExist:
            print("✗ No expert found with this LOGIN_id")
            print("="*60 + "\n")
            return render(request, 'expert/view assigned work.html', {'data': []})
    
    all_assignments = Workassign.objects.all()
    print(f"\nTotal assignments in database: {all_assignments.count()}")
    
    if all_assignments.count() > 0:
        print("All assignments:")
        for work in all_assignments:
            print(f"  - {work.work}")
            print(f"    Assigned to: {work.EXPERT.name}")
            print(f"    Expert LOGIN_id: {work.EXPERT.LOGIN_id} (type: {type(work.EXPERT.LOGIN_id)})")
            print(f"    Status: {work.status}")
    
    print(f"\nTrying different query methods for expert LOGIN_id={expert_login_id}:")
    
    try:
        method1 = Workassign.objects.filter(EXPERT__LOGIN_id=int(expert_login_id))
        print(f"  Method 1 (int filter): {method1.count()} assignments")
    except:
        method1 = Workassign.objects.none()
        print(f"  Method 1 (int filter): FAILED")
    
    try:
        method2 = Workassign.objects.filter(EXPERT__LOGIN_id=str(expert_login_id))
        print(f"  Method 2 (str filter): {method2.count()} assignments")
    except:
        method2 = Workassign.objects.none()
        print(f"  Method 2 (str filter): FAILED")
    
    try:
        method3 = Workassign.objects.filter(EXPERT=expert)
        print(f"  Method 3 (expert obj): {method3.count()} assignments")
    except:
        method3 = Workassign.objects.none()
        print(f"  Method 3 (expert obj): FAILED")
    
    try:
        method4 = Workassign.objects.filter(EXPERT_id=expert.id)
        print(f"  Method 4 (expert.id): {method4.count()} assignments")
    except:
        method4 = Workassign.objects.none()
        print(f"  Method 4 (expert.id): FAILED")
    
    if method1.exists():
        assigned_works = method1.order_by('-date')
        print(f"\n✓ Using Method 1: Found {assigned_works.count()} assignments")
    elif method2.exists():
        assigned_works = method2.order_by('-date')
        print(f"\n✓ Using Method 2: Found {assigned_works.count()} assignments")
    elif method3.exists():
        assigned_works = method3.order_by('-date')
        print(f"\n✓ Using Method 3: Found {assigned_works.count()} assignments")
    elif method4.exists():
        assigned_works = method4.order_by('-date')
        print(f"\n✓ Using Method 4: Found {assigned_works.count()} assignments")
    else:
        assigned_works = []
        print(f"\n✗ No assignments found with any method")
    
    print("="*60 + "\n")
    
    return render(request, 'expert/view assigned work.html', {'data': assigned_works})


def expert_view_work_details(request, id):
    """
    Expert views detailed information about a specific assigned work
    and can update its status
    """
    if request.session.get('lid', '') == '':
        return HttpResponse('''<script>alert("Logged out");window.location='/'</script>''')
    if request.session.get('type') != 'expert':
        return HttpResponse('''<script>alert("Unauthorized Access");window.location='/'</script>''')
    
    try:
        work = Workassign.objects.get(id=id)
        
        if work.EXPERT.LOGIN_id != int(request.session['lid']):
            return HttpResponse('''<script>alert("Unauthorized access");window.location='/expert_view_assignedwork'</script>''')
        
        if request.method == 'POST' and 'update_status' in request.POST:
            new_status = request.POST.get('status')
            if new_status in ['Assigned', 'In Progress', 'Completed']:
                work.status = new_status
                work.save()
                return HttpResponse('''<script>alert("Status updated successfully!");window.location='/expert_view_work_details/''' + str(id) + '''/'</script>''')
        
        context = {
            'work': work
        }
        return render(request, 'expert/view work details.html', context)
        
    except Workassign.DoesNotExist:
        return HttpResponse('''<script>alert("Work assignment not found");window.location='/expert_view_assignedwork'</script>''')


def add_diet_chart(request):
    if request.session.get('lid','') == '':
        return HttpResponse('''<script>alert('logout succesfull');window.location="/"</script>''')
    if request.session.get('type') != 'expert':
        return HttpResponse('''<script>alert("Unauthorized Access");window.location='/'</script>''')

    return render(request,"expert/add dataset diet.html")


def add_diet_chart_post(request):
    if request.session.get('lid','') == '':
        return HttpResponse('''<script>alert('logout succesfull');window.location="login"</script>''')
    if request.session.get('type') != 'expert':
        return HttpResponse('''<script>alert("Unauthorized Access");window.location='/'</script>''')

    Name=request.POST['textfield']
    Date=request.POST['textfield2']
    Diet_charts=request.FILES['fileField3']
    BMI = request.POST['BMI']
    Alcoholabuse = request.POST['Alcoholabuse']
    Allergies = request.POST['Allergies']
    Arthritis = request.POST['Arthritis']
    Asthma = request.POST['Asthma']
    Bloodpressure = request.POST['Bloodpressure']
    Cancer = request.POST['Cancer']
    Cholestrol = request.POST['Cholestrol']
    Depression = request.POST['Depression']
    Diabetes = request.POST['Diabetes']
    Druguse = request.POST['Druguse']
    Gender = request.POST['Gender']
    Headaches = request.POST['Headaches']
    Heartproblem = request.POST['Heartproblem']
    Kidney = request.POST['Kidney']
    Liver = request.POST['Liver']
    Obicity = request.POST['Obicity']
    Pregnancy = request.POST['Pregnancy']
    Smoking = request.POST['Smoking']
    Stroke = request.POST['Stroke']

    yobj=Diet_chart()
    yobj.Name=Name
    yobj.Date=Date

    fs = FileSystemStorage()
    date = datetime.datetime.now().strftime("%Y%m%d-%H%M%S") + ".jpg"
    fn = fs.save(date, Diet_charts)
    path = fs.url(date)
    yobj.Dietplan=path
    yobj.Time= datetime.datetime.now().strftime("%H:%M:%S")
    yobj.BMI=BMI
    yobj.Alcoholabuse=Alcoholabuse
    yobj.Allergies=Allergies
    yobj.Arthritis=Arthritis
    yobj.Asthma=Asthma
    yobj.Bloodpressure=Bloodpressure
    yobj.Cancer=Cancer
    yobj.Cholestrol=Cholestrol
    yobj.Depression=Depression
    yobj.Diabetes=Diabetes
    yobj.Druguse=Druguse
    yobj.Gender=Gender
    yobj.Headaches=Headaches
    yobj.Heartproblem=Heartproblem
    yobj.Kidney=Kidney
    yobj.Liver=Liver
    yobj.Obicity=Obicity
    yobj.Pregnancy=Pregnancy
    yobj.bmi=BMI
    yobj.Smoking=Smoking
    yobj.Stroke=Stroke
    yobj.save()

    return HttpResponse('''<script>alert('diet add');window.location="/add_diet_chart"</script>''')


def View_diet_chart(request):
    if request.session.get('lid','') == '':
        return HttpResponse('''<script>alert('logout succesfull');window.location="/"</script>''')
    if request.session.get('type') != 'expert':
        return HttpResponse('''<script>alert("Unauthorized Access");window.location='/'</script>''')

    k = Diet_chart.objects.all()
    return render(request, "expert/view_diet_chart.html", {'data': k})


def View_diet_chart_post(request):
    if request.session.get('lid','') == '':
        return HttpResponse('''<script>alert('logout succesfull');window.location="/"</script>''')
    if request.session.get('type') != 'expert':
        return HttpResponse('''<script>alert("Unauthorized Access");window.location='/'</script>''')

    search = request.POST['textfield']
    u = Diet_chart.objects.filter(Name__icontains=search)
    return render(request, "expert/view_diet_chart.html", {'data': u})


def delete_diet_chart(request,id):
    if request.session.get('type') != 'expert':
        return HttpResponse('''<script>alert("Unauthorized Access");window.location='/'</script>''')
    
    Diet_chart.objects.filter(id=id).delete()
    return HttpResponse('''<script>alert('Deleted');window.location="/View_diet_chart"</script>''')


def Edit_diet_chart(request,id):
    if request.session.get('lid','') == '':
        return HttpResponse('''<script>alert('logout succesfull');window.location="/"</script>''')
    if request.session.get('type') != 'expert':
        return HttpResponse('''<script>alert("Unauthorized Access");window.location='/'</script>''')

    oi= Diet_chart.objects.get(id=id)
    return render(request,"expert/Edit_diet_chart.html",{'data':oi,'id':id})


def Edit_diet_chart_post(request):
    if request.session.get('lid','') == '':
        return HttpResponse('''<script>alert('logout succesfull');window.location="/"</script>''')
    if request.session.get('type') != 'expert':
        return HttpResponse('''<script>alert("Unauthorized Access");window.location='/'</script>''')

    id = request.POST['id']
    Name = request.POST['textfield']
    Date = request.POST['textfield2']

    BMI = request.POST['BMI']
    Alcoholabuse = request.POST['Alcoholabuse']
    Allergies = request.POST['Allergies']
    Arthritis = request.POST['Arthritis']
    Asthma = request.POST['Asthma']
    Bloodpressure = request.POST['Bloodpressure']
    Cancer = request.POST['Cancer']
    Cholestrol = request.POST['Cholestrol']
    Depression = request.POST['Depression']
    Diabetes = request.POST['Diabetes']
    Druguse = request.POST['Druguse']
    Gender = request.POST['Gender']
    Headaches = request.POST['Headaches']
    Heartproblem = request.POST['Heartproblem']
    Kidney = request.POST['Kidney']
    Liver = request.POST['Liver']
    Obicity = request.POST['Obicity']
    Pregnancy = request.POST['Pregnancy']
    Smoking = request.POST['Smoking']
    Stroke = request.POST['Stroke']

    if 'fileField3' in request.FILES:
        Diet_charts = request.FILES['fileField3']

        fs = FileSystemStorage()
        date = datetime.datetime.now().strftime("%Y%m%d-%H%M%S") + ".jpg"
        fn = fs.save(date, Diet_charts)
        path = fs.url(date)
        Diet_chart.objects.filter(id=id).update(Name=Name, Date=Date, Dietplan=path, bmi=BMI, Alcoholabuse=Alcoholabuse,
                                                Allergies=Allergies, Arthritis=Arthritis, Asthma=Asthma, Bloodpressure=Bloodpressure, Cancer=Cancer,
                                                Cholestrol=Cholestrol,Depression=Depression,Diabetes=Diabetes,Druguse=Druguse,Gender=Gender,
                                                Headaches=Headaches,Heartproblem=Heartproblem,Kidney=Kidney,Liver=Liver,Obicity=Obicity,
                                                Pregnancy=Pregnancy,Smoking=Smoking,Stroke=Stroke)
    else:
        Diet_chart.objects.filter(id=id).update(Name=Name, Date=Date, bmi=BMI,
                                                Alcoholabuse=Alcoholabuse,
                                                Allergies=Allergies, Arthritis=Arthritis, Asthma=Asthma,
                                                Bloodpressure=Bloodpressure, Cancer=Cancer,
                                                Cholestrol=Cholestrol, Depression=Depression, Diabetes=Diabetes,
                                                Druguse=Druguse, Gender=Gender,
                                                Headaches=Headaches, Heartproblem=Heartproblem, Kidney=Kidney,
                                                Liver=Liver, Obicity=Obicity,
                                                Pregnancy=Pregnancy, Smoking=Smoking, Stroke=Stroke)

    return HttpResponse('''<script>alert('Done');window.location='/View_diet_chart'</script>''')


def flutter_login(request):
    username = request.POST['username']
    password = request.POST['psw']

    a = Login.objects.filter(username=username, password=password)
    if a.exists():
        b = Login.objects.get(username=username, password=password)

        if b.type == 'user':
            user = User.objects.get(LOGIN_id=b.id)

            return JsonResponse({
                "status": "ok",
                "lid": str(b.id),
                "type": "user",
                "name": user.Name
            })
        else:
            return JsonResponse({"status": "no"})
    else:
        return JsonResponse({"status": "no"})


def user_reg(request):
    name=request.POST['name']
    dob=request.POST['dob']
    email=request.POST['email']
    place=request.POST['place']
    gender=request.POST['gender']
    district=request.POST['district']
    post=request.POST['post']
    pin=request.POST['pin']
    phone=request.POST['phone']
    password=request.POST['password']
    bloodtype=request.POST['bloodtype']
    photo=request.FILES['image']
    fs=FileSystemStorage()
    path=fs.save(photo.name,photo)

    aa=Login.objects.filter(username=email)
    if aa.exists():
        return JsonResponse({"status": "not ok"})

    lobj = Login()
    lobj.username = email
    lobj.password = password
    lobj.type = 'user'
    lobj.save()

    f = User()
    f.Name = name
    f.Gender = gender
    f.Place = place
    f.Pin = pin
    f.Post = post
    f.Bloodtype = bloodtype
    f.Photo = path
    f.Email = email
    f.Phone = phone
    f.LOGIN = lobj
    f.District = district
    f.Dob = dob
    f.save()

    return JsonResponse({"status": "ok"})


def view_diet_charts(request):
    mdata = []
    diet_charts = Diet_chart.objects.all()
    for i in diet_charts:
        data = {
            'name': i.Name,
            'date': i.Date,
            'time': i.Time,
            'dietplan': i.Dietplan,
            'gender': i.Gender,
            'obicity': i.Obicity,
            'bloodpressure': i.Bloodpressure,
            'diabetes': i.Diabetes,
            'cholestrol': i.Cholestrol,
            'alcoholabuse': i.Alcoholabuse,
            'druguse': i.Druguse,
            'smoking': i.Smoking,
            'headaches': i.Headaches,
            'asthma': i.Asthma,
            'heartproblem': i.Heartproblem,
            'cancer': i.Cancer,
            'stroke': i.Stroke,
            'kidney': i.Kidney,
            'liver': i.Liver,
            'depression': i.Depression,
            'allergies': i.Allergies,
            'arthritis': i.Arthritis,
            'pregnancy': i.Pregnancy,
            'bmi': i.bmi
        }
        mdata.append(data)
    print(mdata)
    return JsonResponse({"status": "ok", "data": mdata})


def cosine_similarity(list1, list2):
    vector1 = np.array(list1)
    vector2 = np.array(list2)
    dot_product = np.dot(vector1, vector2)
    magnitude1 = np.linalg.norm(vector1)
    magnitude2 = np.linalg.norm(vector2)
    similarity = dot_product / (magnitude1 * magnitude2)
    return similarity


def predict_diet(request):
    if request.method != 'POST':
        return JsonResponse({'status': 'error', 'message': 'Invalid HTTP method'}, status=405)

    try:
        data = json.loads(request.body)

        gender = data.get('Gender', '')
        obesity = data.get('Obicity', '')
        alcohol_abuse = data.get('Alcoholabuse', '')
        drug_use = data.get('Druguse', '')
        smoking = data.get('Smoking', '')
        headaches = data.get('Headaches', '')
        asthma = data.get('Asthma', '')
        cancer = data.get('Cancer', '')
        stroke = data.get('Stroke', '')
        kidney = data.get('Kidney', '')
        liver = data.get('Liver', '')
        depression = data.get('Depression', '')
        allergies = data.get('Allergies', '')
        arthritis = data.get('Arthritis', '')
        pregnancy = data.get('Pregnancy', '')
        bmi = data.get('BMI', '')
        blood_pressure = data.get('BloodPressure', '')

        qry = (
            f"Gender: {gender}. Obesity: {obesity}. "
            f"Alcohol abuse: {alcohol_abuse}. Drug use: {drug_use}. "
            f"Smoking: {smoking}. Headaches: {headaches}. Asthma: {asthma}. "
            f"Cancer: {cancer}. Stroke: {stroke}. Kidney: {kidney}. Liver: {liver}. "
            f"Depression: {depression}. Allergies: {allergies}. Arthritis: {arthritis}. "
            f"Pregnancy: {pregnancy}. BMI: {bmi}. Blood Pressure: {blood_pressure}. "
            f"Give me the best diet plan for the next 7 days."
        )

        ai_result = generate_gemini_response(qry)

        dc = Diet_chart.objects.all()
        if not dc:
            return JsonResponse(
                {'status': 'ok', 'dietPlans': [], 'result': ai_result, 'message': 'No diets in database'}
            )

        lookup = {
            'Gender': [], 'Obicity': [], 'Bloodpressure': [], 'Alcoholabuse': [], 'Druguse': [],
            'Asthma': [], 'Headaches': [], 'Liver': [], 'Stroke': [], 'Kidney': [], 'Depression': [],
            'Allergies': [], 'Pregnancy': [], 'Smoking': [], 'Cancer': []
        }

        dataset = []
        ids = []

        for item in dc:
            vector = []
            for field in lookup.keys():
                value = getattr(item, field)
                if value not in lookup[field]:
                    lookup[field].append(value)
                vector.append(lookup[field].index(value))

            try:
                vector.append(float(item.bmi))
            except:
                vector.append(-1)

            dataset.append(vector)
            ids.append(item.id)

        feature = []
        for field, value in [
            ('Gender', gender), ('Obicity', obesity), ('Bloodpressure', blood_pressure),
            ('Alcoholabuse', alcohol_abuse), ('Druguse', drug_use), ('Asthma', asthma),
            ('Headaches', headaches), ('Liver', liver), ('Stroke', stroke), ('Kidney', kidney),
            ('Depression', depression), ('Allergies', allergies), ('Pregnancy', pregnancy),
            ('Smoking', smoking), ('Cancer', cancer)
        ]:
            try:
                feature.append(lookup[field].index(value))
            except:
                feature.append(-1)

        try:
            feature.append(float(bmi))
        except:
            feature.append(-1)

        scores = []
        for i in range(len(dataset)):
            score = cosine_similarity(feature, dataset[i])
            scores.append({'id': ids[i], 'score': score})

        scores = sorted(scores, key=lambda x: x['score'], reverse=True)[:3]
        best_ids = [x['id'] for x in scores]

        results = []
        for d in Diet_chart.objects.filter(id__in=best_ids):
            results.append({
                'name': d.Name,
                'dietplan': d.Dietplan,
                'date': d.Date,
                'time': d.Time,
                'gender': d.Gender,
                'obicity': d.Obicity,
                'bloodpressure': d.Bloodpressure,
                'bmi': d.bmi
            })

        return JsonResponse({'status': 'ok', 'dietPlans': results, 'result': ai_result})

    except Exception as e:
        traceback.print_exc()
        return JsonResponse({'status': 'error', 'message': str(e)}, status=500)


def user_view_expert(request):
    a=Experts.objects.all()
    l=[]
    for i in a:
        l.append({
            'id':i.id,'image':i.image,'name':i.name,'place':i.place,'LOGIN':str(i.LOGIN.id),
        })
    print(l)
    return JsonResponse({
        'status':'ok','data':l
    })


def send_complaint(request):
    lid=request.POST['lid']
    complaint=request.POST['complaint']

    a=Complaints()
    a.USER=User.objects.get(LOGIN_id=lid)
    a.complaints=complaint
    a.date=datetime.datetime.now().today().date()
    a.reply='pending'
    a.save()
    return JsonResponse({"status": "ok"})


def user_view_reply(request):
    lid=request.POST['lid']
    a=Complaints.objects.filter(USER__LOGIN_id=lid)
    l=[]
    for i in a:
        l.append({'id': i.id,
                  'complaint': i.complaints,
                  'reply': i.reply,
                  'date': str(i.date) })
    return JsonResponse({"status": "ok",'data':l})


def send_feedback(request):
    lid=request.POST['lid']
    eid=request.POST['eid']
    feedback=request.POST['feedback']
    rating=request.POST['rating']

    a=Expertfeedback()
    a.USER=User.objects.get(LOGIN_id=lid)
    a.EXPERT=Experts.objects.get(id=eid)
    a.feedback=feedback
    a.rating=rating
    a.date=datetime.datetime.now().today().date()
    a.save()
    return JsonResponse({"status": "ok"})


def add_water(request):
    lid=request.POST['lid']
    type=request.POST['type']
    alert=request.POST['alert']

    a=Water()
    a.USER=User.objects.get(LOGIN_id=lid)
    a.type=type
    a.alert=alert
    a.date=datetime.datetime.now().today()
    a.save()
    return JsonResponse({"status": "ok"})


def user_view_waterlo(request):
    lid=request.POST['lid']
    l=[]
    a=Water.objects.filter(USER__LOGIN_id=lid)
    for i in a:
        l.append({
            'id':i.id,'type':i.type,'alert':i.alert,'date':str(i.date)
        })
    return JsonResponse({"status": "ok",'data':l})


def delete_water_log(request):
    wid=request.POST['wid']
    a=Water.objects.get(id=wid)
    a.delete()
    return JsonResponse({"status": "ok"})


from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from .models import *
import datetime

@csrf_exempt
def add_food(request):
    try:
        if request.method == "POST":
            lid = request.POST.get('lid')
            name = request.POST.get('name')  # ✅ added
            type_ = request.POST.get('type')
            gram = request.POST.get('gram')
            date = request.POST.get('date')

            print("DATA:", lid, name, type_, gram, date)

            # ✅ Validation
            if not all([lid, name, type_, gram, date]):
                return JsonResponse({
                    "status": "error",
                    "message": "Missing fields"
                })

            # ✅ Safe user fetch
            user = User.objects.filter(LOGIN_id=lid).first()
            if not user:
                return JsonResponse({
                    "status": "error",
                    "message": "Invalid user"
                })

            # ✅ Convert values safely
            gram = float(gram)

            # ✅ Convert date
            try:
                date_obj = datetime.datetime.strptime(date, "%Y-%m-%d").date()
            except:
                date_obj = datetime.date.today()
                
                

            # ✅ Save
            a = Food()
            a.USER = user
            a.name = name
            a.type = type_
            a.gram = gram
            a.callorie = gram
            a.date = date_obj
            a.save()

            return JsonResponse({"status": "ok"})

        return JsonResponse({"status": "error", "message": "Invalid request"})

    except Exception as e:
        print("ERROR:", str(e))  # 🔥 VERY IMPORTANT
        return JsonResponse({
            "status": "error",
            "message": str(e)
        })
        


# ✅ DELETE (SAFE VERSION)
@csrf_exempt
def delete_food_log(request):
    try:
        wid = request.POST.get('wid')

        food = Food.objects.filter(id=wid).first()
        if not food:
            return JsonResponse({"status": "error", "message": "Food not found"})

        food.delete()
        return JsonResponse({"status": "ok"})

    except Exception as e:
        print("ERROR:", str(e))
        return JsonResponse({"status": "error", "message": str(e)})


# ✅ VIEW (SAFE VERSION)
@csrf_exempt
def user_view_foodlo(request):
    try:
        lid = request.POST.get('lid')

        foods = Food.objects.filter(USER__LOGIN_id=lid)

        data = []
        for i in foods:
            data.append({
                'id': i.id,
                'name': getattr(i, 'name', ''),  # safe
                'type': i.type,
                'gram': str(i.gram),
                'date': str(i.date),
                'callorie': str(i.callorie)
            })

        return JsonResponse({"status": "ok", "data": data})

    except Exception as e:
        print("ERROR:", str(e))
        return JsonResponse({"status": "error", "message": str(e)})

@csrf_exempt
def user_viewchat(request):
    from_id = request.POST.get("from_id")
    to_id   = request.POST.get("to_id")
 
    if not from_id or not to_id:
        return JsonResponse({"status": "error", "message": "Missing parameters"})
 
    chats = Chat.objects.filter(
        Q(FROMID_id=from_id, TOID_id=to_id) |
        Q(FROMID_id=to_id,   TOID_id=from_id)
    ).order_by("id")
 
    data = []
    for c in chats:
        data.append({
            "id":       c.id,
            "msg":      c.message,
            "from_id":  str(c.FROMID_id),
            "to_id":    str(c.TOID_id),
            "date":     c.date.strftime("%Y-%m-%d"),
            "msg_type": getattr(c, "msg_type", "text") or "text",  # safe fallback
        })
 
    return JsonResponse({"status": "success", "data": data})

@csrf_exempt
def user_sendchat(request):
    from_id = request.POST.get("from_id")
    to_id = request.POST.get("to_id")
    message = request.POST.get("message")

    if not from_id or not to_id or not message:
        return JsonResponse({"status": "error", "message": "Missing fields"})

    Chat.objects.create(
        FROMID_id=from_id,
        TOID_id=to_id,
        message=message,
        date=timezone.now().date()
    )

    return JsonResponse({"status": "success", "message": "sent"})


@csrf_exempt
def user_viewchat(request):
    from_id = request.POST.get("from_id")
    to_id = request.POST.get("to_id")
    if not from_id or not to_id:
        return JsonResponse({"status": "error", "message": "Missing parameters"})
    chats = Chat.objects.filter(
        Q(FROMID_id=from_id, TOID_id=to_id) |
        Q(FROMID_id=to_id, TOID_id=from_id)
    ).order_by("id")
    data = []
    for c in chats:
        data.append({
            "id": c.id,
            "msg": c.message,
            "from_id": str(c.FROMID_id),
            "to_id": str(c.TOID_id),
            "date": c.date.strftime("%Y-%m-%d"),
            "msg_type": getattr(c, "msg_type", "text") or "text",
        })
    return JsonResponse({"status": "success", "data": data})


@csrf_exempt
def user_sendchat(request):
    from_id = request.POST.get("from_id")
    to_id = request.POST.get("to_id")
    message = request.POST.get("message")
    if not from_id or not to_id or not message:
        return JsonResponse({"status": "error", "message": "Missing fields"})
    Chat.objects.create(
        FROMID_id=from_id,
        TOID_id=to_id,
        message=message,
        date=timezone.now().date()
    )
    return JsonResponse({"status": "success", "message": "sent"})


@csrf_exempt
def user_sendchat_image(request):
    if request.method != "POST":
        return JsonResponse({"status": "error", "message": "POST required"})
    from_id = request.POST.get("from_id")
    to_id = request.POST.get("to_id")
    image = request.FILES.get("image")
    if not from_id or not to_id:
        return JsonResponse({"status": "error", "message": "Missing from_id or to_id"})
    if not image:
        return JsonResponse({"status": "error", "message": "No image file received"})
    try:
        fs = FileSystemStorage()
        ext = image.name.rsplit(".", 1)[-1] if "." in image.name else "jpg"
        filename = datetime.datetime.now().strftime("%Y%m%d-%H%M%S%f") + "." + ext
        fs.save(filename, image)
        path = fs.url(filename)
        Chat.objects.create(
            FROMID_id=from_id,
            TOID_id=to_id,
            message=path,
            msg_type="image",
            date=timezone.now().date()
        )
        return JsonResponse({"status": "success", "url": path})
    except Exception as e:
        traceback.print_exc()
        return JsonResponse({"status": "error", "message": str(e)})


def chat_view(request):
    expert_id = request.session.get("lid")
    user_id   = request.session.get("userid")

    if not expert_id or not user_id:
        return JsonResponse({"status": "error", "message": "Missing session IDs"})

    chats = Chat.objects.filter(
        Q(FROMID_id=expert_id, TOID_id=user_id) |
        Q(FROMID_id=user_id,   TOID_id=expert_id)
    ).order_by("id")

    user = User.objects.get(LOGIN_id=user_id)

    data = []
    for c in chats:
        data.append({
            "id":       c.id,
            "message":  c.message,
            "from":     str(c.FROMID_id),
            "to":       str(c.TOID_id),
            "date":     c.date.strftime("%Y-%m-%d"),
            "msg_type": getattr(c, "msg_type", "text") or "text",
        })

    return JsonResponse({
        "status":  "success",
        "data":    data,
        "name":    user.Name,
        "photo":   user.Photo.url if user.Photo else "",
        "toid":    str(user_id),
        "fromid":  str(expert_id),   # ← needed for Jitsi room name on web side
    })

def chat_send(request, msg):
    expert_id = request.session.get("lid")
    user_id = request.session.get("userid")
    if not expert_id or not user_id:
        return JsonResponse({"status": "error", "message": "Missing session IDs"})
    Chat.objects.create(
        FROMID_id=expert_id,
        TOID_id=user_id,
        message=msg,
        date=timezone.now().date()
    )
    return JsonResponse({"status": "success"})

from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
import datetime

# ✅ Define this globally (top of file)
calories_per_gram = {
    "rice": 1.3,
    "chicken": 2.4,
    "apple": 0.52,
    "banana": 0.89,
    "egg": 1.55,
    "milk": 0.64,
}

@csrf_exempt
def user_add_food(request):
    try:
        print("Request Data:", request.POST)

        # ✅ Get data safely
        lid = request.POST.get('lid')
        food_type = request.POST.get('type')
        food_name = request.POST.get('name')
        gram = request.POST.get('gram')

        # ✅ Validate inputs
        if not all([lid, food_type, food_name, gram]):
            return JsonResponse({
                "status": "error",
                "message": "Missing fields"
            })

        # ✅ Safe conversion
        try:
            gram = int(gram)
        except:
            return JsonResponse({
                "status": "error",
                "message": "Invalid gram value"
            })

        # ✅ Get user safely
        user = User.objects.filter(LOGIN_id=lid).first()
        if not user:
            return JsonResponse({
                "status": "error",
                "message": "Invalid user"
            })

        # ✅ Calories calculation
        food_key = food_name.lower()

        if food_key in calories_per_gram:
            calories = int(calories_per_gram[food_key] * gram)
        else:
            try:
                # 🔥 FIXED f-string
                cal_val = float(getcalval(f"100 gm {food_name}"))
                calories = int((cal_val / 100) * gram)
            except Exception as e:
                print("API ERROR:", e)
                calories = gram  # fallback (no crash)

        # ✅ Save food
        food = Food(
            USER=user,
            type=food_type,
            name=food_name,
            gram=gram,
            callorie=calories,
            date=datetime.date.today(),
        )
        food.save()

        return JsonResponse({
            "status": "ok",
            "calories": calories
        })

    except Exception as e:
        print("ERROR:", str(e))
        return JsonResponse({
            "status": "error",
            "message": str(e)
        })


def user_view_take_calorie(request):
    lid = request.POST['lid']
    date = datetime.datetime.now().date()
    total_calories = 0
    l = []
    a = Food.objects.filter(USER__LOGIN_id=lid, date=date)
    for i in a:
        total_calories += i.callorie
        l.append({
            'id': i.id,
            'type': i.type,
            'gram': str(i.gram),
            'date': str(i.date),
            'callorie': str(i.callorie)
        })
    return JsonResponse({"status": "ok", 'data': l, 'total_calories': total_calories})


@csrf_exempt
def chatbot_response(request):
    if request.method == 'POST':
        try:
            data = json.loads(request.body)
            user_message = data.get('message', '').strip()
            if not user_message:
                return JsonResponse({'response': 'Please enter a valid message'})
            ai_reply = generate_gemini_response(user_message)
            return JsonResponse({'response': ai_reply})
        except json.JSONDecodeError:
            return JsonResponse({'response': 'Invalid JSON format'}, status=400)
        except Exception as e:
            return JsonResponse({'response': str(e)}, status=500)
    return JsonResponse({'response': 'Invalid request method. Use POST'}, status=405)


@csrf_exempt
def create_order(request):
    try:
        payer_id = request.POST.get("user_id")
        expert_id = request.POST.get("expert_id")
        if not payer_id or not expert_id:
            return JsonResponse({"status": "error", "message": "Missing user/expert ID"})

        amount_rupees = 1099
        amount_paise = amount_rupees * 100

        client = razorpay.Client(
            auth=(settings.RAZORPAY_KEY_ID, settings.RAZORPAY_KEY_SECRET)
        )
        order = client.order.create({
            "amount": amount_paise,
            "currency": "INR",
            "payment_capture": 1
        })

        expires = timezone.now() + timedelta(days=1)
        PaymentAccess.objects.create(
            payer_id=payer_id,
            expert_id=expert_id,
            order_id=order["id"],
            amount=amount_paise,
            expires_at=expires,
            is_active=False
        )
        return JsonResponse({
            "status": "success",
            "order_id": order["id"],
            "amount": amount_paise,
            "key": settings.RAZORPAY_KEY_ID
        })
    except Exception as e:
        traceback.print_exc()
        return JsonResponse({"status": "error", "message": str(e)})


@csrf_exempt
def verify_payment(request):
    try:
        order_id = request.POST.get("order_id")
        payment_id = request.POST.get("payment_id")
        signature = request.POST.get("signature")

        if not order_id or not payment_id or not signature:
            return JsonResponse({"status": "error", "message": "Missing parameters"})

        payment = PaymentAccess.objects.filter(order_id=order_id).first()
        if not payment:
            return JsonResponse({"status": "error", "message": "Order not found"})

        body = order_id + "|" + payment_id
        generated = hmac.new(
            settings.RAZORPAY_KEY_SECRET.encode(),
            body.encode(),
            hashlib.sha256
        ).hexdigest()

        if generated != signature:
            payment.is_active = False
            payment.save()
            return JsonResponse({"status": "error", "message": "Signature mismatch"})

        payment.payment_id = payment_id
        payment.signature = signature
        payment.is_active = True
        payment.activate_for_days(days=1)
        payment.save()
        return JsonResponse({"status": "success", "message": "Payment verified"})
    except Exception as e:
        traceback.print_exc()
        return JsonResponse({"status": "error", "message": str(e)})


@csrf_exempt
def check_chat_access(request):
    try:
        user_id = request.POST.get("user_id")
        expert_id = request.POST.get("expert_id")

        if not user_id or not expert_id:
            return JsonResponse({"status": "error", "message": "Missing user/expert ID"})

        access = PaymentAccess.objects.filter(
            payer_id=user_id,
            expert_id=expert_id
        ).order_by("-id").first()

        if not access:
            return JsonResponse({"status": "no_access", "message": "No payment found"})

        if not access.is_valid_now():
            if access.is_active:
                access.is_active = False
                access.save(update_fields=["is_active"])
            return JsonResponse({
                "status": "expired",
                "message": "Access expired",
                "expires_at": access.expires_at.isoformat() if access.expires_at else None
            })

        return JsonResponse({
            "status": "allowed",
            "message": "Access granted",
            "expires_at": access.expires_at.isoformat() if access.expires_at else None
        })
    except Exception as e:
        traceback.print_exc()
        return JsonResponse({"status": "error", "message": str(e)})
    
def chat_send_image(request):
    if request.method != "POST":
        return JsonResponse({"status": "error", "message": "POST required"})

    expert_id = request.session.get("lid")
    user_id   = request.session.get("userid")

    if not expert_id or not user_id:
        return JsonResponse({"status": "error", "message": "Missing session IDs"})

    image = request.FILES.get("image")
    if not image:
        return JsonResponse({"status": "error", "message": "No image received"})

    try:
        fs       = FileSystemStorage()
        ext      = image.name.rsplit(".", 1)[-1] if "." in image.name else "jpg"
        filename = datetime.datetime.now().strftime("%Y%m%d-%H%M%S%f") + "." + ext
        fs.save(filename, image)
        path = fs.url(filename)

        Chat.objects.create(
            FROMID_id=expert_id,
            TOID_id=user_id,
            message=path,
            msg_type="image",
            date=timezone.now().date()
        )
        return JsonResponse({"status": "success", "url": path})

    except Exception as e:
        traceback.print_exc()
        return JsonResponse({"status": "error", "message": str(e)})