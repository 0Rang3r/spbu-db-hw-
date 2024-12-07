-- Если таблица уже существует, удалить её
DROP TABLE IF EXISTS enrollments;
DROP TABLE IF EXISTS courses;
DROP TABLE IF EXISTS teachers;
DROP TABLE IF EXISTS students;

-- Создать временную таблицу студентов
CREATE TEMPORARY TABLE students (
    student_id INT PRIMARY KEY,
    name VARCHAR(100),
    age INT,
    gender VARCHAR(10)
);

CREATE INDEX idx_student_id ON students(student_id);

-- Создать временную таблицу преподавателей
CREATE TEMPORARY TABLE teachers (
    teacher_id INT PRIMARY KEY,
    name VARCHAR(100),
    department VARCHAR(100)
);

CREATE INDEX idx_teacher_id ON teachers(teacher_id);

-- Создать временную таблицу курсов с внешним ключом на преподавателей
CREATE TEMPORARY TABLE courses (
    course_id INT PRIMARY KEY,
    name VARCHAR(100),
    teacher_id INT REFERENCES teachers(teacher_id)
);

CREATE INDEX idx_course_id ON courses(course_id);
CREATE INDEX idx_course_teacher_id ON courses(teacher_id);

-- Создать временную таблицу записей на курсы с внешними ключами на студентов и курсы
CREATE TEMPORARY TABLE enrollments (
    student_id INT,
    course_id INT,
    enrollment_date DATE,
    PRIMARY KEY (student_id, course_id),
    FOREIGN KEY (student_id) REFERENCES students(student_id),
    FOREIGN KEY (course_id) REFERENCES courses(course_id)
);

CREATE INDEX idx_enrollments_student_id ON enrollments(student_id);
CREATE INDEX idx_enrollments_course_id ON enrollments(course_id);

-- Создать функцию триггера для проверки, чтобы enrollment_date не превышала текущую дату
CREATE OR REPLACE FUNCTION check_enrollment_date()
RETURNS trigger AS $$
BEGIN
    IF NEW.enrollment_date > CURRENT_DATE THEN
        RAISE EXCEPTION 'Дата выбора курса не может быть в будущем!';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Создать триггер, использующий эту функцию
CREATE TRIGGER check_enrollment_date
BEFORE INSERT ON enrollments
FOR EACH ROW
EXECUTE PROCEDURE check_enrollment_date();

-- Добавить данные о студентах
INSERT INTO students (student_id, name, age, gender) VALUES
(1, 'Наташа', 20, 'женщина'),
(2, 'Боб', 21, 'мужчина'),
(3, 'Антон', 19, 'мужчина'),
(4, 'Елена', 22, 'женщина');

-- Добавить данные о преподавателях
INSERT INTO teachers (teacher_id, name, department) VALUES
(1, 'Иван', 'Информатика'),
(2, 'Мидлюра', 'Математика'),
(3, 'Андрей', 'Физика');

-- Добавить данные о курсах
INSERT INTO courses (course_id, name, teacher_id) VALUES
(1, 'Введение в программирование', 1),
(2, 'Математический анализ I', 2),
(3, 'Классическая механика', 3);

-- Добавить данные о записях на курсы
INSERT INTO enrollments (student_id, course_id, enrollment_date) VALUES
(1, 1, '2023-09-01'),
(1, 2, '2023-09-01'),
(2, 1, '2023-09-02'),
(3, 2, '2023-09-03'),
(4, 3, '2023-09-04'),
(2, 3, '2023-09-05');

-- Запрос 1: Получить информацию обо всех студентах
SELECT * FROM students LIMIT 10;

-- Запрос 2: Получить все курсы и их преподавателей
SELECT c.course_id, c.name AS course_name, t.name AS teacher_name
FROM courses c
JOIN teachers t ON c.teacher_id = t.teacher_id
LIMIT 10;

-- Запрос 3: Получить всех студентов, записанных на курс "Математический анализ I"
SELECT s.student_id, s.name
FROM enrollments e
JOIN students s ON e.student_id = s.student_id
JOIN courses c ON e.course_id = c.course_id
WHERE c.name = 'Математический анализ I'
LIMIT 10;

-- Запрос 4: Подсчитать количество студентов, записанных на каждый курс
SELECT c.name AS course_name, COUNT(e.student_id) AS student_count
FROM courses c
LEFT JOIN enrollments e ON c.course_id = e.course_id
GROUP BY c.course_id, c.name
LIMIT 10;

-- Запрос 5: Вычислить средний возраст студентов
SELECT AVG(age) AS average_age FROM students LIMIT 1;

-- Запрос 6: Подсчитать количество курсов, которые ведёт каждый преподаватель
SELECT t.name AS teacher_name, COUNT(c.course_id) AS course_count
FROM teachers t
LEFT JOIN courses c ON t.teacher_id = c.teacher_id
GROUP BY t.teacher_id, t.name
LIMIT 10;

-- Запрос 7: Подсчитать общее количество записей на курсы
SELECT COUNT(*) AS total_enrollments FROM enrollments LIMIT 1;

-- Запрос 8: Подсчитать количество студентов по полу
SELECT gender, COUNT(*) AS count
FROM students
GROUP BY gender LIMIT 10;
