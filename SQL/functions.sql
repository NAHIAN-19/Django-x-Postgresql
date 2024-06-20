-------------------------------------------- Date: 2023/12/09 23:17:00
--------------------------------------------      Version: 1.0
-------------------------------------------- Author: Nahian Nazeeb
-- Trigger functions for the database
-- Trigger function for validating the category and user
CREATE OR REPLACE FUNCTION validate_category_user()
RETURNS TRIGGER AS $$
BEGIN
	IF EXISTS (
		SELECT 1
		FROM category c
		WHERE c.id = NEW.categoryid
			AND c.userid = NEW.userid
	) THEN
    RETURN NEW;
	ELSE
		RAISE EXCEPTION 'Category does not belong to the same user';
	END IF;
END;
$$ LANGUAGE plpgsql;
-- Trigger for validate_category_user
CREATE TRIGGER validate_category_user_trigger
BEFORE INSERT ON tasks
FOR EACH ROW
EXECUTE FUNCTION validate_category_user();

-- Trigger function for updating the completed date and status of a task
CREATE OR REPLACE FUNCTION update_completeddate_and_status()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'Completed' AND NEW.completeddate IS NULL THEN
        NEW.completeddate := CURRENT_TIMESTAMP;
    END IF;

    IF NEW.duedate < CURRENT_TIMESTAMP AND NEW.status != 'Completed' THEN
        NEW.status := 'Overdue';
    END IF;
	
	IF NEW.status != 'Completed' AND NEW.completeddate IS NOT NULL THEN
		NEW.completeddate := NULL;
	END IF;
	
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
-- Trigger for update_completeddate_and_status
CREATE TRIGGER update_completeddate_and_status_trigger
BEFORE INSERT OR UPDATE ON tasks
FOR EACH ROW
EXECUTE FUNCTION update_completeddate_and_status();
-- Trigger function for updating the task count of a category
CREATE OR REPLACE FUNCTION update_task_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE category
        SET task_count = task_count + 1
        WHERE id = NEW.categoryid;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE category
        SET task_count = task_count - 1
        WHERE id = OLD.categoryid;
    ELSIF TG_OP = 'UPDATE' AND NEW.categoryid != OLD.categoryid THEN
        UPDATE category
        SET task_count = task_count + 1
        WHERE id = NEW.categoryid;

        UPDATE category
        SET task_count = task_count - 1
        WHERE id = OLD.categoryid;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
-- Trigger for update_task_count
CREATE TRIGGER update_task_count_trigger
AFTER INSERT OR UPDATE OR DELETE ON tasks
FOR EACH ROW
EXECUTE FUNCTION update_task_count();
-- Trigger function for task creation
CREATE OR REPLACE FUNCTION on_task_created()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE activity
    SET task_created = task_created + 1
    WHERE userid = NEW.userid;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
-- Trigger function for updating the timestamp of a task
CREATE OR REPLACE FUNCTION update_activity_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.timestamp = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
-- Trigger for update_activity_timestamp
CREATE TRIGGER activity_update_timestamp
BEFORE UPDATE ON activity
FOR EACH ROW
EXECUTE FUNCTION update_activity_timestamp();
-- Trigger function for updating the last login of a user
CREATE OR REPLACE FUNCTION update_activity_last_login()
RETURNS TRIGGER AS $$
BEGIN
    NEW.last_login = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
-- Trigger for update_activity_last_login
CREATE TRIGGER activity_update_last_login
BEFORE UPDATE ON activity
FOR EACH ROW
EXECUTE FUNCTION update_activity_last_login();
-- Trigger function for task editing
CREATE OR REPLACE FUNCTION on_task_edited()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE activity
    SET task_edited = task_edited + 1
    WHERE userid = NEW.userid;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
-- Trigger function for task completion
CREATE OR REPLACE FUNCTION on_task_completed()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'Completed' AND OLD.status != 'Completed' THEN
        UPDATE activity
        SET task_completed = task_completed + 1
        WHERE userid = NEW.userid;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
-- Trigger function for task deletion
CREATE OR REPLACE FUNCTION on_task_deleted()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE activity
    SET task_deleted = task_deleted + 1
    WHERE userid = NEW.userid;
    RETURN NEW;	
END;
$$ LANGUAGE plpgsql;

-- Trigger function for task deletaion count on category deletion
CREATE OR REPLACE FUNCTION update_task_count_on_category_deletion()
RETURNS TRIGGER AS $$
BEGIN
	UPDATE activity
	SET task_deleted = task_deleted + OLD.task_count
	WHERE userid = OLD.userid;
	RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- Trigger for update_task_count_on_category_deletion
CREATE TRIGGER update_task_count_on_category_deletion_trigger
AFTER DELETE ON category
FOR EACH ROW
EXECUTE FUNCTION update_task_count_on_category_deletion();

-- Trigger for task creation
CREATE TRIGGER task_created_trigger
AFTER INSERT ON tasks
FOR EACH ROW
EXECUTE FUNCTION on_task_created();

-- Trigger for task editing
CREATE TRIGGER task_edited_trigger
AFTER UPDATE ON tasks
FOR EACH ROW
EXECUTE FUNCTION on_task_edited();

