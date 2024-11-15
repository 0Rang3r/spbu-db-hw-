-- Удалить индекс idx_sales_employee_date;
CREATE TABLE IF NOT EXISTS employees (
    employee_id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    position VARCHAR(50) NOT NULL,
    department VARCHAR(50) NOT NULL,
    salary NUMERIC(10, 2) NOT NULL,
    manager_id INT REFERENCES employees(employee_id)
);

-- Вставить пример данных в таблицу employees
INSERT INTO employees (name, position, department, salary, manager_id)
VALUES
    ('Alice Johnson', 'Manager', 'Sales', 85000, NULL),
    ('Bob Smith', 'Sales Associate', 'Sales', 50000, 1),
    ('Carol Lee', 'Sales Associate', 'Sales', 48000, 1),
    ('David Brown', 'Sales Intern', 'Sales', 30000, 2),
    ('Eve Davis', 'Developer', 'IT', 75000, NULL),
    ('Frank Miller', 'Intern', 'IT', 35000, 5);

-- Просмотреть данные из таблицы employees
SELECT * FROM employees LIMIT 5;

-- Создать таблицу sales
CREATE TABLE IF NOT EXISTS sales(
    sale_id SERIAL PRIMARY KEY,
    employee_id INT REFERENCES employees(employee_id),
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    sale_date DATE NOT NULL
);

-- Вставить пример данных в таблицу sales
INSERT INTO sales (employee_id, product_id, quantity, sale_date)
VALUES
    (2, 1, 20, '2024-10-15'),
    (2, 2, 15, '2024-10-16'),
    (3, 1, 10, '2024-10-17'),
    (3, 3, 5, '2024-10-20'),
    (4, 2, 8, '2024-10-21'),
    (2, 1, 12, '2024-11-01');

-- Просмотреть данные из таблицы sales
SELECT * FROM sales LIMIT 5;

-- Создать таблицу products
CREATE TABLE IF NOT EXISTS products (
    product_id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    price NUMERIC(10, 2) NOT NULL
);

-- Вставить пример данных в таблицу products
INSERT INTO products (name, price)
VALUES
    ('Product A', 150.00),
    ('Product B', 200.00),
    ('Product C', 100.00);

-- Создать временную таблицу sales_temp
CREATE TEMP TABLE sales_temp AS
SELECT * FROM sales;

-- Просмотреть данные из таблицы sales_temp
SELECT * FROM sales_temp LIMIT 3;

-- Удалить временную таблицу sales_temp
DROP TABLE sales_temp;

-- Создать временную таблицу sales_summary, используя группировку данных
CREATE TEMP TABLE sales_summary AS
SELECT department, position, SUM(salary) AS total_salary
FROM employees
GROUP BY department, position;

-- Просмотреть данные из таблицы sales_summary
SELECT * FROM sales_summary;

-- Создать временную таблицу current_month_sales, получить продажи товаров за текущий месяц
CREATE TEMP TABLE current_month_sales AS
SELECT product_id, SUM(quantity) AS total_sales
FROM sales
WHERE date_part('month', sale_date) = date_part('month', CURRENT_DATE)
GROUP BY product_id;

-- Просмотреть данные из таблицы current_month_sales
SELECT * FROM current_month_sales LIMIT 5;

-- Удалить временную таблицу current_month_sales
DROP TABLE current_month_sales;

-- Создать представление sales_view
CREATE VIEW sales_view AS
SELECT * FROM sales;

-- Удалить представление sales_view
DROP VIEW sales_view;

-- Использовать CTE для создания иерархии сотрудников
WITH employee_hierarchy AS (
    SELECT e1.name AS manager, e2.name AS employee
    FROM employees e1
    JOIN employees e2 ON e1.employee_id = e2.manager_id
)
SELECT * FROM employee_hierarchy LIMIT 5;

-- Использовать CTE для вычисления средней зарплаты в каждом отделе
WITH department_avg_salary AS (
    SELECT department, AVG(salary) AS average_salary
    FROM employees
    GROUP BY department
)
SELECT * FROM department_avg_salary;

-- Выполнить запрос и проанализировать производительность
EXPLAIN ANALYZE
SELECT * FROM employees WHERE department = 'Sales';

-- Создать индекс для ускорения запросов по полю department
CREATE INDEX idx_department ON employees(department);

-- Снова выполнить запрос и проанализировать производительность
EXPLAIN ANALYZE
SELECT * FROM employees WHERE department = 'Sales';

-- Удалить индекс
DROP INDEX idx_department;

-- Массово вставить больше данных в таблицу employees
INSERT INTO employees (name, position, department, salary, manager_id)
VALUES
    ('Alice Johnson', 'Manager', 'Sales', 85000, NULL),
    ('Bob Smith', 'Sales Associate', 'Sales', 50000, 1),
    ('Carol Lee', 'Sales Associate', 'Sales', 48000, 1),
    ('David Brown', 'Sales Intern', 'Sales', 30000, 2),
    ('Eve Davis', 'Developer', 'IT', 75000, NULL),
    ('Frank Miller', 'Intern', 'IT', 35000, 5);

-- Снова выполнить запрос и проанализировать производительность
EXPLAIN ANALYZE
SELECT * FROM employees WHERE department = 'Sales';

