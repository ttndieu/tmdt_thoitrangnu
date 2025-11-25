import express from "express";
import { verifyToken } from "../middlewares/auth.middleware.js";
import { requireRole } from "../middlewares/role.middleware.js";

import User from "../models/User.js";

const router = express.Router();

/**
 * GET /api/admin/users
 * Lấy danh sách user
 */
router.get("/users", verifyToken, requireRole("admin"), async (req, res) => {
    const users = await User.find().select("-password");
    return res.json({ users });
});

/**
 * GET /api/admin/users/:id
 * Lấy chi tiết user
 */
router.get("/users/:id", verifyToken, requireRole("admin"), async (req, res) => {
    const user = await User.findById(req.params.id).select("-password");
    if (!user) return res.status(404).json({ message: "Không tìm thấy user" });
    res.json({ user });
});

/**
 * PUT /api/admin/users/:id
 * Cập nhật user (tên, phone, role)
 */
router.put("/users/:id", verifyToken, requireRole("admin"), async (req, res) => {
    const user = await User.findByIdAndUpdate(req.params.id, req.body, { new: true })
        .select("-password");
    res.json({ user });
});

/**
 * POST /api/admin/users
 */
router.post("/users", verifyToken, requireRole("admin"), async (req, res) => {
    const user = await User.create(req.body);
    res.json({ user });
});
/**
 * delete /api/admin/users
 */
router.delete("/users/:id", verifyToken, requireRole("admin"), async (req, res) => {
    try {
        const user = await User.findById(req.params.id);

        if (!user) return res.status(404).json({ message: "User not found" });
        if (user.role === "admin") {
            return res.status(400).json({ message: "Không thể xoá admin" });
        }

        await User.findByIdAndDelete(req.params.id);
        return res.json({ message: "Đã xoá người dùng" });

    } catch (err) {
        return res.status(500).json({ message: err.message });
    }
});



export default router;