-- Trigger for task deletion
CREATE TRIGGER task_deleted_trigger
BEFORE DELETE ON tasks
FOR EACH ROW
EXECUTE FUNCTION on_task_deleted();

-- Trigger for task completion
CREATE TRIGGER task_completed_trigger
AFTER UPDATE ON tasks
FOR EACH ROW
EXECUTE FUNCTION on_task_completed();

-- Functions for the database
------------------------------------------------------------------------------------------------------------------------

-- User functions
-- create_user
DROP FUNCTION IF EXISTS create_user;
CREATE OR REPLACE FUNCTION create_user(data JSON)
RETURNS JSON AS $$
DECLARE
	_user JSON = NULL::JSON;
	_activity_id INT;
	_profile_id INT;
	_username VARCHAR = coalesce((data->>'username')::varchar, NULL);
	_firstname VARCHAR = coalesce((data->>'firstname')::varchar, NULL);
	_lastname VARCHAR = coalesce((data->>'lastname')::varchar, NULL);
	_address VARCHAR = coalesce((data->>'address')::varchar, NULL);
	_phone VARCHAR = coalesce((data->>'phone')::varchar, NULL);
	_email VARCHAR = coalesce((data->>'email')::varchar, NULL);
	_password VARCHAR = coalesce((data->>'password')::varchar, NULL);
	_is_superuser BOOLEAN = coalesce((data->>'issuperuser')::BOOLEAN, FALSE);
	_is_active BOOLEAN = coalesce((data->>'isactive')::BOOLEAN, TRUE);
	_is_staff BOOLEAN = coalesce((data->>'isstaff')::BOOLEAN, FALSE);
BEGIN
	IF _username IS NULL OR _firstname IS NULL OR _lastname IS NULL OR _address IS NULL OR _phone IS NULL OR _email IS NULL OR _password IS NULL THEN
		RETURN JSON_BUILD_OBJECT(
			'status', 'failed',
			'message', 'All fields are required'
		);
	END IF;

	INSERT INTO users (username, firstname, lastname, address, phone, email, password, issuperuser, isactive, isstaff)
	VALUES (_username, _firstname, _lastname, _address, _phone, _email, _password, _is_superuser, _is_active, _is_staff)
	RETURNING JSON_BUILD_OBJECT(
		'id', id,
		'username', username,
		'firstname', firstname,
		'lastname', lastname,
		'address', address,
		'phone', phone,
		'email', email,
		'issuperuser', issuperuser,
		'isactive', isactive,
		'isstaff', isstaff
	) INTO _user;
	INSERT INTO activity (account_created, last_login, userid)
	VALUES (CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (_user->>'id')::INT)
	RETURNING id INTO _activity_id;
	
	INSERT INTO profile (userid)
	VALUES ((_user->>'id')::INT)
	RETURNING id INTO _profile_id;

	RETURN JSON_BUILD_OBJECT(
		'status', CASE WHEN _user IS NULL THEN 'failed' ELSE 'success' END,
		'user', _user
	);
END;
$$ LANGUAGE plpgsql;

-- get_users

DROP FUNCTION IF EXISTS get_users;
CREATE OR REPLACE FUNCTION get_users(_page INT, _limit INT)
RETURNS JSON AS $$
DECLARE
	_users JSON = NULL::JSON;
	_page INT = coalesce(_page, 1);
	_limit INT = coalesce(_limit, 10);
BEGIN
	_users = (
		select JSON_AGG(JSON_BUILD_OBJECT(
			'id', uu.id,
			'username', uu.username,
			'firstname', uu.firstname,
			'lastname', uu.lastname,
			'address', uu.address,
			'phone', uu.phone,
			'email', uu.email,
			'issuperuser', uu.issuperuser,
			'isactive', uu.isactive,
			'isstaff',uu.isstaff
		))
		FROM (
			SELECT 
				u.id,
				u.username,
				u.firstname,
				u.lastname,
				u.address,
				u.phone,
				u.email,
				u.issuperuser,
				u.isactive,
				u.isstaff
			FROM users u
			ORDER BY u.id ASC
			LIMIT _limit
			OFFSET (_page - 1) * _limit
		) uu
	)::JSON;
	return JSON_BUILD_OBJECT(
		'status', 'success',
		'users', _users
	);
END;
$$ LANGUAGE plpgsql;

--get_user

DROP FUNCTION IF EXISTS get_user;
CREATE OR REPLACE FUNCTION get_user(_id INT)
RETURNS JSON AS $$
DECLARE
	_user JSON = NULL::JSON;
BEGIN
	IF _id IS NULL THEN
		RETURN JSON_BUILD_OBJECT(
			'status', 'failed',
			'id', 'required'
		);
	END IF;
	
	_user = (
		SELECT JSON_AGG(u) 
		FROM users u
		WHERE id = _id
	)::JSON -> 0;
	
	RETURN JSON_BUILD_OBJECT(
		'status', CASE WHEN _user IS NULL THEN 'failed' ELSE 'success' END,
		'user', _user
	);
END;
$$ LANGUAGE plpgsql;

-- update_user

