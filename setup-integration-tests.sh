#!/bin/bash

set -e  # Exit on any error

echo "📁 Creating test folder structure..."
mkdir -p tests-integration/{sql,mongo,elastic,spel,utils}

echo "📝 Creating testData.js..."
cat <<EOT > tests-integration/utils/testData.js
module.exports = [
  { name: "denis", age: 37 },
  { name: "denis", age: 3 },
  { name: "oleg", age: 20 }
];
EOT

echo "🐳 Creating docker-compose.yml..."
cat <<EOT > tests-integration/docker-compose.yml
version: "3.9"
services:
  mysql:
    image: mysql:8
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: root
      MYSQL_DATABASE: testdb
    ports:
      - "3306:3306"
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 10s
      timeout: 5s
      retries: 5

  postgres:
    image: postgres:15
    restart: always
    environment:
      POSTGRES_USER: root
      POSTGRES_PASSWORD: root
      POSTGRES_DB: testdb
    ports:
      - "5432:5432"

  mongo:
    image: mongo:6
    restart: always
    ports:
      - "27017:27017"

  elasticsearch:
    image: elasticsearch:8.12.2
    environment:
      - discovery.type=single-node
      - xpack.security.enabled=false
    ports:
      - "9200:9200"
EOT

echo "🧪 Creating MySQL integration test script..."
cat <<EOT > tests-integration/sql/test-mysql.js
const mysql = require('mysql2/promise');
const testData = require('../utils/testData');

(async () => {
  try {
    const conn = await mysql.createConnection({
      host: 'localhost',
      user: 'root',
      password: 'root',
      database: 'testdb'
    });

    await conn.execute("DROP TABLE IF EXISTS people");
    await conn.execute("CREATE TABLE people (name VARCHAR(255), age INT)");

    for (const person of testData) {
      await conn.execute("INSERT INTO people (name, age) VALUES (?, ?)", [person.name, person.age]);
    }

    const [rows] = await conn.execute("SELECT * FROM people WHERE age >= 18 AND name = 'denis'");
    console.log("✅ Query Result:", rows);
    if (rows.length === 1 && rows[0].name === 'denis' && rows[0].age === 37) {
      console.log("✅ Integration test passed");
    } else {
      console.error("❌ Integration test failed");
      process.exit(1);
    }

    await conn.end();
  } catch (e) {
    console.error("❌ Error during MySQL test:", e);
    process.exit(1);
  }
})();
EOT

echo "✅ Setup complete!"
echo "Next steps:"
echo "1. Run: docker-compose -f tests-integration/docker-compose.yml up -d"
echo "2. Run: npm install mysql2"
echo "3. Run: node tests-integration/sql/test-mysql.js"
