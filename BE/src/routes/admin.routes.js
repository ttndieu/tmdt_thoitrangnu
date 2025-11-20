import express from "express";
import { verifyToken } from "../middlewares/auth.middleware.js";
import { requireRole } from "../middlewares/role.middleware.js";

import {
  getDashboardStats,
  getTopProducts,
  getRevenueByMonth
} from "../controllers/admin.controller.js";

const router = express.Router();

// Tổng quan dashboard
router.get("/stats", verifyToken, requireRole("admin"), getDashboardStats);

// Top 10 sản phẩm bán chạy
router.get("/top-products", verifyToken, requireRole("admin"), getTopProducts);

// Doanh thu theo tháng
router.get("/revenue/month", verifyToken, requireRole("admin"), getRevenueByMonth);

export default router;
