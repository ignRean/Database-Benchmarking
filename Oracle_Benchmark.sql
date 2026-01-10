-- 1. CLEANUP PREVIOUS RUNS
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE employees_benchmark';
    EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE departments_benchmark';
    EXCEPTION WHEN OTHERS THEN NULL;
END;
/

-- 2. SCHEMA SETUP
-- Creating a Normalized Schema to test Join Optimization
CREATE TABLE departments_benchmark (
    dept_id NUMBER PRIMARY KEY,
    dept_name VARCHAR2(50),
    location VARCHAR2(50)
);

CREATE TABLE employees_benchmark (
    emp_id NUMBER PRIMARY KEY,
    first_name VARCHAR2(50),
    last_name VARCHAR2(50),
    email VARCHAR2(100),
    salary NUMBER(10, 2),
    dept_id NUMBER, -- Foreign Key
    hire_date DATE
);

-- 3. DATA GENERATION (PL/SQL BULK INSERT)
-- Generating 50 Departments and 50,000 Employees
DECLARE
    v_dept_id NUMBER;
BEGIN
    -- Insert Departments
    FOR i IN 1..50 LOOP
        INSERT INTO departments_benchmark VALUES (i, 'Dept_'||i, 'Location_'||i);
    END LOOP;

    -- Insert Employees
    FOR i IN 1..50000 LOOP
        v_dept_id := ROUND(DBMS_RANDOM.VALUE(1, 50));
        INSERT INTO employees_benchmark VALUES (
            i, 
            'Fname_'||i, 
            'Lname_'||i, 
            'user'||i||'@company.com',
            ROUND(DBMS_RANDOM.VALUE(30000, 120000), 2),
            v_dept_id,
            SYSDATE - ROUND(DBMS_RANDOM.VALUE(1, 3650))
        );
    END LOOP;
    COMMIT;
END;
/

-- 4. BENCHMARK SECTION
-- We are useing executing timestamps to measure precise latency

PROMPT '>>> TEST 1: UNOPTIMIZED SEARCH (FULL TABLE SCAN) <<<'
SELECT count(*) FROM employees_benchmark WHERE dept_id = 25;

PROMPT '>>> OPTIMIZATION STEP: CREATING B-TREE INDEX <<<'
CREATE INDEX idx_emp_dept ON employees_benchmark(dept_id);

PROMPT '>>> TEST 2: OPTIMIZED SEARCH (INDEX RANGE SCAN) <<<'
SELECT count(*) FROM employees_benchmark WHERE dept_id = 25;

PROMPT '>>> TEST 3: JOIN PERFORMANCE (AGGREGATION) <<<'
SELECT d.dept_name, AVG(e.salary) as avg_sal
FROM employees_benchmark e
JOIN departments_benchmark d ON e.dept_id = d.dept_id
GROUP BY d.dept_name;