DROP FUNCTION IF EXISTS update_user;
CREATE OR REPLACE FUNCTION update_user(user_id INT, data JSON)
RETURNS JSON AS $$
DECLARE
	_user JSON = NULL::JSON;
	_username VARCHAR = coalesce((data->>'username')::varchar, NULL);
	_firstname VARCHAR = coalesce((data->>'firstname')::varchar, NULL);
	_lastname VARCHAR = coalesce((data->>'lastname')::varchar, NULL);
	_address VARCHAR = coalesce((data->>'address')::varchar, NULL);
	_phone VARCHAR = coalesce((data->>'phone')::varchar, NULL);
	_email VARCHAR = coalesce((data->>'email')::varchar, NULL);
	_password VARCHAR = coalesce((data->>'password')::varchar, NULL);
	_is_superuser BOOLEAN = coalesce((data->>'issuperuser')::BOOLEAN, FALSE);
	_is_active BOOLEAN = coalesce((data->>'isactive')::BOOLEAN, TRUE);
	_is_staff BOOLEAN = coalesce((data->>'isstaff')::BOOLEAN, FALSE);
BEGIN
	IF _username IS NULL AND _firstname IS NULL AND _lastname IS NULL AND _address IS NULL AND _phone IS NULL AND _email IS NULL AND _password IS NULL AND _is_superuser IS NULL AND _is_active IS NULL AND _is_staff IS NULL THEN
		RETURN JSON_BUILD_OBJECT(
			'status', 'failed',
			'message', 'At least one field is required for updating'
		);
	END IF;

	UPDATE users
	SET
		username = COALESCE(_username, username),
		firstname = COALESCE(_firstname, firstname),
		lastname = COALESCE(_lastname, lastname),
		address = COALESCE(_address, address),
		phone = COALESCE(_phone, phone),
		email = COALESCE(_email, email),
		password = COALESCE(_password, password),
		issuperuser = COALESCE(_is_superuser, issuperuser),
		isactive = COALESCE(_is_active, isactive),
		isstaff = COALESCE(_is_staff, isstaff)
	WHERE id = user_id
	RETURNING JSON_BUILD_OBJECT(
		'id', id,
		'username', username,
		'firstname', firstname,
		'lastname', lastname,
		'address', address,
		'phone', phone,
		'email', email,
		'issuperuser', issuperuser,
		'isactive', isactive,
		'isstaff', isstaff
	) INTO _user;

	RETURN JSON_BUILD_OBJECT(
		'status', CASE WHEN _user IS NULL THEN 'failed' ELSE 'success' END,
		'user', _user
	);
END;
$$ LANGUAGE plpgsql;

-- delete_users

DROP FUNCTION IF EXISTS delete_user;
CREATE OR REPLACE FUNCTION delete_user(user_id INT)
RETURNS JSON AS $$
DECLARE
	_user JSON = NULL::JSON;
BEGIN
	DELETE FROM users WHERE id = user_id
	RETURNING JSON_BUILD_OBJECT(
		'id', id,
		'username', username,
		'firstname', firstname,
		'lastname', lastname,
		'address', address,
		'phone', phone,
		'email', email,
		'issuperuser', issuperuser,
		'isactive', isactive,
		'isstaff', isstaff
	) INTO _user;

	RETURN JSON_BUILD_OBJECT(
		'status', CASE WHEN _user IS NULL THEN 'failed' ELSE 'success' END,
		'user', _user
	);
END;
$$ LANGUAGE plpgsql;

-- Category functions
-- create_category

DROP FUNCTION IF EXISTS create_category;
CREATE OR REPLACE FUNCTION create_category(data JSON)
RETURNS JSON AS $$

DECLARE
	_category JSON = NULL::JSON;
	_categoryname VARCHAR = coalesce((data->>'categoryname')::varchar, NULL);
	_tags VARCHAR = coalesce((data->>'tags')::varchar,NULL);
	_userid INT = coalesce((data->>'userid')::INT, NULL);
BEGIN
	IF _categoryname IS NULL OR _userid IS NULL THEN
		RETURN JSON_BUILD_OBJECT(
			'status', 'failed',
			'message', 'All fields are required'
		);
	END IF;

	INSERT INTO category (categoryname,tags, userid)
	VALUES (_categoryname, _tags, _userid)
	RETURNING JSON_BUILD_OBJECT(
		'id', id,
		'categoryname', categoryname,
		'tags', tags,
		'userid', userid
	) INTO _category;

	RETURN JSON_BUILD_OBJECT(
		'status', CASE WHEN _category IS NULL THEN 'failed' ELSE 'success' END,
		'category', _category
	);
END;
$$ LANGUAGE plpgsql;

-- get_categories

DROP FUNCTION IF EXISTS get_categories;
CREATE OR REPLACE FUNCTION get_categories(_page INT, _limit INT)
RETURNS JSON AS $$
DECLARE
    _categories JSON = NULL::JSON;
    _page INT = coalesce(_page, 1);
    _limit INT = coalesce(_limit, 10);
