import express from "express";
import {
  getCart,
  addToCart,
  updateCart,
  removeItem,
  clearCart,
} from "../controllers/cart.controller.js";

import { verifyToken } from "../middlewares/auth.middleware.js";

const router = express.Router();

router.get("/", verifyToken, getCart);
router.post("/", verifyToken, addToCart);
router.put("/", verifyToken, updateCart);
router.delete("/item", verifyToken, removeItem);
router.delete("/clear", verifyToken, clearCart);

export default router;
