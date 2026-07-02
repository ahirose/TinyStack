CREATE TABLE users (id INT, name TEXT, email TEXT);
CREATE TABLE products (id INT, name TEXT, price INT, category TEXT);
CREATE TABLE schema_docs (table_name TEXT, column_name TEXT, description TEXT);
CREATE TABLE query_history (id INT, nl_query TEXT, sql_text TEXT, created_at TEXT);

INSERT INTO users (id, name, email) VALUES (1, 'Alice', 'alice@example.com');
INSERT INTO users (id, name, email) VALUES (2, 'Bob', 'bob@example.com');
INSERT INTO users (id, name, email) VALUES (3, 'Carol', 'carol@example.com');

INSERT INTO products (id, name, price, category) VALUES (1, 'Notebook', 500, 'stationery');
INSERT INTO products (id, name, price, category) VALUES (2, 'Pen', 120, 'stationery');
INSERT INTO products (id, name, price, category) VALUES (3, 'Keyboard', 8000, 'electronics');

INSERT INTO schema_docs (table_name, column_name, description) VALUES ('users', 'id', 'Unique user identifier');
INSERT INTO schema_docs (table_name, column_name, description) VALUES ('users', 'name', 'User display name');
INSERT INTO schema_docs (table_name, column_name, description) VALUES ('users', 'email', 'User email address');
INSERT INTO schema_docs (table_name, column_name, description) VALUES ('products', 'id', 'Unique product identifier');
INSERT INTO schema_docs (table_name, column_name, description) VALUES ('products', 'name', 'Product name');
INSERT INTO schema_docs (table_name, column_name, description) VALUES ('products', 'price', 'Price in yen');
INSERT INTO schema_docs (table_name, column_name, description) VALUES ('products', 'category', 'Product category');

INSERT INTO query_history (id, nl_query, sql_text, created_at) VALUES (1, 'Show all users', 'SELECT * FROM users;');
INSERT INTO query_history (id, nl_query, sql_text, created_at) VALUES (2, 'List products under 1000 yen', 'SELECT * FROM products WHERE price = 500;');
INSERT INTO query_history (id, nl_query, sql_text, created_at) VALUES (3, '全ユーザーを表示', 'SELECT * FROM users;');
