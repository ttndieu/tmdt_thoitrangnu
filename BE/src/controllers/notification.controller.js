// be/src/controllers/notification.controller.js

import Notification from "../models/Notification.js";

// ======================================================
// LẤY DANH SÁCH THÔNG BÁO (CẢ USER + BROADCAST)
// GET /api/notifications
// ======================================================
export const getNotifications = async (req, res) => {
  try {
    const userId = req.user._id;
    const { limit = 50 } = req.query;

    // Lấy thông báo:
    // - Riêng của user
    // - Broadcast chung cho tất cả
    const notifications = await Notification.find({
      $or: [
        { audience: "user", user: userId },
        { audience: "all" }
      ]
    })
      .sort({ createdAt: -1 })
      .limit(parseInt(limit));

    // Tính số chưa đọc
    const unreadPersonal = await Notification.countDocuments({
      audience: "user",
      user: userId,
      isRead: false,
    });

    const unreadBroadcast = await Notification.countDocuments({
      audience: "all",
      isReadBy: { $ne: userId }
    });

    return res.json({
      success: true,
      notifications,
      unreadCount: unreadPersonal + unreadBroadcast,
    });

  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
};


// ======================================================
// ĐÁNH DẤU 1 THÔNG BÁO LÀ ĐÃ ĐỌC
// PUT /api/notifications/:id/read
// ======================================================
export const markAsRead = async (req, res) => {
  try {
    const userId = req.user._id;
    const id = req.params.id;

    const noti = await Notification.findById(id);
    if (!noti) {
      return res.status(404).json({ message: "Notification not found" });
    }

    // Nếu là broadcast → thêm user vào isReadBy
    if (noti.audience === "all") {
      if (!noti.isReadBy.includes(userId)) {
        noti.isReadBy.push(userId);
        await noti.save();
      }
    } else {
      // Nếu là riêng → đánh dấu isRead = true
      if (noti.user.toString() !== userId.toString()) {
        return res.status(403).json({ message: "Not allowed" });
      }

      noti.isRead = true;
      await noti.save();
    }

    return res.json({ success: true });

  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
};


// ======================================================
// ĐÁNH DẤU TẤT CẢ LÀ ĐÃ ĐỌC
// PUT /api/notifications/read-all
// ======================================================
export const markAllAsRead = async (req, res) => {
  try {
    const userId = req.user._id;

    // Đánh dấu riêng
    await Notification.updateMany(
      { audience: "user", user: userId, isRead: false },
      { isRead: true }
    );

    // Broadcast: thêm user vào isReadBy list
    await Notification.updateMany(
      {
        audience: "all",
        isReadBy: { $ne: userId }
      },
      {
        $push: { isReadBy: userId }
      }
    );

    return res.json({ success: true });

  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
};


// ======================================================
// XÓA 1 THÔNG BÁO RIÊNG
// DELETE /api/notifications/:id
// ======================================================
// ⚠ Broadcast không thể bị xóa — giống Facebook/Zalo
// (chỉ đánh dấu đọc)
export const deleteNotification = async (req, res) => {
  try {
    const userId = req.user._id;

    const noti = await Notification.findOne({
      _id: req.params.id,
      audience: "user",
      user: userId
    });

    if (!noti) {
      return res.status(404).json({ message: "Notification not found or cannot delete broadcast" });
    }

    await noti.deleteOne();

    return res.json({ success: true });

  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
};


// ======================================================
// ĐẾM SỐ THÔNG BÁO CHƯA ĐỌC
// GET /api/notifications/unread-count
// ======================================================
export const getUnreadCount = async (req, res) => {
  try {
    const userId = req.user._id;

    const unreadPersonal = await Notification.countDocuments({
      audience: "user",
      user: userId,
      isRead: false,
    });

    const unreadBroadcast = await Notification.countDocuments({
      audience: "all",
      isReadBy: { $ne: userId }
    });

    return res.json({
      success: true,
      count: unreadPersonal + unreadBroadcast,
    });

  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
};
