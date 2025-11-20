import express from "express";
import {
  createOrder,
  getMyOrders,
  getAllOrders,
  updateOrderStatus,
} from "../controllers/order.controller.js";

import { verifyToken } from "../middlewares/auth.middleware.js";
import { requireRole } from "../middlewares/role.middleware.js";

const router = express.Router();

// User
router.post("/", verifyToken, createOrder);
router.get("/", verifyToken, getMyOrders);

// Admin
router.get("/admin/all", verifyToken, requireRole("admin"), getAllOrders);
router.put("/:id/status", verifyToken, requireRole("admin"), updateOrderStatus);

export default router;
