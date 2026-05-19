"""safe_path_web URL Configuration

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
    path('admin/', admin.site.urls),

    path('', views.logg),
    path('login_post', views.login_post),
    path('logoutt', views.logoutt),



    path('admin_home', views.admin_home),
    path('adm_add_police_station', views.adm_add_police_station),
    path('adm_add_police_station_post', views.adm_add_police_station_post),
    path('adm_view_police_station', views.adm_view_police_station),
    path('adm_delete_police_station/<id>', views.adm_delete_police_station),
    path('adm_edit_police_station/<id>', views.adm_edit_police_station),
    path('adm_edit_police_station_post/<id>', views.adm_edit_police_station_post),
    path('adm_verify_police_officer', views.adm_verify_police_officer),
    path('adm_approve_police_officer/<id>', views.adm_approve_police_officer),
    path('adm_reject_police_officer/<id>', views.adm_reject_police_officer),
    path('adm_view_verified_police_officer', views.adm_view_verified_police_officer),
    path('adm_view_users', views.adm_view_users),
    path('adm_view_false_reportings', views.adm_view_false_reportings),
    path('adm_block_user/<id>', views.adm_block_user),
    path('adm_unblock_user/<id>', views.adm_unblock_user),



    path('pol_register', views.pol_register),
    path('pol_register_post', views.pol_register_post),
    path('police_home', views.police_home),
    path('pol_view_profile', views.pol_view_profile),
    path('pol_edit_profile', views.pol_edit_profile),
    path('pol_add_dangerous_spot', views.pol_add_dangerous_spot),
    path('pol_add_dangerous_spot_post', views.pol_add_dangerous_spot_post),
    path('pol_view_dangerous_spot', views.pol_view_dangerous_spot),
    path('pol_delete_dangerous_spot/<id>', views.pol_delete_dangerous_spot),
    path('pol_edit_dangerous_spot/<id>', views.pol_edit_dangerous_spot),
    path('pol_edit_dangerous_spot_post/<id>', views.pol_edit_dangerous_spot_post),
    path('pol_add_safe_point', views.pol_add_safe_point),
    path('pol_add_safe_point_post', views.pol_add_safe_point_post),
    path('pol_view_safe_point', views.pol_view_safe_point),
    path('pol_delete_safe_point/<id>', views.pol_delete_safe_point),
    path('pol_edit_safe_point/<id>', views.pol_edit_safe_point),
    path('pol_edit_safe_point_post/<id>', views.pol_edit_safe_point_post),
    path('pol_view_reported_dangerous_spot', views.pol_view_reported_dangerous_spot),
    path('pol_verify_spot/<id>', views.pol_verify_spot),
    path('pol_report_false_spot/<id>', views.pol_report_false_spot),
    path('pol_view_emergency_request', views.pol_view_emergency_request),
    path('pol_update_emergeny_request/<id>', views.pol_update_emergeny_request),
    path('pol_change_password', views.pol_change_password),
    path('pol_change_password_post', views.pol_change_password_post),


    path('user_registration', views.user_registration),
    path('user_login/', views.user_login),
    path('updatelocation/', views.updatelocation),
    path('user_view_nearbyDangerosSpot/', views.user_view_nearbyDangerosSpot),
    path('add_dangerous_spot/', views.add_dangerous_spot),
    path('user_view_dangerous_spot/', views.user_view_dangerous_spot),
    path('user_update_dangerous_spot/', views.user_update_dangerous_spot),
    path('user_delete_dangerous_spot/', views.user_delete_dangerous_spot),
    path('user_view_profile/', views.user_view_profile),
    path('update_profile/', views.update_profile),
    path('user_view_safepoints/', views.user_view_safepoints),
    path('view_nearby_users/', views.view_nearby_users),
    path('add_user_journey/', views.add_user_journey, name='add_user_journey'),
    path('view_user_journeys/', views.view_user_journeys, name='view_user_journeys'),
    path('delete_user_journey/', views.delete_user_journey, name='delete_user_journey'),
    path('view_all_users_journeys/', views.view_all_users_journeys, name='view_all_users_journeys'),
    path('view_today_journeys/', views.view_today_journeys, name='view_today_journeys'),
    path('search_user_journeys/', views.search_user_journeys, name='search_user_journeys'),
    path('view_user_journeys_by_location/', views.view_user_journeys_by_location, name='view_user_journeys_by_location'),

    path('send_journey_request/', views.send_journey_request, name='send_journey_request'),
    path('view_received_requests/', views.view_received_requests, name='view_received_requests'),
    path('view_sent_requests/', views.view_sent_requests, name='view_sent_requests'),
    path('update_request_status/', views.update_request_status, name='update_request_status'),
    path('delete_request/', views.delete_request, name='delete_request'),
    path('update_request_status/', views.update_request_status, name='update_request_status'),
    path('chat_send/', views.chat_send, name='chat_send'),
    path('chat_view_and/', views.chat_view_and, name='chat_view_and'),
    path('user_change_password/', views.user_change_password, name='user_change_password'),

    path('sos_alert/', views.sos_alert, name='sos_alert'),

    path('pol_view_users_addded_dangerous_spot/', views.pol_view_users_addded_dangerous_spot, name='pol_view_users_addded_dangerous_spot'),
    path('pol_approve_dangerous_spot/<int:spot_id>/', views.pol_approve_dangerous_spot,
         name='pol_approve_dangerous_spot'),
    path('pol_reject_dangerous_spot/<int:spot_id>/', views.pol_reject_dangerous_spot,
         name='pol_reject_dangerous_spot'),

    path('get_user_blockchain_score/', views.get_user_blockchain_score, name='get_user_blockchain_score'),
    path('get_user_score_by_lid/', views.get_user_score_by_lid, name='get_user_score_by_lid'),

    path('predict-safety/', views.predict_safety, name='predict_safety'),
    path('get-feature-options/', views.get_feature_options, name='get_feature_options'),
    path('retrain-model/', views.retrain_model, name='retrain_model'),

    path('get-user-sos-alerts/', views.get_user_sos_alerts, name='get_user_sos_alerts'),
    path('delete-sos-alert/<int:alert_id>/', views.delete_sos_alert, name='delete_sos_alert'),
    path('resolve-sos-alert/<int:alert_id>/', views.resolve_sos_alert, name='resolve_sos_alert'),
    path('get-sos-alert-details/<int:alert_id>/', views.get_sos_alert_details, name='get_sos_alert_details'),

    path('police_view_nearby_sos_alerts/', views.police_view_nearby_sos_alerts, name='police_view_nearby_sos_alerts'),
    path('update-sos-status/<int:alert_id>/', views.update_sos_status, name='update_sos_status'),
    path('api/nearby-sos/', views.get_nearby_sos_api, name='get_nearby_sos_api'),
    path('police-update-location/', views.police_update_location, name='police_update_location'),

    path('add-emergency-contact/', views.add_emergency_contact, name='add_emergency_contact'),
    path('get-emergency-contacts/', views.get_emergency_contacts, name='get_emergency_contacts'),
    path('delete-emergency-contact/<int:contact_id>/', views.delete_emergency_contact, name='delete_emergency_contact'),
    path('update-emergency-contact/<int:contact_id>/', views.update_emergency_contact, name='update_emergency_contact'),

]
