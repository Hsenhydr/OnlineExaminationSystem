import express from 'express';
import { createExamWithQuestions, deleteExam,getExams,getMajors } from '../controllers/instructorController.js';
const router = express.Router();

router.post('/create-exam',createExamWithQuestions)
router.delete('/delete-exam/:id',deleteExam)
router.get('/getexams',getExams)
router.get('/getmajors',getMajors)


export default router;