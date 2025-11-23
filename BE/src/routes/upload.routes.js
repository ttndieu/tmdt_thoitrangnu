import express from "express";
import { upload } from "../middlewares/upload.middleware.js";
import {
  uploadImage,
  deleteImage,
  replaceImage,
  listImagesByFolder
} from "../controllers/upload.controller.js";

import { verifyToken } from "../middlewares/auth.middleware.js";
import { requireRole } from "../middlewares/role.middleware.js";
import { uploadAvatar } from "../controllers/upload.controller.js";


const router = express.Router();

// Upload avatar người dùng
router.post(
  "/avatar",
  verifyToken, // CHỈ CẦN LOGIN
  upload.single("avatar"),
  uploadAvatar
);

// Upload mới
router.post(
  "/",
  verifyToken,
  requireRole("admin"),
  upload.single("image"),
  uploadImage
);

// Xoá ảnh theo public_id
router.delete(
  "/:public_id",
  verifyToken,
  requireRole("admin"),
  deleteImage
);

// Thay ảnh mới
router.put(
  "/replace",
  verifyToken,
  requireRole("admin"),
  upload.single("image"),
  replaceImage
);

// List ảnh theo folder
router.get(
  "/list",
  verifyToken,
  requireRole("admin"),
  listImagesByFolder
);

export default router;
