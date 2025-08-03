import connection from '../db.js';

export const createExamWithQuestions = async (req, res) => {
  const { title, duration, major_id, questions } = req.body;
  if (!title || !duration || !major_id || !Array.isArray(questions) || questions.length === 0) {
    return res.status(400).json({ message: 'Please provide exam details and at least one question' });
  }

  try {
    const [examResult] = await connection.query(
      'INSERT INTO exams (title, duration, major_id) VALUES (?, ?, ?)',
      [title, duration, major_id]
    );
    const examId = examResult.insertId;
    
    const questionValues = questions.map(q => [
      examId,
      q.question_text,
      q.choice_a,
      q.choice_b,
      q.choice_c,
      q.choice_d,
      q.correct_answer
    ]);

    await connection.query(
      `INSERT INTO questions 
       (exam_id, question_text, choice_a, choice_b, choice_c, choice_d, correct_answer)
       VALUES ?`,
      [questionValues]
    );

    res.status(201).json({ message: 'Exam and questions created successfully', examId });
  } catch (error) {
    res.status(500).json({ message: 'Database error', error: error.message });
  }
};

export const deleteExam = async (req, res) => {
  const examId = req.params.id;

  if (!examId) {
    return res.status(400).json({ message: 'Exam ID is required' });
  }

  try {
    // Delete dependent rows first to avoid FK constraint errors
    await connection.query('DELETE FROM results WHERE exam_id = ?', [examId]);
    await connection.query('DELETE FROM questions WHERE exam_id = ?', [examId]);

    // Delete the exam itself
    const [result] = await connection.query('DELETE FROM exams WHERE id = ?', [examId]);

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: 'Exam not found' });
    }

    res.status(200).json({ message: 'Exam deleted successfully' });
  } catch (err) {
    console.error('Error deleting exam:', err);
    res.status(500).json({ message: 'Error deleting exam', error: err.message });
  }
};
export const getExams = async (req, res) => {
  try {
    const [exams] = await connection.query(`
      SELECT 
        exams.id,
        exams.title
      FROM exams
    `);

    res.json(exams);
  } catch (err) {
    res.status(500).json({ message: 'Database error', error: err.message });
  }
};
export const getMajors = async (req, res) => {
  try {
    const [majors] = await connection.query('SELECT id, name FROM majors');
    res.status(200).json(majors);
  } catch (error) {
    res.status(500).json({ message: 'Error fetching majors', error: error.message });
  }
};
