import express from "express";
import {
  createReview,
  getReviewsByProduct,
  getMyReviews,
  updateReview,
  deleteReview,
  checkCanReview,
} from "../controllers/review.controller.js";
import { verifyToken } from "../middlewares/auth.middleware.js";

const router = express.Router();

// Lấy đánh giá của 1 sản phẩm
router.get("/product/:productId", getReviewsByProduct);

// CRUD Đánh giá (USER)
router.post("/", verifyToken, createReview);
router.get("/my-reviews", verifyToken, getMyReviews);
router.get("/can-review/:productId", verifyToken, checkCanReview);
router.put("/:reviewId", verifyToken, updateReview);
router.delete("/:reviewId", verifyToken, deleteReview);

export default router;