-- Создать индекс для ускорения запросов
CREATE INDEX idx_department ON employees(department);

-- Снова выполнить запрос и проанализировать производительность
EXPLAIN ANALYZE
SELECT * FROM employees WHERE department = 'Sales';

-- Удалить индекс
DROP INDEX idx_department;

-- Выполнить запрос и проанализировать данные продаж
EXPLAIN ANALYZE
SELECT product_id, SUM(quantity) AS total_sales
FROM sales
WHERE date_part('month', sale_date) = date_part('month', CURRENT_DATE)
GROUP BY product_id
ORDER BY total_sales DESC
LIMIT 5;

-- Создать индекс для ускорения запросов по sale_date
CREATE INDEX idx_sale_date ON sales(sale_date);

-- Выполнить пример запроса для проверки эффекта индекса
SELECT * FROM sales WHERE sale_date BETWEEN '2024-11-01' AND '2024-11-30' LIMIT 5;

-- Создать временную таблицу high_sales_products, содержащую продукты с продажами более 10 за последние 7 дней
CREATE TEMP TABLE high_sales_products AS
SELECT product_id, SUM(quantity) AS total_quantity
FROM sales
WHERE sale_date >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY product_id
HAVING SUM(quantity) > 10;

-- Просмотреть данные из таблицы high_sales_products
SELECT * FROM high_sales_products;

-- Использовать CTE для вычисления общей и средней продаж каждого сотрудника за последние 30 дней
WITH employee_sales_stats AS (
    SELECT 
        employee_id,
        SUM(quantity) AS total_sales,
        AVG(quantity) AS average_sales
    FROM 
        sales
    WHERE 
        sale_date >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY 
        employee_id
)
-- Запросить сотрудников с продажами выше среднего по компании
SELECT 
    e.name, 
    ess.total_sales, 
    ess.average_sales
FROM 
    employee_sales_stats ess
JOIN 
    employees e ON ess.employee_id = e.employee_id
WHERE 
    ess.total_sales > (SELECT AVG(total_sales) FROM employee_sales_stats);

-- Использовать CTE для создания иерархической структуры сотрудников, показывая всех сотрудников под конкретным менеджером
WITH RECURSIVE employee_hierarchy AS (
    SELECT 
        employee_id, 
        name, 
        manager_id, 
        1 AS level
    FROM 
        employees
    WHERE 
        name = 'Alice Johnson'  

    UNION ALL

    -- Рекурсивно найти всех подчиненных сотрудников
    SELECT 
        e.employee_id, 
        e.name, 
        e.manager_id, 
        eh.level + 1
    FROM 
        employees e
    JOIN 
        employee_hierarchy eh ON e.manager_id = eh.employee_id
)
-- Запросить результаты
SELECT 
    *
FROM 
    employee_hierarchy;

-- Использовать CTE для запроса топ-3 продуктов по продажам в текущем и прошлом месяце
WITH monthly_sales AS (
    SELECT 
        product_id, 
        SUM(quantity) AS total_quantity,
        date_trunc('month', sale_date) AS sale_month
    FROM 
        sales
    WHERE 
        sale_date >= date_trunc('month', CURRENT_DATE - INTERVAL '1 month')
    GROUP BY 
        product_id, 
        date_trunc('month', sale_date)
),
ranked_sales AS (
    SELECT 
        product_id,
        total_quantity,
        sale_month,
        ROW_NUMBER() OVER (
            PARTITION BY sale_month 
            ORDER BY total_quantity DESC
        ) AS rank
    FROM 
        monthly_sales
)
SELECT 
    CASE 
        WHEN sale_month = date_trunc('month', CURRENT_DATE) THEN 'Текущий месяц'
        WHEN sale_month = date_trunc('month', CURRENT_DATE - INTERVAL '1 month') THEN 'Прошлый месяц'
        ELSE TO_CHAR(sale_month, 'YYYY-MM')
    END AS month_label,
    product_id,
    total_quantity
FROM 
    ranked_sales
WHERE 
    rank <= 3
ORDER BY 
    sale_month DESC,
    rank ASC;

-- Создать индекс на полях employee_id и sale_date таблицы sales
CREATE INDEX idx_sales_employee_date ON sales(employee_id, sale_date);

-- Использовать EXPLAIN ANALYZE для оценки влияния индекса на производительность запросов

-- 1. Без созданного индекса, использовать EXPLAIN ANALYZE для оценки производительности запроса
-- DROP INDEX IF EXISTS idx_sales_employee_date;

EXPLAIN ANALYZE
SELECT * FROM sales
WHERE employee_id = 2 AND sale_date BETWEEN '2024-10-01' AND '2024-10-31';

-- 2. Создать индекс
-- CREATE INDEX idx_sales_employee_date ON sales(employee_id, sale_date);

-- 3. Снова использовать EXPLAIN ANALYZE для оценки производительности запроса
EXPLAIN ANALYZE
SELECT * FROM sales
WHERE employee_id = 2 AND sale_date BETWEEN '2024-10-01' AND '2024-10-31';

-- 4. Сравнить планы выполнения и показатели производительности двух запросов

-- Удалить индекс idx_sales_employee_date;
