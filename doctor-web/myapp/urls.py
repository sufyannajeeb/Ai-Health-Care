
from django.conf.urls.static import static
from django.contrib import admin
from django.urls import path, include

from doctor_web_app import settings
from myapp import views



urlpatterns = [
    path('', views.home, name='home'),
    path('loginindex', views.login, name='login'),
    path('logout',views.logout),
    path('admin_home',views.admin_home),
    path('expert_reg',views.expert_reg),
    path('admin_verify_expert',views.admin_verify_expert),
    path('admin_verify_expert_post',views.admin_verify_expert_post),
    path('admin_view_user',views.admin_view_user),
    path('admin_delete_expert/<id>',views.admin_delete_expert),
    path('admin_view_expert_feedback/<id>',views.admin_view_expert_feedback),
    path('admin_view_complaints',views.admin_view_complaints),
    path('assign_work',views.assign_work),
    path('admin_view_assign',views.admin_view_assign),
    path('admin_reply_post',views.admin_reply_post),
    path('delete_assign_work/<id>',views.delete_assign_work),
    path('admin_reply/<id>',views.admin_reply),


    path('expert_home',views.expert_home),
    path('expertview_user',views.expertview_user),
    path('chatwithuser',views.chatwithuser),
    path('expert_view_assignedwork',views.expert_view_assignedwork),
    path('expert_view_feedback',views.expert_view_feedback),
    path('expertchatview',views.expertchatview),
    # path('expertcoun_insert_chat/<str:msg>/<int:id>', views.expertcoun_insert_chat, name='expertcoun_insert_chat'),
    # path('expertcoun_msg/<int:id>', views.expertcoun_msg, name='expertcoun_msg'),

    path('add_diet_chart', views.add_diet_chart, name='add_diet_chart'),
    path('View_diet_chart', views.View_diet_chart, name='View_diet_chart'),
    path('View_diet_chart_post', views.View_diet_chart_post, name='View_diet_chart_post'),
    path('add_diet_chart_post', views.add_diet_chart_post, name='add_diet_chart_post'),
    path('delete_diet_chart/<id>', views.delete_diet_chart, name='delete_diet_chart'),
    path('Edit_diet_chart/<id>', views.Edit_diet_chart, name='Edit_diet_chart'),
    path('Edit_diet_chart_post', views.Edit_diet_chart_post, name='Edit_diet_chart_post'),


    # path('expert_chat_to_user/<int:id>', views.expert_chat_to_user, name='expert_chat_to_user'),
    # path('chat_view', views.chat_view, name='chat_view'),
    # path('chat_send/<msg>', views.chat_send, name='chat_send'),



    path('flutter_login', views.flutter_login, name='flutter_login'),
    path('user_reg', views.user_reg, name='user_reg'),
    path('view_diet_charts', views.view_diet_charts, name='view_diet_charts'),
    path('view_diet_charts', views.view_diet_charts, name='view_diet_charts'),
    path('predict_diet', views.predict_diet, name='predict_diet'),
    path('user_view_expert', views.user_view_expert, name='user_view_expert'),
    path('user_view_reply', views.user_view_reply, name='user_view_reply'),
    path('send_complaint', views.send_complaint, name='send_complaint'),
    # path('user_viewchat', views.user_viewchat, name='user_viewchat'),
    # path('user_sendchat', views.user_sendchat, name='user_sendchat'),
    path('send_feedback', views.send_feedback, name='send_feedback'),
    path('add_water', views.add_water, name='add_water'),
    path('user_view_waterlo', views.user_view_waterlo, name='user_view_waterlo'),
    path('delete_water_log', views.delete_water_log, name='delete_water_log'),
    path('add_food', views.add_food, name='add_food'),
    path('user_add_food', views.user_add_food, name='user_add_food'),
    path('user_view_foodlo', views.user_view_foodlo, name='user_view_foodlo'),
    path('delete_food_log', views.delete_food_log, name='delete_food_log'),
    path('user_view_take_calorie', views.user_view_take_calorie, name='user_view_take_calorie'),

    path('chatbot_response', views.chatbot_response, name='chatbot_response'),
    path('chat', views.chatbot_response),
    
    
    
    #Dev Neeraj New url's for chat feature
    path('user_viewchat', views.user_viewchat),
    path('user_sendchat', views.user_sendchat),
    path('user_sendchat_image', views.user_sendchat_image),
    path('chat_view', views.chat_view),
    path('chat_send/<str:msg>', views.chat_send),
    path('chat_send_image', views.chat_send_image),
    path('expert_chat_to_user/<int:id>', views.expert_chat_to_user, name='expert_chat_to_user'),
    
    #razor pay payment gateway url's Neeraj Dev
    path('create_order', views.create_order),
    path('verify_payment', views.verify_payment),
    path('check_chat_access', views.check_chat_access),
    
    #assingn_work
    path('assign_work/', views.assign_work, name='assign_work'),
    path('admin_view_assign/', views.admin_view_assign, name='admin_view_assign'),
    path('expert_view_assignedwork', views.expert_view_assignedwork, name='expert_view_assignedwork'),
    path('expert_view_work_details/<int:id>/', views.expert_view_work_details, name='expert_view_work_details'),       

]