BEGIN
    _categories = (
        SELECT JSON_AGG(JSON_BUILD_OBJECT(
            'id', cat.id,
            'categoryname', cat.categoryname,
			'tags', cat.tags,
            'userid', cat.userid,
            'task_count', cat.task_count
        ))
        FROM (
            SELECT
                c.id,
                c.categoryname,
				c.tags,
                c.userid,
                COUNT(t.id) AS task_count
            FROM category c
            LEFT JOIN tasks t ON c.id = t.categoryid
            GROUP BY c.id
            ORDER BY c.id ASC
            LIMIT _limit
            OFFSET (_page - 1) * _limit
        ) cat
    )::JSON;

    RETURN JSON_BUILD_OBJECT(
        'status', 'success',
        'categories', _categories
    );
END;
$$ LANGUAGE plpgsql;

-- get_category

DROP FUNCTION IF EXISTS get_category;
CREATE OR REPLACE FUNCTION get_category(_id INT)
RETURNS JSON AS $$
DECLARE
	_category JSON = NULL::JSON;
BEGIN
	IF _id IS NULL THEN
		RETURN JSON_BUILD_OBJECT(
			'status', 'failed',
			'id', 'required'
		);
	END IF;
	_category = (
		SELECT JSON_BUILD_OBJECT(
			'id', cat.id,
			'categoryname', cat.categoryname,
			'tags', cat.tags,
			'userid', cat.userid,
			'task_count', COUNT(t.id)
		)
		FROM category cat
		LEFT JOIN tasks t ON cat.id = t.categoryid
		WHERE cat.id = _id
		GROUP BY cat.id
	)::JSON;

	RETURN JSON_BUILD_OBJECT(
		'status', CASE WHEN _category IS NULL THEN 'failed' ELSE 'success' END,
		'category', _category
	);
END;
$$ LANGUAGE plpgsql;

--update_category

DROP FUNCTION IF EXISTS update_category;
CREATE OR REPLACE FUNCTION update_category(category_id INT, data JSON)
RETURNS JSON AS $$
DECLARE
    _category JSON = NULL::JSON;
    _categoryname VARCHAR = coalesce((data->>'categoryname')::varchar, NULL);
	_tags varchar = coalesce((data->>'tags')::varchar,NULL);
    _userid INT = coalesce((data->>'userid')::INT, NULL);
BEGIN
    IF _categoryname IS NULL AND _userid IS NULL THEN
        RETURN JSON_BUILD_OBJECT(
            'status', 'failed',
            'message', 'At least one field is required for updating'
        );
    END IF;

    UPDATE category
    SET
        categoryname = COALESCE(_categoryname, categoryname),
		tags = COALESCE(_tags, tags),
        userid = COALESCE(_userid, userid)
    WHERE id = category_id;

    SELECT JSON_BUILD_OBJECT(
        'id', id,
        'categoryname', categoryname,
		'tags', tags,
        'userid', userid,
        'task_count', task_count
    )
    INTO _category
    FROM (
        SELECT
            cat.id,
            cat.categoryname,
			cat.tags,
            cat.userid,
            COUNT(t.id) AS task_count
        FROM category cat
        LEFT JOIN tasks t ON cat.id = t.categoryid
        WHERE cat.id = category_id
        GROUP BY cat.id
    ) cat;

    RETURN JSON_BUILD_OBJECT(
        'status', CASE WHEN _category IS NULL THEN 'failed' ELSE 'success' END,
        'category', _category
    );
END;
$$ LANGUAGE plpgsql;

--delete_category

DROP FUNCTION IF EXISTS delete_category;
CREATE OR REPLACE FUNCTION delete_category(category_id INT)
RETURNS JSON AS $$
DECLARE
	_category JSON = NULL::JSON;
BEGIN

	DELETE FROM category WHERE id = category_id
	RETURNING JSON_BUILD_OBJECT(
		'id', id,
		'categoryname', categoryname,
		'tags', tags,
		'userid', userid,
		'task_count', task_count
	) INTO _category;

	RETURN JSON_BUILD_OBJECT(
		'status', CASE WHEN _category IS NULL THEN 'failed' ELSE 'success' END,
		'category', _category
	);
END;
$$ LANGUAGE plpgsql;

-- Task functions
-- create_task

