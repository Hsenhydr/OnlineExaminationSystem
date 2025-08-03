import express from 'express';
import { getResultsById, getStudentAvailableExams, getStudentProfile,getExamWithQuestions,submitExam } from '../controllers/studentController.js';

const router = express.Router();

router.get('/:id/getProfile',getStudentProfile)
router.get('/:id/getResults',getResultsById)
router.get('/:id/getExams',getStudentAvailableExams)
router.get('/getExam/:id', getExamWithQuestions);
router.post('/submit-exam',submitExam)

export default router;