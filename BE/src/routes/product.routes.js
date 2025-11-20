import express from "express";
import {
  getAllProducts,
  getProductById,
  createProduct,
  updateProduct,
  deleteProduct
} from "../controllers/product.controller.js";

import { verifyToken } from "../middlewares/auth.middleware.js";
import { requireRole } from "../middlewares/role.middleware.js";

const router = express.Router();

// Public
router.get("/", getAllProducts);
router.get("/:id", getProductById);

// Admin
router.post("/", verifyToken, requireRole("admin"), createProduct);
router.put("/:id", verifyToken, requireRole("admin"), updateProduct);
router.delete("/:id", verifyToken, requireRole("admin"), deleteProduct);

export default router;