DROP FUNCTION IF EXISTS create_task;
CREATE OR REPLACE FUNCTION create_task(data JSON)
RETURNS JSON AS $$
DECLARE
	_task JSON = NULL::JSON;
	_tasktitle VARCHAR = COALESCE((data->>'tasktitle')::VARCHAR, NULL);
	_categoryid INT = COALESCE((data->>'categoryid')::INT, NULL);
	_duedate TIMESTAMP = COALESCE((data->>'duedate')::TIMESTAMP, NULL);
	_createddate TIMESTAMP = COALESCE((data->>'createddate')::TIMESTAMP, CURRENT_TIMESTAMP);
	_completeddate TIMESTAMP = COALESCE((data->>'completeddate')::TIMESTAMP, NULL);
	_status VARCHAR = COALESCE((data->>'status')::VARCHAR, 'Pending');
	_userid INT = COALESCE((data->>'userid')::INT, NULL);
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM category
        WHERE id = _categoryid AND userid = _userid
    ) THEN
        RETURN JSON_BUILD_OBJECT(
            'status', 'failed',
            'message', 'Invalid category for the user'
        );
	END IF;
	
	IF _tasktitle IS NULL OR _categoryid IS NULL OR _duedate IS NULL OR _userid IS NULL THEN
		RETURN JSON_BUILD_OBJECT(
			'status', 'failed',
			'message', 'All fields are required'
		);
	END IF;
	IF _duedate <= CURRENT_TIMESTAMP AND _status != 'Completed' THEN
		_status := 'Overdue';
	END IF;
	IF _status = 'Completed' AND _completeddate IS NULL THEN
		_completeddate := CURRENT_TIMESTAMP;
	END IF;
	INSERT INTO tasks (tasktitle, categoryid, duedate, createddate, completeddate, status, userid)
	VALUES (_tasktitle, _categoryid, _duedate, _createddate, _completeddate, _status, _userid)
	RETURNING JSON_BUILD_OBJECT(
		'id', id,
		'tasktitle', tasktitle,
		'categoryid', categoryid,
		'duedate', duedate,
		'createddate', createddate,
		'completeddate', completeddate,
		'status', status,
		'userid', userid
	) INTO _task;

	RETURN JSON_BUILD_OBJECT(
		'status', CASE WHEN _task IS NULL THEN 'failed' ELSE 'success' END,
		'task', _task
	);
END;
$$ LANGUAGE plpgsql;

-- get_tasks

DROP FUNCTION IF EXISTS get_tasks;
CREATE OR REPLACE FUNCTION get_tasks(_page INT, _limit INT)
RETURNS JSON AS $$
DECLARE
	_tasks JSON = NULL::JSON;
	_page INT = coalesce(_page, 1);
	_limit INT = coalesce(_limit, 10);
BEGIN
	_tasks = (
		select JSON_AGG(JSON_BUILD_OBJECT(
			'id', t.id,
			'tasktitle', t.tasktitle,
			'categoryid', t.categoryid,
			'duedate', t.duedate,
			'createddate', t.createddate,
			'completeddate', t.completeddate,
			'status', t.status,
			'userid', t.userid
		))
		FROM (
			SELECT 
				t.id,
				t.tasktitle,
				t.categoryid,
				t.duedate,
				t.createddate,
				t.completeddate,
				t.status,
				t.userid
			FROM tasks t
			ORDER BY t.id ASC
			LIMIT _limit
			OFFSET (_page - 1) * _limit
		) t
	)::JSON;
	return JSON_BUILD_OBJECT(
		'status', 'success',
		'tasks', _tasks
	);
END;
$$ LANGUAGE plpgsql;


-- get_task

DROP FUNCTION IF EXISTS get_task;
CREATE OR REPLACE FUNCTION get_task(_id INT)
RETURNS JSON AS $$
DECLARE
	_task JSON = NULL::JSON;
BEGIN
	IF _id IS NULL THEN
		RETURN JSON_BUILD_OBJECT(
			'status', 'failed',
			'id', 'required'
		);
	END IF;
	UPDATE tasks
	SET
		status = CASE
					WHEN duedate < CURRENT_TIMESTAMP AND status != 'Completed' THEN 'Overdue'
					WHEN duedate > CURRENT_TIMESTAMP AND status = 'Overdue' THEN 'Pending'
					ELSE status
				END;
	UPDATE tasks
	SET
		completeddate = CASE
							WHEN status != 'Completed' THEN NULL
							WHEN status = 'Completed' THEN CURRENT_TIMESTAMP
							ELSE completeddate
						END;

	_task = (
		SELECT JSON_BUILD_OBJECT(
			'id', t.id,
			'tasktitle', t.tasktitle,
			'categoryid', t.categoryid,
			'duedate', t.duedate,
			'createddate', t.createddate,
			'completeddate', t.completeddate,
			'status', t.status,
			'userid', t.userid
		)
		FROM tasks t
		WHERE t.id = _id
	)::JSON;
	
	RETURN JSON_BUILD_OBJECT(
		'status', CASE WHEN _task IS NULL THEN 'failed' ELSE 'success' END,
		'task', _task
	);
END;
$$ LANGUAGE plpgsql;


-- update_task

DROP FUNCTION IF EXISTS update_task;
CREATE OR REPLACE FUNCTION update_task(task_id INT, data JSON)
RETURNS JSON AS $$
DECLARE
	_task JSON = NULL::JSON;
	_tasktitle VARCHAR = COALESCE((data->>'tasktitle')::VARCHAR, NULL);
	_categoryid INT = COALESCE((data->>'categoryid')::INT, NULL);
	_duedate TIMESTAMP = COALESCE((data->>'duedate')::TIMESTAMP, NULL);
	_createddate TIMESTAMP = COALESCE((data->>'createddate')::TIMESTAMP, CURRENT_TIMESTAMP);
	_completeddate TIMESTAMP = COALESCE((data->>'completeddate')::TIMESTAMP, NULL);
	_status VARCHAR = COALESCE((data->>'status')::VARCHAR, 'Pending');
	_userid INT = COALESCE((data->>'userid')::INT, NULL);
