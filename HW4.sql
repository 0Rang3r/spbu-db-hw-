-- Создание таблицы сотрудников employees
CREATE TABLE IF NOT EXISTS employees (
    employee_id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    position VARCHAR(50) NOT NULL,
    department VARCHAR(50) NOT NULL,
    salary NUMERIC(10, 2) NOT NULL,
    manager_id INT REFERENCES employees(employee_id)
);

-- Вставка примерных данных
INSERT INTO employees (name, position, department, salary, manager_id)
VALUES
    ('Alice Johnson', 'Менеджер', 'Отдел продаж', 85000, NULL),
    ('Bob Smith', 'Специалист по продажам', 'Отдел продаж', 50000, 1),
    ('Carol Lee', 'Специалист по продажам', 'Отдел продаж', 48000, 1),
    ('David Brown', 'Стажер по продажам', 'Отдел продаж', 30000, 2),
    ('Eve Davis', 'Разработчик', 'IT отдел', 75000, NULL),
    ('Frank Miller', 'Стажер', 'IT отдел', 35000, 5);

-- Создание таблицы продаж sales
CREATE TABLE IF NOT EXISTS sales(
    sale_id SERIAL PRIMARY KEY,
    employee_id INT REFERENCES employees(employee_id),
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    sale_date DATE NOT NULL
);

-- Вставка примерных данных
INSERT INTO sales (employee_id, product_id, quantity, sale_date)
VALUES
    (2, 1, 20, '2024-10-15'),
    (2, 2, 15, '2024-10-16'),
    (3, 1, 10, '2024-10-17'),
    (3, 3, 5, '2024-10-20'),
    (4, 2, 8, '2024-10-21'),
    (2, 1, 12, '2024-11-01');

-- Создание таблицы продуктов products
CREATE TABLE IF NOT EXISTS products (
    product_id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    price NUMERIC(10, 2) NOT NULL
);

-- Вставка примерных данных
INSERT INTO products (name, price)
VALUES
    ('Продукт A', 150.00),
    ('Продукт B', 200.00),
    ('Продукт C', 100.00);

-- Создание функции для проверки зарплаты
CREATE OR REPLACE FUNCTION check_salary()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.salary < 25000 THEN
        RAISE EXCEPTION 'Зарплата должна быть выше минимального уровня';
    END IF;
    RAISE NOTICE 'Проверка зарплаты пройдена, сотрудник: % , зарплата: %', NEW.name, NEW.salary;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Создание триггера для вызова функции проверки зарплаты
CREATE TRIGGER salary_check_trigger
BEFORE INSERT OR UPDATE ON employees
FOR EACH ROW
WHEN (NEW.salary IS NOT NULL)
EXECUTE FUNCTION check_salary();

-- Вставка сотрудников, соответствующих и не соответствующих условиям, с использованием транзакций
BEGIN;

-- Вставка сотрудника, соответствующего условиям
INSERT INTO employees (name, position, department, salary, manager_id)
VALUES ('X', 'Менеджер', 'Отдел продаж', 35000, NULL);

-- Попытка вставить сотрудника, не соответствующего условиям
BEGIN;
    INSERT INTO employees (name, position, department, salary, manager_id)
    VALUES ('Alice Johnson', 'Менеджер', 'Отдел продаж', 15000, NULL);
EXCEPTION WHEN OTHERS THEN
    ROLLBACK;
    RAISE NOTICE 'Сотрудник с зарплатой ниже минимального уровня не был добавлен';
END;

COMMIT;

-- Запрос данных для проверки
SELECT * FROM employees LIMIT 200;

