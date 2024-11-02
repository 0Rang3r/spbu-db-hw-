CREATE TABLE courses (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    is_exam BOOLEAN NOT NULL,
    min_grade INTEGER,
    max_grade INTEGER
);

CREATE TABLE groups (
    id SERIAL PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    short_name VARCHAR(50) NOT NULL,
    students_ids INTEGER[]
);

CREATE TABLE students (
    id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    group_id INTEGER REFERENCES groups(id),
    courses_ids INTEGER[]
);

CREATE TABLE course_grades (
    student_id INTEGER REFERENCES students(id),
    course_id INTEGER REFERENCES courses(id),
    grade INTEGER,
    grade_str VARCHAR(10),
    PRIMARY KEY (student_id, course_id)
);
INSERT INTO courses (name, is_exam, min_grade, max_grade)
VALUES
('Math', TRUE, 40, 100),
('Science', FALSE, 50, 100),
('History', TRUE, 35, 90);
INSERT INTO groups (full_name, short_name, students_ids)
VALUES
('Computer Science 101', 'CS101', ARRAY[1, 2]),
('Mathematics 201', 'MATH201', ARRAY[3]);
INSERT INTO students (first_name, last_name, group_id, courses_ids)
VALUES
('John', 'Doe', 1, ARRAY[1, 2]),
('Jane', 'Smith', 1, ARRAY[2, 3]),
('Alice', 'Johnson', 2, ARRAY[1, 3]);
INSERT INTO course_grades (student_id, course_id, grade, grade_str)
VALUES
(1, 1, 85, 'A'),
(1, 2, 70, 'B'),
(2, 2, 90, 'A'),
(3, 1, 60, 'C'),
(3, 3, 80, 'B');
SELECT students.first_name, students.last_name, courses.name, course_grades.grade
FROM course_grades
JOIN students ON course_grades.student_id = students.id
JOIN courses ON course_grades.course_id = courses.id;
SELECT students.first_name, students.last_name, courses.name, course_grades.grade
FROM course_grades
JOIN students ON course_grades.student_id = students.id
JOIN courses ON course_grades.course_id = courses.id
WHERE course_grades.grade > 80;
SELECT groups.full_name, AVG(course_grades.grade) AS avg_grade
FROM students
JOIN groups ON students.group_id = groups.id
JOIN course_grades ON students.id = course_grades.student_id
GROUP BY groups.full_name;
SELECT courses.name, MAX(course_grades.grade) AS max_grade
FROM course_grades
JOIN courses ON course_grades.course_id = courses.id
GROUP BY courses.name;