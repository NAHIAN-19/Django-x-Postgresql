CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(30) NOT NULL UNIQUE,
    firstName VARCHAR(15) NOT NULL,
    lastName VARCHAR(15) NOT NULL,
    address VARCHAR(255) NOT NULL,
    phone VARCHAR(20) NOT NULL CHECK (LENGTH(phone) <= 20),
    email VARCHAR(50) NOT NULL CHECK (POSITION('@' IN email) > 0),
    password VARCHAR(128) NOT NULL,
    issuperuser BOOLEAN DEFAULT FALSE,
    isactive BOOLEAN DEFAULT TRUE,
    isstaff BOOLEAN DEFAULT FALSE
);

create table if not exists category(
	id serial primary key,
	categoryname varchar(50) not null,
	tags varchar(128),
	userid serial references users(id) on delete cascade not null,
	task_count int default 0
);
CREATE TABLE IF NOT EXISTS tasks (
    id SERIAL PRIMARY KEY,
    tasktitle VARCHAR(255) NOT NULL,
    categoryid SERIAL REFERENCES category(id) ON DELETE CASCADE NOT NULL,
    duedate TIMESTAMP NOT NULL,
    createddate TIMESTAMP DEFAULT current_timestamp,
    completeddate TIMESTAMP DEFAULT NULL,
    status VARCHAR(20) DEFAULT 'Pending' CHECK (status IN ('Pending', 'Overdue', 'Completed')),
    userid SERIAL REFERENCES users(id) ON DELETE CASCADE NOT NULL
);
CREATE TABLE IF NOT EXISTS profile (
    id serial PRIMARY KEY,
    profile_picture_path VARCHAR(255),
    bio TEXT,
    date_of_birth DATE,
    website VARCHAR(255),
    userid serial REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    UNIQUE (userid)
);
create table if not exists activity(
	id serial primary key,
	task_created int default 0,
	task_edited int default 0,
	task_completed int default 0,
	task_deleted int default 0,
	account_created TIMESTAMP,
	last_login TIMESTAMP,
	timestamp TIMESTAMP default current_timestamp,
	userid serial references users(id) on delete cascade not null,
	UNIQUE (userid)
);
