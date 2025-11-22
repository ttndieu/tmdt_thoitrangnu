// be/src/controllers/notification.controller.js

import Notification from "../models/Notification.js";

// GET /api/notifications
export const getNotifications = async (req, res) => {
  try {
    const { type, isRead, limit = 50 } = req.query;

    const filter = { user: req.user._id };

    if (type) filter.type = type;
    if (isRead !== undefined) filter.isRead = isRead === "true";

    const notifications = await Notification.find(filter)
      .sort({ createdAt: -1 })
      .limit(parseInt(limit));

    const unreadCount = await Notification.countDocuments({
      user: req.user._id,
      isRead: false,
    });

    return res.json({
      success: true,
      notifications,
      unreadCount,
    });
  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
};

// PUT /api/notifications/:id/read
export const markAsRead = async (req, res) => {
  try {
    const notification = await Notification.findOneAndUpdate(
      { _id: req.params.id, user: req.user._id },
      { isRead: true },
      { new: true }
    );

    if (!notification) {
      return res.status(404).json({ message: "Notification not found" });
    }

    return res.json({ success: true, notification });
  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
};

// PUT /api/notifications/read-all
export const markAllAsRead = async (req, res) => {
  try {
    await Notification.updateMany(
      { user: req.user._id, isRead: false },
      { isRead: true }
    );

    return res.json({ success: true, message: "All notifications marked as read" });
  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
};

// DELETE /api/notifications/:id
export const deleteNotification = async (req, res) => {
  try {
    const notification = await Notification.findOneAndDelete({
      _id: req.params.id,
      user: req.user._id,
    });

    if (!notification) {
      return res.status(404).json({ message: "Notification not found" });
    }

    return res.json({ success: true, message: "Notification deleted" });
  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
};

// GET /api/notifications/unread-count
export const getUnreadCount = async (req, res) => {
  try {
    const count = await Notification.countDocuments({
      user: req.user._id,
      isRead: false,
    });

    return res.json({ success: true, count });
  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
};