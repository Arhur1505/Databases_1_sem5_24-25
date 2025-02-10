#include <iostream>
#include <vector>
#include <string>
#include <pqxx/pqxx>

using namespace std;
using namespace pqxx;

/**
 * Uniwersalna funkcja do zarządzania danymi w bazie.
 * @param conn         Połączenie z bazą danych.
 * @param schema       Nazwa schematu.
 * @param table        Nazwa tabeli.
 * @param operation    Rodzaj operacji: "insert", "update", "delete", "select".
 * @param columns      Kolumny (dla operacji insert i select).
 * @param values       Wartości (dla operacji insert).
 * @param updates      Zmiany (dla operacji update).
 * @param condition    Warunek (dla operacji update, delete i select).
 */
void manage_table(connection &conn, const string &schema, const string &table, const string &operation,
                  const vector<string> &columns = {}, const vector<string> &values = {},
                  const vector<string> &updates = {}, const string &condition = "") {
    try {
        string full_table_name = schema + "." + table;

        if (operation == "insert") {
            if (columns.empty() || values.empty() || columns.size() != values.size()) {
                throw invalid_argument("Liczba kolumn i wartości musi być równa dla operacji insert.");
            }

            string query = "INSERT INTO " + full_table_name + " (";
            for (size_t i = 0; i < columns.size(); ++i) {
                query += columns[i] + (i < columns.size() - 1 ? ", " : "");
            }
            query += ") VALUES (";
            for (size_t i = 0; i < values.size(); ++i) {
                query += "$" + to_string(i + 1) + (i < values.size() - 1 ? ", " : "");
            }
            query += ")";

            work transaction(conn);
            conn.prepare("insert_query", query);
            prepare::invocation invocation = transaction.prepared("insert_query");
            for (const auto &val : values) {
                invocation(val);
            }
            invocation.exec();
            transaction.commit();
            cout << "Dane zostały wstawione!" << endl;

        } else if (operation == "update") {
            if (updates.empty() || condition.empty()) {
                throw invalid_argument("Zmiany i warunek są wymagane dla operacji update.");
            }

            string query = "UPDATE " + full_table_name + " SET ";
            for (size_t i = 0; i < updates.size(); ++i) {
                query += updates[i] + (i < updates.size() - 1 ? ", " : "");
            }
            query += " WHERE " + condition;

            work transaction(conn);
            transaction.exec(query);
            transaction.commit();
            cout << "Dane zostały zaktualizowane!" << endl;

        } else if (operation == "delete") {
            if (condition.empty()) {
                throw invalid_argument("Warunek jest wymagany dla operacji delete.");
            }

            string query = "DELETE FROM " + full_table_name + " WHERE " + condition;

            work transaction(conn);
            transaction.exec(query);
            transaction.commit();
            cout << "Dane zostały usunięte!" << endl;

        } else if (operation == "select") {
            if (columns.empty()) {
                throw invalid_argument("Kolumny są wymagane dla operacji select.");
            }

            string query = "SELECT ";
            for (size_t i = 0; i < columns.size(); ++i) {
                query += columns[i] + (i < columns.size() - 1 ? ", " : "");
            }
            query += " FROM " + full_table_name;
            if (!condition.empty()) {
                query += " WHERE " + condition;
            }

            nontransaction transaction(conn);
            result res = transaction.exec(query);
            for (auto row : res) {
                for (auto field : row) {
                    cout << field.c_str() << " ";
                }
                cout << endl;
            }

        } else {
            throw invalid_argument("Nieznana operacja: " + operation);
        }
    } catch (const sql_error &e) {
        cerr << "SQL error: " << e.what() << endl;
        cerr << "Polecenie SQL: " << e.query() << endl;
    } catch (const exception &e) {
        cerr << "Błąd: " << e.what() << endl;
    }
}

int main() {
    string connection_string = "dbname=u2jozwiak user=u2jozwiak password=2jozwiak host=localhost port=5432";

    try {
        connection conn(connection_string);
        if (!conn.is_open()) {
            cerr << "Nie udało się połączyć z bazą danych!" << endl;
            return 1;
        }

        string schema = "kurs";

        cout << "Odczytanie danych z tabeli uczestnik:" << endl;
        manage_table(conn, schema, "uczestnik", "select", 
                     {"id_uczestnik", "nazwisko", "imie"}, 
                     {}, {}, 
                     "id_uczestnik=31");

        conn.disconnect();
    } catch (const exception &e) {
        cerr << "Błąd: " << e.what() << endl;
        return 1;
    }

    return 0;
}