CREATE TABLE app_user (
    email VARCHAR(100) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    photo_url TEXT NOT NULL
);
COMMENT ON TABLE app_user IS 'Stores all the application users of JUWURA.';

CREATE TABLE project (
    id SERIAL PRIMARY KEY,
    name VARCHAR(64) NOT NULL,
    photo_url TEXT NOT NULL,
    icon CHAR(1) NOT NULL,
    owner VARCHAR(100) REFERENCES app_user (email) NOT NULL,
    next_task_id INTEGER NOT NULL DEFAULT 0
);
COMMENT ON TABLE project IS 'Stores all projects in JUWURA';

CREATE TABLE project_member (
    project_id INTEGER REFERENCES project (id) NOT NULL,
    user_id VARCHAR(100) REFERENCES app_user (email) NOT NULL,
    is_pinned BOOLEAN NOT NULL DEFAULT FALSE,
    last_visited TIMESTAMP NOT NULL
);
COMMENT ON TABLE project_member IS
'Stores all the members of a specific project';

CREATE TABLE task (
    id SERIAL PRIMARY KEY,
    parent_id INTEGER REFERENCES task (id),
    project_id INTEGER REFERENCES project (id) NOT NULL,
    short_title VARCHAR(16) NOT NULL,
    icon CHAR(1) NOT NULL
);
COMMENT ON TABLE task IS
'Stores all the task of all the projects, only some fields are required';

CREATE TABLE task_unblock (
    target_task INTEGER REFERENCES task (id) NOT NULL,
    unblocked_task INTEGER REFERENCES task (id) NOT NULL
);
COMMENT ON TABLE task_unblock IS
'Stores all the tasks that unblock once target_task is completed';

CREATE TABLE task_field_type (
    id SERIAL PRIMARY KEY,
    project_id INTEGER REFERENCES project (id),
    name VARCHAR(16) NOT NULL
);
COMMENT ON TABLE task_field_type IS
'Stores all the types of fields a task can have,
for example DATE, TEXT, SELECT, etc';

CREATE TABLE task_field (
    id SERIAL PRIMARY KEY,
    project_id INTEGER REFERENCES project (id) NOT NULL,
    task_field_type_id INTEGER REFERENCES task_field_type (id) NOT NULL,
    name VARCHAR(16) NOT NULL
);
COMMENT ON TABLE task_field IS
'Stores all the custom fields of a given task type in a given project';

CREATE TABLE task_field_option (
    id SERIAL PRIMARY KEY,
    task_field INTEGER REFERENCES task_field (id) NOT NULL,
    value TEXT
);
COMMENT ON TABLE task_field_option IS
'If a task field needs to select from multiple predefined values,
the options to that task_field are saved here';

CREATE TABLE task_fields_for_task (
    task_id INTEGER REFERENCES task (id) NOT NULL,
    task_field_id INTEGER REFERENCES task_field (id) NOT NULL,
    value TEXT,

    UNIQUE (task_id, task_field_id)
);
COMMENT ON TABLE task_fields_for_task IS
'Relates all the custom task fields to a task';
