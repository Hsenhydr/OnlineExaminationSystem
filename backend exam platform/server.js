import express from 'express';
import dotenv from 'dotenv';
import cors from 'cors'; // Import the cors package

import authRoutes from './routes/authRoutes.js';
import studentRoutes from './routes/studentRoutes.js'
import instructorRoutes from './routes/instructorRoutes.js'
import connection from './db.js';

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json());
app.use('/api/auth', authRoutes);
app.use('/api/student',studentRoutes);
app.use('/api/instructor',instructorRoutes)
const PORT = process.env.PORT || 3000;

app.get('/', async (req, res) => {
  const query = 'SELECT * FROM exams';

  try {
    const [results] = await connection.query(query);
    res.status(200).json(results);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});


app.listen(PORT, () => {
  console.log(`Server is running on http://localhost:${PORT}`);
});

