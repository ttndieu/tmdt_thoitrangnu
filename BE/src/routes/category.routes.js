import express from "express";
import {
  getAllCategories,
  createCategory,
  updateCategory,
  deleteCategory,
} from "../controllers/category.controller.js";

import { verifyToken } from "../middlewares/auth.middleware.js";
import { requireRole } from "../middlewares/role.middleware.js";

const router = express.Router();

router.get("/", getAllCategories);

router.post("/", verifyToken, requireRole("admin"), createCategory);

router.put("/:id", verifyToken, requireRole("admin"), updateCategory);

router.delete("/:id", verifyToken, requireRole("admin"), deleteCategory);

export default router;
