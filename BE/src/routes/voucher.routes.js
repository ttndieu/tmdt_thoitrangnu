import express from "express";
import {
  createVoucher,
  getAllVouchers,
  applyVoucher,
  updateVoucher,
  deleteVoucher
} from "../controllers/voucher.controller.js";

import { verifyToken } from "../middlewares/auth.middleware.js";
import { requireRole } from "../middlewares/role.middleware.js";

const router = express.Router();

// Public - Danh sách voucher
router.get("/", verifyToken, getAllVouchers);

// User apply mã
router.post("/apply", verifyToken, applyVoucher);

// Admin
router.post("/", verifyToken, requireRole("admin"), createVoucher);
// router.get("/", verifyToken, requireRole("admin"), getAllVouchers);
router.put("/:id", verifyToken, requireRole("admin"), updateVoucher);
router.delete("/:id", verifyToken, requireRole("admin"), deleteVoucher);

export default router;
