import express from "express";
import {
  getWishlist,
  addWishlist,
  removeWishlist
} from "../controllers/wishlist.controller.js";

import { verifyToken } from "../middlewares/auth.middleware.js";

const router = express.Router();

router.get("/", verifyToken, getWishlist);
router.post("/:productId", verifyToken, addWishlist);
router.delete("/:productId", verifyToken, removeWishlist);

export default router;
