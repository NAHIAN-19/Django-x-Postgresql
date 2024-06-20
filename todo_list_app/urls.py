from django.contrib import admin
from django.urls import path, include
from . import views
from django.views.generic import TemplateView
urlpatterns = [
    path('', TemplateView.as_view(template_name='home.html')),
    path('users/', views.UsersHandler, name="users"),
    path('users/<int:id>/', views.UserHandler, name="user"),
    path('categories/', views.CategoriesHandler, name="categories"),
    path('categories/<int:id>/', views.CategoryHandler, name="category"),
    path('tasks/', views.TasksHandler, name="tasks"),
    path('tasks/<int:id>/', views.TaskHandler, name="task"),
    path('profiles/', views.ProfilesHandler, name="profiles"),
    path('profiles/<int:id>/', views.ProfileHandler, name="profile"),
    path('activity/', views.ActivitiesHandler, name="activities"),
    path('activity/<int:id>/', views.ActivityHandler, name="activity"),
]