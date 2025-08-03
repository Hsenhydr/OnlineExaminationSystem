import connection from "../db.js";

export const getStudentProfile = async (req, res) => {
  try {
    const studentId = req.params.id;

    const [userRows] = await connection.query(
      'SELECT id FROM users WHERE id = ? AND role = "student"',
      [studentId]
    );
    if (userRows.length === 0) {
      return res.status(404).json({ message: 'Student not found or invalid role' });
    }
    const [rows] =await connection.query('SELECT id, name, email FROM users WHERE id = ?', [studentId]);
    res.json(rows[0]);
  } catch (err) {
    res.status(500).json({ message: 'Database error', error: err.message });
  }
};
export const getStudentAvailableExams = async (req, res) => {
  try {
    const studentId = req.params.id;

    const [studentRows] = await connection.query(
      'SELECT major_id FROM users WHERE id = ? AND role = "student"', 
      [studentId]
    );

    if (studentRows.length === 0) {
      return res.status(404).json({ message: 'Student not found or not a student' });
    }

    const majorId = studentRows[0].major_id;

    if (!majorId) {
      return res.status(400).json({ message: 'Student major is not assigned' });
    }

    const [examRows] = await connection.query(
      'SELECT id, title, duration FROM exams WHERE major_id = ?',
      [majorId]
    );
    res.json(examRows);
  } catch (err) {
    res.status(500).json({ message: 'Database error', error: err.message });
  }
};
export const getResultsById = async (req, res) => {
  try {
    const studentId = req.params.id;
    const [rows] = await connection.query(
      `SELECT 
         exams.title AS exam_title,
         exams.duration,
         majors.name AS major,
         results.score,
         results.taken_at
       FROM results
       JOIN exams ON results.exam_id = exams.id
       JOIN majors ON exams.major_id = majors.id
       WHERE results.student_id = ?`,
      [studentId]
    );
    res.json(rows);
  } catch (err) {
    res.status(500).json({ message: 'Database error', error: err.message });
  }
};
export const getExamWithQuestions = async (req, res) => {
  const examId = req.params.id;
  try {
    // Fetch the exam details
    const [examRows] = await connection.query(
      `SELECT exams.id, exams.title, exams.duration, majors.name AS major
       FROM exams
       JOIN majors ON exams.major_id = majors.id
       WHERE exams.id = ?`,
      [examId]
    );

    if (examRows.length === 0) {
      return res.status(404).json({ message: "Exam not found" });
    }

    const exam = examRows[0];

    // Fetch related questions
    const [questions] = await connection.query(
      `SELECT id, question_text, choice_a, choice_b, choice_c, choice_d, correct_answer
       FROM questions
       WHERE exam_id = ?`,
      [examId]
    );

    res.json({
      exam,
      questions
    });
  } catch (err) {
    res.status(500).json({ message: "Database error", error: err.message });
  }
};
export const submitExam = async (req, res) => {
  try {
    const { studentId, examId, answers } = req.body;

    // Check if user is a student
    const [userRows] = await connection.query(
      "SELECT role FROM users WHERE id = ?",
      [studentId]
    );

    if (userRows.length === 0 || userRows[0].role !== "student") {
      return res.status(403).json({ message: "Only students can submit exams." });
    }

    // Get all questions for the exam
    const [questionRows] = await connection.query(
      "SELECT id, correct_answer FROM questions WHERE exam_id = ?",
      [examId]
    );

    if (questionRows.length === 0) {
      return res.status(404).json({ message: "Exam not found or has no questions." });
    }

    // Step 3: Calculate score
    let correctAnswers = 0;
    questionRows.forEach((question) => {
      const studentAnswer = answers[question.id];
      if (studentAnswer && studentAnswer === question.correct_answer) {
        correctAnswers++;
      }
    });

    const totalQuestions = questionRows.length;
    const score = Math.round((correctAnswers / totalQuestions) * 100); // Score out of 100

    // Step 4: Save result in DB
    await connection.query(
      "INSERT INTO results (student_id, exam_id, score) VALUES (?, ?, ?)",
      [studentId, examId, score]
    );

    res.json({
      message: "Exam submitted successfully",
      totalQuestions,
      correctAnswers,
      score, 
    });
  } catch (err) {
    console.error("Submit exam error:", err);
    res.status(500).json({ message: "Database error", error: err.message });
  }
};

