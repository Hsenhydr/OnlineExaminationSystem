import connection from '../db.js';

export const signup = async (req, res) => {
  const { email, password, major_id, name, role } = req.body;
  const platform = req.headers['x-client-platform'];

  if (!email || !password || !major_id || !name || !role) {
    return res.status(400).json({ message: 'All fields are required' });
  }

  if (role === 'student' && platform !== 'mobile') {
    return res.status(403).json({ message: 'Students can only sign up via mobile app' });
  }
  if (role === 'instructor' && platform !== 'web') {
    return res.status(403).json({ message: 'Instructors can only sign up via web' });
  }

  const sql = 'INSERT INTO users (name, email, password, role, major_id) VALUES (?, ?, ?, ?, ?)';
  const values = [name, email, password, role, major_id];

  try {
    await connection.execute(sql, values);
    res.status(201).json({ message: 'User registered successfully' });
  } catch (err) {
    if (err.code === 'ER_DUP_ENTRY') {
      return res.status(409).json({ message: 'Email already exists' });
    }
    return res.status(500).json({ message: 'Database error' });
  }
};

export const login = async (req, res) => {
  const { email, password } = req.body;
  const platform = req.headers['x-client-platform'];

  if (!email || !password) {
    return res.status(400).json({ message: 'Email and password required' });
  }

  try {
    const [results] = await connection.execute('SELECT * FROM users WHERE email = ?', [email]);

    if (results.length === 0) {
      return res.status(401).json({ message: 'Invalid email or password' });
    }

    const user = results[0];

    if (user.role === 'student' && platform !== 'mobile') {
      return res.status(403).json({ message: 'Students can only log in via mobile app' });
    }
    if (user.role === 'instructor' && platform !== 'web') {
      return res.status(403).json({ message: 'Instructors can only log in via web' });
    }

    if (user.password !== password) {
      return res.status(401).json({ message: 'Invalid email or password' });
    }

    const { password: _, ...userWithoutPassword } = user;
    res.json({ message: 'Login successful', user: userWithoutPassword });
  } catch (err) {
    return res.status(500).json({ message: 'Database error' });
  }
};
