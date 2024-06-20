from rest_framework import status
from rest_framework.decorators import api_view
from rest_framework.response import Response
from .utils import database
import json
import psycopg2
from psycopg2 import Error

@api_view(['GET', 'POST'])
def UsersHandler(request):
    if request.method == "GET":
        try: 
            page = request.GET.get("page",1)
            limit = request.GET.get("limit",10)
            
            if page is None:
                page = 1
            if limit is None:
                limit = 10

            database.cur.execute("""
                SELECT get_users(%s, %s);
            """, (page, limit))

            result = json.loads(json.dumps(database.cur.fetchone()[0]))
            
            database.conn.commit()

            return Response(
                {
                    "message": result["status"] == "failed" and "User retrieval failed" or "User retrieved successfully",
                    "data": result
                },
                status = result["status"] == "failed" and status.HTTP_400_BAD_REQUEST or status.HTTP_200_OK
            )


        except (Exception, database.Error) as error:
            database.conn.commit()

            print(f"Error while interacting with the database:\n{error}")
            return Response(
                {"message": f"Error while interacting with the database:\n{error}"},
                status = status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    elif request.method == "POST":
        try:
            body = json.dumps(json.loads(request.body))

            database.cur.execute("""
                SELECT create_user(%s);
            """, (body,))
            
            result = json.loads(json.dumps(database.cur.fetchone()[0]))
            
            database.conn.commit()
            return Response(
                {
                    "message": result["status"] == "failed" and "User creation failed" or "User created successfully",
                    "data": result
                },
                status=result["status"] == "failed" and status.HTTP_400_BAD_REQUEST or status.HTTP_201_CREATED
            )
        except (Exception, database.Error) as error:
            database.conn.commit()
            print(f"Error while interacting with the database:\n{error}")
            return Response(
                {"message": f"Error while interacting with the database:\n{error}"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

@api_view(['GET', 'PATCH', 'DELETE'])
def UserHandler(request, id):
    if request.method == "GET":
        try:
            database.cur.execute("""
                SELECT get_user(%s);
            """, (id,))
            
            result = json.loads(json.dumps(database.cur.fetchone()[0]))
            
            database.conn.commit()

            return Response(
                {
                    "message": result["status"] == "failed" and "User retrieval failed" or "User retrieved successfully",
                    "data": result
                },
                status=result["status"] == "failed" and status.HTTP_400_BAD_REQUEST or status.HTTP_200_OK
            )

        except (Exception, database.Error) as error:
            database.conn.commit()
            
            print(f"Error while interacting with the database:\n{error}")
            return Response(
                {"message": f"Error while interacting with the database:\n{error}"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    elif request.method == "PATCH":
        try:
            body = json.dumps(json.loads(request.body))
            database.cur.execute("""
                SELECT update_user(%s, %s);
            """, (id, body))
            
            result = json.loads(json.dumps(database.cur.fetchone()[0]))
            database.conn.commit()
            return Response(
                {
                    "message": result["status"] == "failed" and "User update failed" or "User updated successfully",
                    "data": result
                },
                status=result["status"] == "failed" and status.HTTP_400_BAD_REQUEST or status.HTTP_200_OK
            )

        except (Exception, database.Error) as error:
            database.conn.commit()
            print(f"Error while interacting with the database:\n{error}")
            return Response(
                {"message": f"Error while interacting with the database:\n{error}"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    elif request.method == "DELETE":
        try:
            database.cur.execute("""
                SELECT delete_user(%s);
            """, (id,))
            
            result = json.loads(json.dumps(database.cur.fetchone()[0]))
            database.conn.commit()
            return Response(
                {
                    "message": result["status"] == "failed" and "User deletion failed" or "User deleted successfully",
                    "data": result
                },
                status=result["status"] == "failed" and status.HTTP_400_BAD_REQUEST or status.HTTP_200_OK
            )

        except (Exception, database.Error) as error:
            database.conn.commit()
            print(f"Error while interacting with the database:\n{error}")
            return Response(
                {"message": f"Error while interacting with the database:\n{error}"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    else:
        return Response(
            {"message": f"Invalid request method {request.method}"},
            status=status.HTTP_405_METHOD_NOT_ALLOWED
        )
# Category Handler
@api_view(['GET', 'POST'])
def CategoriesHandler(request):
    if request.method == "GET":
        try: 
            page = request.GET.get("page")
            limit = request.GET.get("limit")
            
            if page is None:
                page = 1
            if limit is None:
                limit = 10
            database.cur.execute("""
                SELECT get_categories(%s, %s);
            """, (page, limit))

            result = json.loads(json.dumps(database.cur.fetchone()[0]))
            
            database.conn.commit()

            return Response(
                {
                    "message": result["status"] == "failed" and "Category retrieval failed" or "Category retrieved successfully",
                    "data": result
                },
                status = result["status"] == "failed" and status.HTTP_400_BAD_REQUEST or status.HTTP_200_OK
            )


        except (Exception, database.Error) as error:
            database.conn.commit()

            print(f"Error while interacting with the database:\n{error}")
            return Response(
                {"message": f"Error while interacting with the database:\n{error}"},
                status = status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    elif request.method == "POST":
        try:
            body = json.dumps(json.loads(request.body))

            database.cur.execute("""
                SELECT create_category(%s);
            """, (body,))
            
            result = json.loads(json.dumps(database.cur.fetchone()[0]))
            
            database.conn.commit()
            return Response(
                {
                    "message": result["status"] == "failed" and "Category creation failed" or "Category created successfully",
                    "data": result
                },
                status=result["status"] == "failed" and status.HTTP_400_BAD_REQUEST or status.HTTP_201_CREATED
            )
        except (Exception, database.Error) as error:
            database.conn.commit()
            print(f"Error while interacting with the database:\n{error}")
            return Response(
                {"message": f"Error while interacting with the database:\n{error}"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
            
@api_view(['GET', 'PATCH', 'DELETE'])
def CategoryHandler(request, id):
    if request.method == "GET":
        try:
            database.cur.execute("""
                SELECT get_category(%s);
            """, (id,))
            
            result = json.loads(json.dumps(database.cur.fetchone()[0]))
            
            database.conn.commit()

            return Response(
                {
                    "message": result["status"] == "failed" and "Category retrieval failed" or "Category retrieved successfully",
                    "data": result
                },
                status=result["status"] == "failed" and status.HTTP_400_BAD_REQUEST or status.HTTP_200_OK
            )

        except (Exception, database.Error) as error:
            database.conn.commit()
            
            print(f"Error while interacting with the database:\n{error}")
            return Response(
                {"message": f"Error while interacting with the database:\n{error}"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    elif request.method == "PATCH":
        try:
            body = json.dumps(json.loads(request.body))
            database.cur.execute("""
                SELECT update_category(%s, %s);
            """, (id, body))
            
            result = json.loads(json.dumps(database.cur.fetchone()[0]))
            database.conn.commit()
            return Response(
                {
                    "message": result["status"] == "failed" and "Category update failed" or "Category updated successfully",
                    "data": result
                },
                status=result["status"] == "failed" and status.HTTP_400_BAD_REQUEST or status.HTTP_200_OK
            )

        except (Exception, database.Error) as error:
            database.conn.commit()
            print(f"Error while interacting with the database:\n{error}")
            return Response(
                {"message": f"Error while interacting with the database:\n{error}"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    elif request.method == "DELETE":
        try:
            database.cur.execute("""
                SELECT delete_category(%s);
            """, (id,))
            
            result = json.loads(json.dumps(database.cur.fetchone()[0]))
            
            database.conn.commit()
            return Response(
                {
                    "message": result["status"] == "failed" and "Category deletion failed" or "Category deleted successfully",
                    "data": result
                },
                status=result["status"] == "failed" and status.HTTP_400_BAD_REQUEST or status.HTTP_200_OK
            )
            
        except (Exception, database.Error) as error:
            database.conn.commit()
            print(f"Error while interacting with the database:\n{error}")
            return Response(
                {"message": f"Error while interacting with the database:\n{error}"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
            
    else:
        return Response(
            {"message": f"Invalid request method {request.method}"},
            status=status.HTTP_405_METHOD_NOT_ALLOWED
        )
# Task Handler
@api_view(['GET', 'POST'])
def TasksHandler(request):
    if request.method == "GET":
        try: 
            page = request.GET.get("page")
            limit = request.GET.get("limit")
            
            if page is None:
                page = 1
            if limit is None:
                limit = 10

            database.cur.execute("""
                SELECT get_tasks(%s, %s);
            """, (page, limit))

            result = json.loads(json.dumps(database.cur.fetchone()[0]))
            
            database.conn.commit()

            return Response(
                {
                    "message": result["status"] == "failed" and "Task retrieval failed" or "Task retrieved successfully",
                    "data": result
                },
                status = result["status"] == "failed" and status.HTTP_400_BAD_REQUEST or status.HTTP_200_OK
            )


        except (Exception, database.Error) as error:
            database.conn.commit()

            print(f"Error while interacting with the database:\n{error}")
            return Response(
                {"message": f"Error while interacting with the database:\n{error}"},
                status = status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    elif request.method == "POST":
        try:
            body = json.dumps(json.loads(request.body))

            database.cur.execute("""
                SELECT create_task(%s);
            """, (body,))
            
            result = json.loads(json.dumps(database.cur.fetchone()[0]))
            
            database.conn.commit()
            return Response(
                {
                    "message": result["status"] == "failed" and "Task creation failed" or "Task created successfully",
                    "data": result
                },
                status=result["status"] == "failed" and status.HTTP_400_BAD_REQUEST or status.HTTP_201_CREATED
            )
        except (Exception, database.Error) as error:
            database.conn.commit()
            print(f"Error while interacting with the database:\n{error}")
            return Response(
                {"message": f"Error while interacting with the database:\n{error}"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
            
@api_view(['GET', 'PATCH', 'DELETE'])
def TaskHandler(request, id):
    if request.method == "GET":
        try:
            database.cur.execute("""
                SELECT get_task(%s);
            """, (id,))
            
            result = json.loads(json.dumps(database.cur.fetchone()[0]))
            
            database.conn.commit()

            return Response(
                {
                    "message": result["status"] == "failed" and "Task retrieval failed" or "Task retrieved successfully",
                    "data": result
                },
                status=result["status"] == "failed" and status.HTTP_400_BAD_REQUEST or status.HTTP_200_OK
            )

        except (Exception, database.Error) as error:
            database.conn.commit()
            
            print(f"Error while interacting with the database:\n{error}")
            return Response(
                {"message": f"Error while interacting with the database:\n{error}"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    elif request.method == "PATCH":
        try:
            body = json.dumps(json.loads(request.body))
            database.cur.execute("""
                SELECT update_task(%s, %s);
            """, (id, body))
            
            result = json.loads(json.dumps(database.cur.fetchone()[0]))
            database.conn.commit()
            return Response(
                {
                    "message": result["status"] == "failed" and "Task update failed" or "Task updated successfully",
                    "data": result
                },
                status=result["status"] == "failed" and status.HTTP_400_BAD_REQUEST or status.HTTP_200_OK
            )

        except (Exception, database.Error) as error:
            database.conn.commit()
            print(f"Error while interacting with the database:\n{error}")
            return Response(
                {"message": f"Error while interacting with the database:\n{error}"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    elif request.method == "DELETE":
        try:
            database.cur.execute("""
                SELECT delete_task(%s);
            """, (id,))
            
            result = json.loads(json.dumps(database.cur.fetchone()[0]))
            database.conn.commit()
            return Response(
                {
                    "message": result["status"] == "failed" and "Task deletion failed" or "Task deleted successfully",
                    "data": result
                },
                status=result["status"] == "failed" and status.HTTP_400_BAD_REQUEST or status.HTTP_200_OK
            )

        except (Exception, database.Error) as error:
            database.conn.commit()
            print(f"Error while interacting with the database:\n{error}")
            return Response(
                {"message": f"Error while interacting with the database:\n{error}"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
            
    else:
        return Response(
            {"message": f"Invalid request method {request.method}"},
            status=status.HTTP_405_METHOD_NOT_ALLOWED
        )
# Profile Handler
@api_view(['GET', 'POST'])
def ProfilesHandler(request):
    if request.method == "GET":
        try: 
            page = request.GET.get("page")
            limit = request.GET.get("limit")
            
            if page is None:
                page = 1
            if limit is None:
                limit = 10

            database.cur.execute("""
                SELECT get_profiles(%s, %s);
            """, (page, limit))

            result = json.loads(json.dumps(database.cur.fetchone()[0]))
            
            database.conn.commit()

            return Response(
                {
                    "message": result["status"] == "failed" and "Profile retrieval failed" or "Profile retrieved successfully",
                    "data": result
                },
                status = result["status"] == "failed" and status.HTTP_400_BAD_REQUEST or status.HTTP_200_OK
            )


        except (Exception, database.Error) as error:
            database.conn.commit()

            print(f"Error while interacting with the database:\n{error}")
            return Response(
                {"message": f"Error while interacting with the database:\n{error}"},
                status = status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    elif request.method == "POST":
        try:
            body = json.dumps(json.loads(request.body))

            database.cur.execute("""
                SELECT create_profile(%s);
            """, (body,))
            
            result = json.loads(json.dumps(database.cur.fetchone()[0]))
            
            database.conn.commit()
            return Response(
                {
                    "message": result["status"] == "failed" and "Profile creation failed" or "Profile created successfully",
                    "data": result
                },
                status=result["status"] == "failed" and status.HTTP_400_BAD_REQUEST or status.HTTP_201_CREATED
            )
        except (Exception, database.Error) as error:
            database.conn.commit()
            print(f"Error while interacting with the database:\n{error}")
            return Response(
                {"message": f"Error while interacting with the database:\n{error}"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
            
@api_view(['GET', 'PATCH', 'DELETE'])
def ProfileHandler(request, id):
    if request.method == "GET":
        try:
            database.cur.execute("""
                SELECT get_profile(%s);
            """, (id,))
            
            result = json.loads(json.dumps(database.cur.fetchone()[0]))
            
            database.conn.commit()

            return Response(
                {
                    "message": result["status"] == "failed" and "Profile retrieval failed" or "Profile retrieved successfully",
                    "data": result
                },
                status=result["status"] == "failed" and status.HTTP_400_BAD_REQUEST or status.HTTP_200_OK
            )

        except (Exception, database.Error) as error:
            database.conn.commit()
            
            print(f"Error while interacting with the database:\n{error}")
            return Response(
                {"message": f"Error while interacting with the database:\n{error}"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    elif request.method == "PATCH":
        try:
            body = json.dumps(json.loads(request.body))
            database.cur.execute("""
                SELECT update_profile(%s, %s);
            """, (id, body))
            
            result = json.loads(json.dumps(database.cur.fetchone()[0]))
            database.conn.commit()
            return Response(
                {
                    "message": result["status"] == "failed" and "Profile update failed" or "Profile updated successfully",
                    "data": result
                },
                status=result["status"] == "failed" and status.HTTP_400_BAD_REQUEST or status.HTTP_200_OK
            )

        except (Exception, database.Error) as error:
            database.conn.commit()
            print(f"Error while interacting with the database:\n{error}")
            return Response(
                {"message": f"Error while interacting with the database:\n{error}"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    elif request.method == "DELETE":
        try:
            database.cur.execute("""
                SELECT delete_profile(%s);
            """, (id,))
            
            result = json.loads(json.dumps(database.cur.fetchone()[0]))
            
            database.conn.commit()
            return Response(
                {
                    "message": result["status"] == "failed" and "Profile deletion failed" or "Profile deleted successfully",
                    "data": result
                },
                status=result["status"] == "failed" and status.HTTP_400_BAD_REQUEST or status.HTTP_200_OK
            )
            
        except (Exception, database.Error) as error:
            database.conn.commit()
            print(f"Error while interacting with the database:\n{error}")
            return Response(
                {"message": f"Error while interacting with the database:\n{error}"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
            
    else:
        return Response(
            {"message": f"Invalid request method {request.method}"},
            status=status.HTTP_405_METHOD_NOT_ALLOWED
        )
# Activity Handler
@api_view(['GET', 'POST'])
def ActivitiesHandler(request):
    if request.method == "GET":
        try: 
            page = request.GET.get("page")
            limit = request.GET.get("limit")
            
            if page is None:
                page = 1
            if limit is None:
                limit = 10

            database.cur.execute("""
                SELECT get_activities(%s, %s);
            """, (page, limit))

            result = json.loads(json.dumps(database.cur.fetchone()[0]))
            
            database.conn.commit()

            return Response(
                {
                    "message": result["status"] == "failed" and "Activity retrieval failed" or "Activity retrieved successfully",
                    "data": result
                },
                status = result["status"] == "failed" and status.HTTP_400_BAD_REQUEST or status.HTTP_200_OK
            )


        except (Exception, database.Error) as error:
            database.conn.commit()

            print(f"Error while interacting with the database:\n{error}")
            return Response(
                {"message": f"Error while interacting with the database:\n{error}"},
                status = status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    elif request.method == "POST":
        try:
            body = json.dumps(json.loads(request.body))

            database.cur.execute("""
                SELECT create_activity(%s);
            """, (body,))
            
            result = json.loads(json.dumps(database.cur.fetchone()[0]))
            
            database.conn.commit()
            return Response(
                {
                    "message": result["status"] == "failed" and "Activity creation failed" or "Activity created successfully",
                    "data": result
                },
                status=result["status"] == "failed" and status.HTTP_400_BAD_REQUEST or status.HTTP_201_CREATED
            )
        except (Exception, database.Error) as error:
            database.conn.commit()
            print(f"Error while interacting with the database:\n{error}")
            return Response(
                {"message": f"Error while interacting with the database:\n{error}"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
            
@api_view(['GET', 'PATCH', 'DELETE'])
def ActivityHandler(request, id):
    if request.method == "GET":
        try:
            database.cur.execute("""
                SELECT get_activity(%s);
            """, (id,))
            
            result = json.loads(json.dumps(database.cur.fetchone()[0]))
            
            database.conn.commit()

            return Response(
                {
                    "message": result["status"] == "failed" and "Activity retrieval failed" or "Activity retrieved successfully",
                    "data": result
                },
                status=result["status"] == "failed" and status.HTTP_400_BAD_REQUEST or status.HTTP_200_OK
            )

        except (Exception, database.Error) as error:
            database.conn.commit()
            
            print(f"Error while interacting with the database:\n{error}")
            return Response(
                {"message": f"Error while interacting with the database:\n{error}"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    elif request.method == "PATCH":
        try:
            body = json.dumps(json.loads(request.body))
            database.cur.execute("""
                SELECT update_activity(%s, %s);
            """, (id, body))
            
            result = json.loads(json.dumps(database.cur.fetchone()[0]))
            database.conn.commit()
            return Response(
                {
                    "message": result["status"] == "failed" and "Activity update failed" or "Activity updated successfully",
                    "data": result
                },
                status=result["status"] == "failed" and status.HTTP_400_BAD_REQUEST or status.HTTP_200_OK
            )

        except (Exception, database.Error) as error:
            database.conn.commit()
            print(f"Error while interacting with the database:\n{error}")
            return Response(
                {"message": f"Error while interacting with the database:\n{error}"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    elif request.method == "DELETE":
        try:
            database.cur.execute("""
                SELECT delete_activity(%s);
            """, (id,))
            
            result = json.loads(json.dumps(database.cur.fetchone()[0]))
            
            database.conn.commit()
            return Response(
                {
                    "message": result["status"] == "failed" and "Activity deletion failed" or "Activity deleted successfully",
                    "data": result
                },
                status=result["status"] == "failed" and status.HTTP_400_BAD_REQUEST or status.HTTP_200_OK
            )
            
        except (Exception, database.Error) as error:
            database.conn.commit()
            print(f"Error while interacting with the database:\n{error}")
            return Response(
                {"message": f"Error while interacting with the database:\n{error}"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
            
    else:
        return Response(
            {"message": f"Invalid request method {request.method}"},
            status=status.HTTP_405_METHOD_NOT_ALLOWED
        )