BEGIN

	IF _tasktitle IS NULL AND _categoryid IS NULL AND _duedate IS NULL AND _createddate IS NULL AND _completeddate IS NULL AND _status IS NULL AND _userid IS NULL THEN
		RETURN JSON_BUILD_OBJECT(
			'status', 'failed',
			'message', 'At least one field is required for updating'
		);
	END IF;

	IF _duedate < CURRENT_TIMESTAMP AND _status != 'Completed' THEN
		_status := 'Overdue';
	END IF;

	IF _status = 'Completed' AND _completeddate IS NULL THEN
		_completeddate := CURRENT_TIMESTAMP;
	END IF;
	UPDATE tasks
	SET
		tasktitle = COALESCE(_tasktitle, tasktitle),
		categoryid = COALESCE(_categoryid, categoryid),
		duedate = COALESCE(_duedate, duedate),
		createddate = COALESCE(_createddate, createddate),
		completeddate = COALESCE(_completeddate, completeddate),
		status = COALESCE(_status, status),
		userid = COALESCE(_userid, userid)
	WHERE id = task_id
	RETURNING JSON_BUILD_OBJECT(
		'id', id,
		'tasktitle', tasktitle,
		'categoryid', categoryid,
		'duedate', duedate,
		'createddate', createddate,
		'completeddate', completeddate,
		'status', status,
		'userid', userid
	) INTO _task;

	RETURN JSON_BUILD_OBJECT(
		'status', CASE WHEN _task IS NULL THEN 'failed' ELSE 'success' END,
		'task', _task
	);
END;
$$ LANGUAGE plpgsql;

-- delete_task

DROP FUNCTION IF EXISTS delete_task;
CREATE OR REPLACE FUNCTION delete_task(task_id INT)
RETURNS JSON AS $$
DECLARE
	_task JSON = NULL::JSON;
BEGIN

	DELETE FROM tasks WHERE id = task_id
	RETURNING JSON_BUILD_OBJECT(
		'id', id,
		'tasktitle', tasktitle,
		'categoryid', categoryid,
		'duedate', duedate,
		'createddate', createddate,
		'completeddate', completeddate,
		'status', status,
		'userid', userid
	) INTO _task;
	update activity
	set task_deleted = task_deleted + 1
	where userid = (_task->>'userid')::INT;

	RETURN JSON_BUILD_OBJECT(
		'status', CASE WHEN _task IS NULL THEN 'failed' ELSE 'success' END,
		'task', _task
	);
END;
$$ LANGUAGE plpgsql;

-- Profile functions
-- create_profile

DROP FUNCTION IF EXISTS create_profile;
CREATE OR REPLACE FUNCTION create_profile(data JSON)
RETURNS JSON AS $$
DECLARE
	_profile JSON = NULL::JSON;
	_picture_path VARCHAR = coalesce((data->>'profile_picture_path')::VARCHAR, NULL);
	_bio TEXT = coalesce((data->>'bio')::TEXT, NULL);
	_date_of_birth DATE = coalesce((data->>'date_of_birth')::DATE, NULL);
	_website VARCHAR = coalesce((data->>'website')::VARCHAR, NULL);
	_userid INT = coalesce((data->>'userid')::INT, NULL);
BEGIN
	IF _userid IS NULL THEN
		RETURN JSON_BUILD_OBJECT(
			'status', 'failed',
			'message', 'User ID is required'
		);
	END IF;

	INSERT INTO profile (profile_picture_path, bio, date_of_birth, website, userid)
	VALUES (_picture_path, _bio, _date_of_birth, _website, _userid)
	RETURNING JSON_BUILD_OBJECT(
		'id', id,
		'profile_picture_path', profile_picture_path,
		'bio', bio,
		'date_of_birth', date_of_birth,
		'website', website,
		'userid', userid
	) INTO _profile;

	RETURN JSON_BUILD_OBJECT(
		'status', CASE WHEN _profile IS NULL THEN 'failed' ELSE 'success' END,
		'profile', _profile
	);
END;
$$ LANGUAGE plpgsql;

--get_profiles

DROP FUNCTION IF EXISTS get_profiles;
CREATE OR REPLACE FUNCTION get_profiles(_page INT, _limit INT)
RETURNS JSON AS $$
DECLARE
	_profiles JSON = NULL::JSON;
	_page INT = coalesce(_page, 1);
	_limit INT = coalesce(_limit, 10);
BEGIN

	_profiles = (
		SELECT JSON_AGG(JSON_BUILD_OBJECT(
			'id', p.id,
			'profile_picture_path', p.profile_picture_path,
			'bio', p.bio,
			'date_of_birth', p.date_of_birth,
			'website', p.website,
			'userid', p.userid
		))
		FROM (
			SELECT 
				p.id,
				p.profile_picture_path,
				p.bio,
				p.date_of_birth,
				p.website,
				p.userid
			FROM profile p
			ORDER BY p.id ASC
			LIMIT _limit
			OFFSET (_page - 1) * _limit
		) p
	)::JSON;

	RETURN JSON_BUILD_OBJECT(
		'status', 'success',
		'profiles', _profiles
	);
END;
$$ LANGUAGE plpgsql;

-- get_profile

