import express from "express";
import {
  createOrder,
  getMyOrders,
  getAllOrders,
  updateOrderStatus,
  cancelOrder,
} from "../controllers/order.controller.js";

import { verifyToken } from "../middlewares/auth.middleware.js";
import { requireRole } from "../middlewares/role.middleware.js";

const router = express.Router();

// User
router.post("/", verifyToken, createOrder);
router.get("/", verifyToken, getMyOrders);
router.put("/:id/cancel", verifyToken, cancelOrder);

// Admin
router.get("/admin/all", verifyToken, requireRole("admin"), getAllOrders);
router.put("/:id/status", verifyToken, requireRole("admin"), updateOrderStatus);

export default router;