-- Создание архива сотрудников employees_archive
CREATE TABLE IF NOT EXISTS employees_archive (
    archive_id SERIAL PRIMARY KEY,
    employee_id INT,
    name VARCHAR(50),
    position VARCHAR(50),
    department VARCHAR(50),
    salary NUMERIC(10, 2),
    deleted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Создание функции для архивации сотрудников
CREATE OR REPLACE FUNCTION archive_employee()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO employees_archive (employee_id, name, position, department, salary)
    VALUES (OLD.employee_id, OLD.name, OLD.position, OLD.department, OLD.salary);
    RAISE NOTICE 'Сотрудник % был архивирован', OLD.name;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- Создание триггера для архивации сотрудников перед удалением
CREATE TRIGGER trigger_archive_employee
BEFORE DELETE ON employees
FOR EACH ROW
EXECUTE FUNCTION archive_employee();

-- Создание функции для записи обновлений зарплаты
CREATE OR REPLACE FUNCTION log_salary_update()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.salary <> OLD.salary THEN
        RAISE NOTICE 'Зарплата сотрудника % была обновлена с % на %', OLD.employee_id, OLD.salary, NEW.salary;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Создание триггера для записи обновлений зарплаты
CREATE TRIGGER trigger_log_salary_update
AFTER UPDATE ON employees
FOR EACH ROW
WHEN (OLD.salary IS DISTINCT FROM NEW.salary)
EXECUTE FUNCTION log_salary_update();

-- Создание функции для обновления зарплаты при изменении должности
CREATE OR REPLACE FUNCTION update_salary_on_position_change()
RETURNS TRIGGER AS $$
BEGIN
    RAISE NOTICE 'Изменение должности: % -> %', OLD.position, NEW.position;
    IF NEW.position = 'Менеджер' THEN
        NEW.salary = 100000;
    ELSIF NEW.position = 'Разработчик' THEN
        NEW.salary = 80000;
    ELSE
        NEW.salary = 60000;
    END IF;
    RAISE NOTICE 'Зарплата сотрудника % после изменения должности составляет %', NEW.name, NEW.salary;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Создание триггера для обновления зарплаты при изменении должности
CREATE TRIGGER trigger_update_salary
BEFORE UPDATE ON employees
FOR EACH ROW
WHEN (OLD.position IS DISTINCT FROM NEW.position)
EXECUTE FUNCTION update_salary_on_position_change();

-- Вставка тестового сотрудника и выполнение операций
INSERT INTO employees (name, position, department, salary)
VALUES
    ('Test', 'Тестировщик', 'QA', 30000);

-- Запрос сотрудника с именем 'Test'
SELECT * FROM employees WHERE name = 'Test' LIMIT 5;

-- Обновление имени сотрудника
UPDATE employees
SET name = 'Test2'
WHERE name = 'Test';

-- Запрос сотрудника с именем 'Test2'
SELECT * FROM employees WHERE name = 'Test2' LIMIT 5;

-- Обновление должности сотрудника
UPDATE employees
SET position = 'Менеджер'
WHERE name = 'Test2';

-- Запрос сотрудника с именем 'Test2'
SELECT * FROM employees WHERE name = 'Test2' LIMIT 5;

-- Удаление сотрудников, содержащих 'Test' в имени
DELETE FROM employees WHERE name ILIKE '%Test%';

-- Пример транзакции
BEGIN;

-- Вставка сотрудника, соответствующего условиям
INSERT INTO employees (name, position, department, salary, manager_id)
VALUES ('X', 'Менеджер', 'Отдел продаж', 35000, NULL);

-- Попытка вставить сотрудника, не соответствующего условиям
INSERT INTO employees (name, position, department, salary, manager_id)
VALUES ('Alice Johnson', 'Менеджер', 'Отдел продаж', 15000, NULL);

-- Подтверждение транзакции
COMMIT;

-- Откат транзакции
ROLLBACK;

-- Запрос удаленного сотрудника
SELECT * FROM employees WHERE employee_id = 120;

-- Запрос записи из архива сотрудников
SELECT * FROM employees_archive WHERE employee_id = 120;

-- Уровни сообщений RAISE
-- DEBUG: Для детальной отладки, часто используется при разработке и решении сложных проблем.
-- LOG: Записывает сообщения в журнал PostgreSQL, но не выводит их клиенту.
-- NOTICE: Информационные сообщения, видимые пользователю, часто используются для отладки.
-- WARNING: Предупреждения, не прерывающие выполнение, но требующие внимания.
-- EXCEPTION: Вызывает ошибку, прерывает выполнение и откатывает текущую транзакцию.