DROP FUNCTION IF EXISTS get_profile;
CREATE OR REPLACE FUNCTION get_profile(_id INT)
RETURNS JSON AS $$
DECLARE
	_profile JSON = NULL::JSON;
BEGIN
	IF _id IS NULL THEN
		RETURN JSON_BUILD_OBJECT(
			'status', 'failed',
			'id', 'required'
		);
	END IF;
	_profile = (
		SELECT JSON_AGG(p) 
		FROM profile p
		WHERE userid = _id
	)::JSON -> 0;
	
	RETURN JSON_BUILD_OBJECT(
		'status', CASE WHEN _profile IS NULL THEN 'failed' ELSE 'success' END,
		'profile', _profile
	);
END;
$$ LANGUAGE plpgsql;

-- update_profile

DROP FUNCTION IF EXISTS update_profile;
CREATE OR REPLACE FUNCTION update_profile(profile_id INT, data JSON)
RETURNS JSON AS $$
DECLARE
	_profile JSON = NULL::JSON;
	_picture_path VARCHAR = coalesce((data->>'profile_picture_path')::VARCHAR, NULL);
	_bio TEXT = coalesce((data->>'bio')::TEXT, NULL);
	_date_of_birth DATE = coalesce((data->>'date_of_birth')::DATE, NULL);
	_website VARCHAR = coalesce((data->>'website')::VARCHAR, NULL);
	_userid INT = coalesce((data->>'userid')::INT, NULL);
BEGIN

	IF _picture_path IS NULL AND _bio IS NULL AND _date_of_birth IS NULL AND _website IS NULL AND _userid IS NULL THEN
		RETURN JSON_BUILD_OBJECT(
			'status', 'failed',
			'message', 'At least one field is required for updating'
		);
	END IF;

	UPDATE profile
	SET
		profile_picture_path = COALESCE(_picture_path, profile_picture_path),
		bio = COALESCE(_bio, bio),
		date_of_birth = COALESCE(_date_of_birth, date_of_birth),
		website = COALESCE(_website, website),
		userid = COALESCE(_userid, userid)
	WHERE id = profile_id
	RETURNING JSON_BUILD_OBJECT(
		'id', id,
		'profile_picture_path', profile_picture_path,
		'bio', bio,
		'date_of_birth', date_of_birth,
		'website', website,
		'userid', userid
	) INTO _profile;

	RETURN JSON_BUILD_OBJECT(
		'status', CASE WHEN _profile IS NULL THEN 'failed' ELSE 'success' END,
		'profile', _profile
	);
END;
$$ LANGUAGE plpgsql;

-- delete_profile

DROP FUNCTION IF EXISTS delete_profile;
CREATE OR REPLACE FUNCTION delete_profile(profile_id INT)
RETURNS JSON AS $$
DECLARE
	_profile JSON = NULL::JSON;
BEGIN

	DELETE FROM profile WHERE id = profile_id
	RETURNING JSON_BUILD_OBJECT(
		'id', id,
		'profile_picture_path', profile_picture_path,
		'bio', bio,
		'date_of_birth', date_of_birth,
		'website', website,
		'userid', userid
	) INTO _profile;

	RETURN JSON_BUILD_OBJECT(
		'status', CASE WHEN _profile IS NULL THEN 'failed' ELSE 'success' END,
		'profile', _profile
	);
END;
$$ LANGUAGE plpgsql;

--Activity functions
-- create_activity

DROP FUNCTION IF EXISTS create_activity;
CREATE OR REPLACE FUNCTION create_activity(data JSON)
RETURNS JSON AS $$
DECLARE
	_activity JSON = NULL::JSON;
	_task_created INT = coalesce((data->>'task_created')::INT, 0);
	_task_edited INT = coalesce((data->>'task_edited')::INT, 0);
	_task_completed INT = coalesce((data->>'task_completed')::INT, 0);
	_task_deleted INT = coalesce((data->>'task_deleted')::INT, 0);
	_account_created TIMESTAMP = coalesce((data->>'account_created')::TIMESTAMP, CURRENT_TIMESTAMP);
	_last_login TIMESTAMP = coalesce((data->>'last_login')::TIMESTAMP, CURRENT_TIMESTAMP);
	_userid INT = coalesce((data->>'userid')::INT, NULL);
BEGIN

	IF _userid IS NULL THEN
		RETURN JSON_BUILD_OBJECT(
			'status', 'failed',
			'message', 'User ID is required'
		);
	END IF;

	INSERT INTO activity (task_created, task_edited, task_completed, task_deleted, account_created, last_login, userid)
	VALUES (_task_created, _task_edited, _task_completed, _task_deleted, _account_created, _last_login, _userid)
	RETURNING JSON_BUILD_OBJECT(
		'id', id,
		'task_created', task_created,
		'task_edited', task_edited,
		'task_completed', task_completed,
		'task_deleted', task_deleted,
		'account_created', account_created,
		'last_login', last_login,
		'userid', userid
	) INTO _activity;

	RETURN JSON_BUILD_OBJECT(
		'status', CASE WHEN _activity IS NULL THEN 'failed' ELSE 'success' END,
		'activity', _activity
	);
