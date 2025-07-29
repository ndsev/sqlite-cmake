#include <sqlite3.h>
#include <iostream>
#include <string>

int main() {
    sqlite3* db = nullptr;
    int rc;
    
    // Open an in-memory database
    rc = sqlite3_open(":memory:", &db);
    if (rc != SQLITE_OK) {
        std::cerr << "Can't open database: " << sqlite3_errmsg(db) << std::endl;
        return 1;
    }
    
    std::cout << "Successfully opened SQLite database" << std::endl;
    std::cout << "SQLite version: " << sqlite3_libversion() << std::endl;
    
    // Check which backend we're using
#ifdef SQLITE_USING_NDS_BACKEND
    std::cout << "Using NDS SQLite backend" << std::endl;
#else
    std::cout << "Using public SQLite backend" << std::endl;
#endif
    
    // Create a simple table
    const char* createTableSQL = 
        "CREATE TABLE IF NOT EXISTS test ("
        "id INTEGER PRIMARY KEY,"
        "name TEXT NOT NULL,"
        "value REAL"
        ");";
    
    char* errMsg = nullptr;
    rc = sqlite3_exec(db, createTableSQL, nullptr, nullptr, &errMsg);
    if (rc != SQLITE_OK) {
        std::cerr << "SQL error: " << errMsg << std::endl;
        sqlite3_free(errMsg);
        sqlite3_close(db);
        return 1;
    }
    
    std::cout << "Created test table" << std::endl;
    
    // Insert some data
    const char* insertSQL = 
        "INSERT INTO test (name, value) VALUES "
        "('Alice', 3.14), "
        "('Bob', 2.71), "
        "('Charlie', 1.41);";
    
    rc = sqlite3_exec(db, insertSQL, nullptr, nullptr, &errMsg);
    if (rc != SQLITE_OK) {
        std::cerr << "SQL error: " << errMsg << std::endl;
        sqlite3_free(errMsg);
        sqlite3_close(db);
        return 1;
    }
    
    std::cout << "Inserted test data" << std::endl;
    
    // Query the data
    const char* selectSQL = "SELECT name, value FROM test ORDER BY name;";
    sqlite3_stmt* stmt;
    
    rc = sqlite3_prepare_v2(db, selectSQL, -1, &stmt, nullptr);
    if (rc != SQLITE_OK) {
        std::cerr << "Failed to prepare statement: " << sqlite3_errmsg(db) << std::endl;
        sqlite3_close(db);
        return 1;
    }
    
    std::cout << "\nQuery results:" << std::endl;
    while ((rc = sqlite3_step(stmt)) == SQLITE_ROW) {
        const char* name = reinterpret_cast<const char*>(sqlite3_column_text(stmt, 0));
        double value = sqlite3_column_double(stmt, 1);
        std::cout << "  " << name << ": " << value << std::endl;
    }
    
    sqlite3_finalize(stmt);
    
    // Test FTS5 if enabled
    const char* fts5SQL = "CREATE VIRTUAL TABLE IF NOT EXISTS fts_test USING fts5(content);";
    rc = sqlite3_exec(db, fts5SQL, nullptr, nullptr, &errMsg);
    if (rc == SQLITE_OK) {
        std::cout << "\nFTS5 extension is available and working" << std::endl;
    } else {
        std::cout << "\nFTS5 extension test: " << errMsg << std::endl;
        sqlite3_free(errMsg);
    }
    
    // Test JSON1 if enabled
    const char* jsonSQL = "SELECT json_array(1, 2, 3);";
    rc = sqlite3_prepare_v2(db, jsonSQL, -1, &stmt, nullptr);
    if (rc == SQLITE_OK) {
        if (sqlite3_step(stmt) == SQLITE_ROW) {
            const char* jsonResult = reinterpret_cast<const char*>(sqlite3_column_text(stmt, 0));
            std::cout << "JSON1 extension is available, test result: " << jsonResult << std::endl;
        }
        sqlite3_finalize(stmt);
    } else {
        std::cout << "JSON1 extension not available" << std::endl;
    }
    
    // Close the database
    sqlite3_close(db);
    std::cout << "\nDatabase closed successfully" << std::endl;
    
    return 0;
}