-- Удалить существующую таблицу
DROP TABLE IF EXISTS enrollments, courses, teachers, students;

-- Создать таблицу студентов
CREATE TABLE students (
    student_id INT PRIMARY KEY,
    name VARCHAR(100),
    age INT,
    gender VARCHAR(10)
);

-- Создать индекс для столбца student_id
CREATE INDEX idx_student_id ON students(student_id);

-- Создать таблицу преподавателей
CREATE TABLE teachers (
    teacher_id INT PRIMARY KEY,
    name VARCHAR(100),
    department VARCHAR(100)
);

-- Создать индекс для столбца teacher_id
CREATE INDEX idx_teacher_id ON teachers(teacher_id);

-- Создать таблицу курсов
CREATE TABLE courses (
    course_id INT PRIMARY KEY,
    name VARCHAR(100),
    teacher_id INT,
    FOREIGN KEY (teacher_id) REFERENCES teachers(teacher_id)
);

-- Создать индекс для столбцов course_id и teacher_id
CREATE INDEX idx_course_id ON courses(course_id);
CREATE INDEX idx_course_teacher_id ON courses(teacher_id);

-- Создать таблицу выбора курсов (связывающую студентов и курсы)
CREATE TABLE enrollments (
    student_id INT,
    course_id INT,
    enrollment_date DATE,
    PRIMARY KEY (student_id, course_id),
    FOREIGN KEY (student_id) REFERENCES students(student_id),
    FOREIGN KEY (course_id) REFERENCES courses(course_id)
);

-- Создать составной индекс для столбцов student_id и course_id в таблице enrollments
CREATE INDEX idx_enrollments_student_id ON enrollments(student_id);
CREATE INDEX idx_enrollments_course_id ON enrollments(course_id);

-- Добавить триггер: проверять, является ли дата вставки выбора курсов датой в будущем
DELIMITER $$

CREATE TRIGGER check_enrollment_date
BEFORE INSERT ON enrollments
FOR EACH ROW
BEGIN
    IF NEW.enrollment_date > CURRENT_DATE THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Дата выбора курса не может быть в будущем!';
    END IF;
END $$

DELIMITER ;

-- Вставить данные студента
INSERT INTO students (student_id, name, age, gender) VALUES
(1, 'Наташа', 20, 'женщина'),
(2, 'Боб', 21, 'мужчина'),
(3, 'Антон', 19, 'мужчина'),
(4, 'Елена', 22, 'женщина');

-- Вставить данные преподавателя
INSERT INTO teachers (teacher_id, name, department) VALUES
(1, 'Иван', 'Информатика'),
(2, 'Мидлюра ', 'математика'),
(3, 'Андрей', 'физика');

-- Вставить данные курса
INSERT INTO courses (course_id, name, teacher_id) VALUES
(1, 'Введение в программирование', 1),
(2, 'математический анализ I', 2),
(3, 'классическая механика', 3);

-- Вставить данные о выборе курсов
INSERT INTO enrollments (student_id, course_id, enrollment_date) VALUES
(1, 1, '2023-09-01'),
(1, 2, '2023-09-01'),
(2, 1, '2023-09-02'),
(3, 2, '2023-09-03'),
(4, 3, '2023-09-04'),
(2, 3, '2023-09-05');

-- Вставка данных о выборе курсов (попытка вставить дату в будущем, должно быть отклонено)
-- INSERT INTO enrollments (student_id, course_id, enrollment_date) VALUES (1, 1, '2025-01-01'); 

-- 1. Запросить информацию о всех студентах
SELECT * FROM Students;

-- 2. Запросить все курсы и их преподавателей
SELECT c.course_id, c.name AS course_name, t.name AS teacher_name
FROM Courses c
JOIN Teachers t ON c.teacher_id = t.teacher_id;

-- 3. Запросить всех студентов, которые записались на курс "математический анализ I"
SELECT s.student_id, s.name
FROM Enrollments e
JOIN Students s ON e.student_id = s.student_id
JOIN Courses c ON e.course_id = c.course_id
WHERE c.name = 'математический анализ I';

-- 4. Подсчитать количество студентов, записанных на каждый курс
SELECT c.name AS course_name, COUNT(e.student_id) AS student_count
FROM Courses c
LEFT JOIN Enrollments e ON c.course_id = e.course_id
GROUP BY c.course_id, c.name;

-- 5. Вычислить средний возраст студентов
SELECT AVG(age) AS average_age FROM Students;

-- 6. Подсчитать количество курсов, которые преподает каждый преподаватель
SELECT t.name AS teacher_name, COUNT(c.course_id) AS course_count
FROM Teachers t
LEFT JOIN Courses c ON t.teacher_id = c.teacher_id
GROUP BY t.teacher_id, t.name;

-- 7. Подсчитать общее количество записей на курсы
SELECT COUNT(*) AS total_enrollments FROM Enrollments;

-- 8. Подсчитать количество студентов по полу
SELECT gender, COUNT(*) AS count
FROM Students
GROUP BY gender;