END;
$$ LANGUAGE plpgsql;

--get_activities

DROP FUNCTION IF EXISTS get_activities;
CREATE OR REPLACE FUNCTION get_activities(_page INT, _limit INT)
RETURNS JSON AS $$
DECLARE
	_activities JSON = NULL::JSON;
	_page INT = coalesce(_page, 1);
	_limit INT = coalesce(_limit, 10);
BEGIN

	_activities = (
		SELECT JSON_AGG(JSON_BUILD_OBJECT(
			'id', a.id,
			'task_created', a.task_created,
			'task_edited', a.task_edited,
			'task_completed', a.task_completed,
			'task_deleted', a.task_deleted,
			'account_created', a.account_created,
			'last_login', a.last_login,
			'userid', a.userid
		))
		FROM (
			SELECT 
				a.id,
				a.task_created,
				a.task_edited,
				a.task_completed,
				a.task_deleted,
				a.account_created,
				a.last_login,
				a.userid
			FROM activity a
			ORDER BY a.id ASC
			LIMIT _limit
			OFFSET (_page - 1) * _limit
		) a
	)::JSON;

	RETURN JSON_BUILD_OBJECT(
		'status', 'success',
		'activities', _activities
	);
END;
$$ LANGUAGE plpgsql;

-- get_activity

DROP FUNCTION IF EXISTS get_activity;
CREATE OR REPLACE FUNCTION get_activity(_id INT)
RETURNS JSON AS $$
DECLARE
	_activity JSON = NULL::JSON;
BEGIN

	IF _id IS NULL THEN
		RETURN JSON_BUILD_OBJECT(
			'status', 'failed',
			'id', 'required'
		);
	END IF;
	_activity = (
		SELECT JSON_AGG(a) 
		FROM activity a
		WHERE userid = _id
	)::JSON -> 0;
	
	RETURN JSON_BUILD_OBJECT(
		'status', CASE WHEN _activity IS NULL THEN 'failed' ELSE 'success' END,
		'activity', _activity
	);
END;
$$ LANGUAGE plpgsql;

--update_activity

DROP FUNCTION IF EXISTS update_activity;
CREATE OR REPLACE FUNCTION update_activity(activity_id INT, data JSON)
RETURNS JSON AS $$
DECLARE
	_activity JSON = NULL::JSON;
	_task_created INT = coalesce((data->>'task_created')::INT, 0);
	_task_edited INT = coalesce((data->>'task_edited')::INT, 0);
	_task_completed INT = coalesce((data->>'task_completed')::INT, 0);
	_task_deleted INT = coalesce((data->>'task_deleted')::INT, 0);
	_account_created TIMESTAMP = coalesce((data->>'account_created')::TIMESTAMP, CURRENT_TIMESTAMP);
	_last_login TIMESTAMP = coalesce((data->>'last_login')::TIMESTAMP, CURRENT_TIMESTAMP);
	_userid INT = coalesce((data->>'userid')::INT, NULL);
BEGIN

	IF _task_created IS NULL AND _task_edited IS NULL AND _task_completed IS NULL AND _task_deleted IS NULL AND _account_created IS NULL AND _last_login IS NULL AND _userid IS NULL THEN
		RETURN JSON_BUILD_OBJECT(
			'status', 'failed',
			'message', 'At least one field is required for updating'
		);
	END IF;

	UPDATE activity
	SET
		task_created = COALESCE(_task_created, task_created),
		task_edited = COALESCE(_task_edited, task_edited),
		task_completed = COALESCE(_task_completed, task_completed),
		task_deleted = COALESCE(_task_deleted, task_deleted),
		account_created = COALESCE(_account_created, account_created),
		last_login = COALESCE(_last_login, last_login),
		userid = COALESCE(_userid, userid)
	WHERE id = activity_id
	RETURNING JSON_BUILD_OBJECT(
		'id', id,
		'task_created', task_created,
		'task_edited', task_edited,
		'task_completed', task_completed,
		'task_deleted', task_deleted,
		'account_created', account_created,
		'last_login', last_login,
		'userid', userid
	) INTO _activity;

	RETURN JSON_BUILD_OBJECT(
		'status', CASE WHEN _activity IS NULL THEN 'failed' ELSE 'success' END,
		'activity', _activity
	);
END;
$$ LANGUAGE plpgsql;

-- delete_activity

DROP FUNCTION IF EXISTS delete_activity;
CREATE OR REPLACE FUNCTION delete_activity(activity_id INT)
RETURNS JSON AS $$
DECLARE
	_activity JSON = NULL::JSON;
BEGIN

	DELETE FROM activity WHERE id = activity_id
	RETURNING JSON_BUILD_OBJECT(
		'id', id,
		'task_created', task_created,
		'task_edited', task_edited,
		'task_completed', task_completed,
		'task_deleted', task_deleted,
		'account_created', account_created,
		'last_login', last_login,
		'userid', userid
	) INTO _activity;

	RETURN JSON_BUILD_OBJECT(
		'status', CASE WHEN _activity IS NULL THEN 'failed' ELSE 'success' END,
		'activity', _activity
	);
END;
$$ LANGUAGE plpgsql;
