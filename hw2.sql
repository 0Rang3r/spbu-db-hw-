-- Создание связующих таблиц для нормализации отношений многие ко многим
CREATE TABLE student_courses (
    id SERIAL PRIMARY KEY,
    student_id INTEGER REFERENCES students(id),
    course_id INTEGER REFERENCES courses(id),
    UNIQUE (student_id, course_id)
);

CREATE TABLE group_courses (
    id SERIAL PRIMARY KEY,
    group_id INTEGER REFERENCES groups(id),
    course_id INTEGER REFERENCES courses(id),
    UNIQUE (group_id, course_id)
);

-- Заполнение новых таблиц на основе существующих данных
-- Вставка записей в таблицу student_courses на основе массива courses_ids из таблицы студентов
INSERT INTO student_courses (student_id, course_id)
SELECT students.id, unnest(students.courses_ids)
FROM students;

-- Удаление устаревших столбцов
ALTER TABLE students DROP COLUMN courses_ids;
ALTER TABLE groups DROP COLUMN students_ids;

-- Добавление уникального ограничения на поле name в таблице courses
ALTER TABLE courses ADD CONSTRAINT unique_course_name UNIQUE (name);

-- Создание индекса на поле group_id в таблице students
CREATE INDEX idx_students_group_id ON students(group_id);
-- Создание индекса может улучшить производительность запросов, особенно при соединении и фильтрации по group_id. Например, при запросе студентов, принадлежащих к определенной группе, индекс может сократить количество строк для поиска и повысить скорость выполнения запроса.

-- Обновленные запросы
-- Запрос 1: Получить студентов и их оценки по курсам
SELECT students.first_name, students.last_name, courses.name, course_grades.grade
FROM course_grades
JOIN students ON course_grades.student_id = students.id
JOIN courses ON course_grades.course_id = courses.id
LIMIT 10;

-- Запрос 2: Получить студентов с оценками выше 80
SELECT students.first_name, students.last_name, courses.name, course_grades.grade
FROM course_grades
JOIN students ON course_grades.student_id = students.id
JOIN courses ON course_grades.course_id = courses.id
WHERE course_grades.grade > 80
LIMIT 10;

-- Запрос 3: Получить среднюю оценку для каждой группы
SELECT groups.full_name, AVG(course_grades.grade) AS avg_grade
FROM students
JOIN groups ON students.group_id = groups.id
JOIN course_grades ON students.id = course_grades.student_id
GROUP BY groups.full_name
LIMIT 10;

-- Запрос 4: Получить максимальную оценку по каждому курсу
SELECT courses.name, MAX(course_grades.grade) AS max_grade
FROM course_grades
JOIN courses ON course_grades.course_id = courses.id
GROUP BY courses.name
LIMIT 10;

-- Запрос 5: Показать всех студентов и их список курсов, найти студентов, чья средняя оценка по курсам выше, чем у любого другого студента в их группе
SELECT students.first_name, students.last_name, courses.name
FROM students
JOIN student_courses ON students.id = student_courses.student_id
JOIN courses ON student_courses.course_id = courses.id
JOIN course_grades ON students.id = course_grades.student_id AND courses.id = course_grades.course_id
JOIN groups ON students.group_id = groups.id
GROUP BY students.id, students.first_name, students.last_name, groups.id, courses.name
HAVING AVG(course_grades.grade) > ALL (
    SELECT AVG(course_grades.grade)
    FROM students AS other_students
    JOIN course_grades ON other_students.id = course_grades.student_id
    WHERE other_students.group_id = groups.id AND other_students.id <> students.id
    GROUP BY other_students.id
)
ORDER BY students.first_name, students.last_name;

-- Запрос 6: Подсчитать количество студентов по каждому курсу
SELECT courses.name, COUNT(student_courses.student_id) AS student_count
FROM courses
JOIN student_courses ON courses.id = student_courses.course_id
GROUP BY courses.name;

-- Запрос 7: Найти среднюю оценку по каждому курсу
SELECT courses.name, AVG(course_grades.grade) AS avg_grade
FROM courses
JOIN course_grades ON courses.id = course_grades.course_id
GROUP BY courses.name;
