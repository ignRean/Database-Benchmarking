// 1. DATABASE INIT
use db_assignment_final
db.dropDatabase() // Ensure clean slate

// 2. DATA GENERATION
// Creating 50,000 nested documents to simulate real-world NoSQL structure
print(">>> Generating 50,000 Documents... Please wait.");

var bulkOp = db.employees.initializeUnorderedBulkOp();
var departments = ["HR", "Engineering", "Sales", "Marketing", "Finance"];

for (var i = 0; i < 50000; i++) {
    bulkOp.insert({
        emp_id: i,
        name: { first: "EmpFirst" + i, last: "EmpLast" + i }, // Nested Object
        department: departments[Math.floor(Math.random() * departments.length)],
        salary: Math.floor(Math.random() * 100000) + 30000,
        metadata: { "hire_year": 2020 + (i % 5), "active": true }
    });
}
bulkOp.execute();
print(">>> Data Load Complete.");

// 3. BENCHMARK: UNOPTIMIZED READ
print("\n>>> TEST 1: UNOPTIMIZED QUERY (COLLSCAN)");
var start = new Date();
var result1 = db.employees.find({ "department": "Engineering" }).toArray();
var end = new Date();
print("Time taken: " + (end - start) + "ms");


var explain1 = db.employees.find({ "department": "Engineering" }).explain("executionStats");
print("Docs Examined (Unoptimized): " + explain1.executionStats.totalDocsExamined);

// 5. OPTIMIZATION
print("\n>>> APPLYING INDEX on { department: 1 }");
db.employees.createIndex({ "department": 1 });

// 6. BENCHMARK: OPTIMIZED READ
print(">>> TEST 2: OPTIMIZED QUERY (IXSCAN)");
var start = new Date();
var result2 = db.employees.find({ "department": "Engineering" }).toArray();
var end = new Date();
print("Time taken: " + (end - start) + "ms");

var explain2 = db.employees.find({ "department": "Engineering" }).explain("executionStats");
print("Docs Examined (Optimized): " + explain2.executionStats.totalDocsExamined);

// 7. AGGREGATION PIPELINE TEST
print("\n>>> TEST 3: COMPLEX AGGREGATION");
var start = new Date();
db.employees.aggregate([
    { $match: { "metadata.active": true } },
    { $group: { _id: "$department", avg_salary: { $avg: "$salary" } } },
    { $sort: { avg_salary: -1 } }
]).toArray();
var end = new Date();
print("Aggregation Time: " + (end - start) + "ms");