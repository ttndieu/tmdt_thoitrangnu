import express from "express";
import { verifyToken } from "../middlewares/auth.middleware.js";
import {
  getProfile,
  updateProfile,
  changePassword,
  addAddress,
  deleteAddress,
} from "../controllers/user.controller.js";

const router = express.Router();

router.get("/me", verifyToken, getProfile);
router.put("/update", verifyToken, updateProfile);
router.put("/change-password", verifyToken, changePassword);
router.post("/address", verifyToken, addAddress);
router.delete("/address/:addressId", verifyToken, deleteAddress);

export default router;
