"""SheCare URL Configuration

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/3.0/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.contrib import admin
from django.urls import path

from myapp import views

urlpatterns = [

    path('login/', views.login_get),
    path('login_post/', views.login_post),
    path('logout/',views.logout_view),
    ###### ADMIN #######
    path('admin_main_home/', views.admin_main_home),

    ### POLICE STATION
    path('view_police_station/', views.view_police_station),
    path('view_police_station_post/', views.view_police_station_post),
    path('add_policestation/',views.add_policestation),
    path('add_policestation_post/',views.add_policestation_post),
    path('edit_policestation/<id>',views.edit_policestation),
    path('edit_policestation_post/',views.edit_policestation_post),
    path('delete_police_station/<id>/', views.delete_police_station),

    ### SUBADMIN
    path('add_subadmin/', views.add_subadmin),
    path('add_subadmin_post/', views.add_subadmin_post),
    path('view_subadmin/', views.view_subadmin),
    path('edit_subadmin/<id>', views.edit_subadmin),
    path('edit_subadmin_post/', views.edit_subadmin_post),
    path('deleteSubAdmin/<id>', views.deleteSubAdmin),

    ### PINK POLICE
    path('view_pink_police/', views.view_pink_police),
    path('add_pinkpolice/', views.add_pinkpolice),
    path('add_pinkpolice_post/', views.add_pinkpolice_post),
    path('edit_pinkpolice/<id>', views.edit_pinkpolice),
    path('edit_pinkpolice_post/', views.edit_pinkpolice_post),
    path('delete_pinkpolice/<id>/', views.delete_pinkpolice),
    path('search_pinkpolice/', views.search_pinkpolice),

    ### NOTIFICATION
    path('send_notification/',views.send_notification),
    path('send_notification_post/', views.send_notification_post),
    path('admin_view_notification/', views.admin_view_notification),
    path('deleteNotification/<id>', views.deleteNotification),
    path('edit_notification/<id>', views.edit_notification),
    path('edit_notification_post/', views.edit_notification_post),
    path('admin_view_notification_post/', views.admin_view_notification_post),


    #### FEEDBACK
    path('view_publicfeedback_post/', views.view_publicfeedback_post),
    path('view_publicfeedback/', views.view_publicfeedback),

    #### USERS
    path('view_reg_users/', views.view_reg_users),
    path('view_reg_users_post/', views.view_reg_users_post),

    ################ SUBADMIN #####################
    path('subadminhome/',views.subadminhome),

    ### SAFEPOINT
    path('add_safepoint/', views.add_safepoint),
    path('add_safepoint_post/', views.add_safepoint_post),

    path('view_safepoint/', views.view_safepoint),
    path('edit_safepoint/<id>', views.edit_safepoint),
    path('edit_safepoint_post/', views.edit_safepoint_post),
    path('delete_safepoint/<id>', views.delete_safepoint),

    ### DANGEROUS SPOT
    path('view_dangerous_spot/', views.view_dangerous_spot),
    path('view_dangerous_spot_sub/',views.view_dangerous_spot_sub),
    path('view_dangerous_spot_post/', views.view_dangerous_spot_post),
    path('approve_dangerous_spot/<id>', views.approve_dangerous_spot),
    path('reject_dangerous_spot/<id>', views.reject_dangerous_spot),
    path('view_approved_dangerous_spot/', views.view_approved_dangerous_spot),
    path('view_approved_dangerous_spot_post/', views.view_approved_dangerous_spot_post),
    path('view_rejected_dangerous_spot/', views.view_rejected_dangerous_spot),
    path('view_rejected_dangerous_spot_post/', views.view_rejected_dangerous_spot_post),

    ### FEEDBACK
    path('sub_view_public_feedback/', views.sub_view_public_feedback),
    path('sub_view_publicfeedback_post/', views.sub_view_publicfeedback_post),
    path('user_chatbot/',views.user_chatbot),



################ PINK POLICE ###################


path('pinkpolice_view_emergency/', views.pinkpolice_view_emergency),
    path('add_dangerous_spot/', views.add_dangerous_spot),

    path('pinkpolice_view_dangerous_spot/', views.pinkpolice_view_dangerous_spot),

    path('view_complaint/', views.view_complaint),
    path('send_reply/', views.send_reply),
path('pinkpolice_change_password/', views.pinkpolice_change_password),

    path('pinkpolice_view_profile/', views.pinkpolice_view_profile),




    ### USER
    path('subadmin_view_reg_users/', views.subadmin_view_reg_users),
path('add_idea/', views.add_idea),

path('send_complaint/', views.send_complaint),
path('user_view_reply/', views.user_view_reply),
    path('user_view_pink_police/', views.user_view_pink_police),
path('user_change_password/', views.user_change_password),
path('view_profile/', views.view_profile),
path('update_profile/', views.update_profile),
path('update_profile_photo/', views.update_profile_photo),
path('update_location/', views.update_location),
path('view_nearby_users/', views.view_nearby_users),
path('add_dangerous_spot/', views.add_dangerous_spot),
path('user_view_dangerous_spot/', views.user_view_dangerous_spot),
path('user_update_dangerous_spot/', views.user_update_dangerous_spot),
path('user_delete_dangerous_spot/', views.user_delete_dangerous_spot),
path("user_send_emergency_request/", views.user_send_emergency),
path("pinkpolice_view_emergency/", views.pinkpolice_view_emergency),

path('user_view_safepoints/', views.user_view_safepoints),
    path('user_view_nearbyDangerosSpot/',views.user_view_nearbyDangerosSpot),


    path('pinkpolice_login/', views.pinkpolice_login),
    path('user_registration/', views.user_registration),
    path('user_add_emergency_number/', views.user_add_emergency_number),
    path('user_view_emergency_number/', views.user_view_emergency_number),
    path('user_edit_emergency_number/', views.user_edit_emergency_number),
    path('delete_emergency_number/', views.delete_emergency_number),
    path('delete_emergency_number/', views.delete_emergency_number),
    path('recordings/',views.recordings),
    path('predict-motion/', views.predict_motion, name='predict_motion'),
    path('updatelocation/',views.updatelocation),
    path('get-motion-history/',views.get_motion_history),
path("send_false_alarm/", views.send_false_alarm),

    path('view_all_ideas/', views.view_all_ideas),
    path('view_my_ideas/', views.view_my_ideas),
    path('edit_idea/', views.edit_idea),
    path('delete_idea/', views.delete_idea),

]
