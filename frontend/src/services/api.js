import axios from 'axios';

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:3000';

const api = axios.create({
  baseURL: `${API_URL}/api`,
  headers: {
    'Content-Type': 'application/json',
  },
});

export const createQuiz = async (payload) => {
  const response = await api.post('/quizzes', payload);
  return response.data;
};

export const getQuiz = async (quizId) => {
  const response = await api.get(`/quizzes/${quizId}`);
  return response.data;
};

export const regenerateQuestion = async (quizId, scope, questionId, notes) => {
  const response = await api.post(`/quizzes/${quizId}/regenerate`, {
    scope,
    question_id: questionId,
    notes,
  });
  return response.data;
};

export default {
  createQuiz,
  getQuiz,
  regenerateQuestion,
};
