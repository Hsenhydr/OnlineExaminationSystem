import mysql from 'mysql2/promise';
import dotenv from 'dotenv';

dotenv.config();

let connection;

async function initializeConnection() {
  try {
    connection = await mysql.createConnection({
      host: process.env.DB_HOST,
      user: process.env.DB_USER,
      password: process.env.DB_PASSWORD,
      database: process.env.DB_NAME,
    });

    console.log('Connected to the MySQL database successfully with id', connection.threadId);
  } catch (err) {
    console.error('Error connecting to the database:', err.message);
    process.exit(1);
  }
}

await initializeConnection();

export default connection;
