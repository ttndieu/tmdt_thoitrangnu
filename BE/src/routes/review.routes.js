import express from "express";
import {
  createReview,
  deleteReview,
  updateReview,
  getReviewsByProduct
} from "../controllers/review.controller.js";

import { verifyToken } from "../middlewares/auth.middleware.js";

const router = express.Router();

// User viết review
router.post("/", verifyToken, createReview);

// User sửa review
router.put("/:reviewId", verifyToken, updateReview);

// User xoá review
router.delete("/:reviewId", verifyToken, deleteReview);

// Lấy review theo sản phẩm
router.get("/product/:productId", getReviewsByProduct);

export default router;
