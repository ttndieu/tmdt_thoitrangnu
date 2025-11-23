// be/src/controllers/notification.controller.js

import Notification from "../models/Notification.js";

// ======================================================
// LẤY DANH SÁCH THÔNG BÁO (CẢ USER + BROADCAST)
// GET /api/notifications
// ======================================================
export const getNotifications = async (req, res) => {
  try {
    const userId = req.user._id;
    const userIdStr = userId.toString(); // ✅ Convert to string
    const { limit = 50 } = req.query;

    console.log(`📡 Get notifications for user: ${userIdStr}`);

    // Lấy thông báo
    const notifications = await Notification.find({
      $or: [
        { audience: "user", user: userId },
        { audience: "all" }
      ]
    })
      .sort({ createdAt: -1 })
      .limit(parseInt(limit));

    console.log(`📊 Found ${notifications.length} notifications`);

    // ✅ FIX: Compute isRead cho mỗi notification
    const notificationsWithReadStatus = notifications.map(noti => {
      const obj = noti.toObject();
      
      // Nếu là broadcast → check userId STRING trong isReadBy
      if (obj.audience === "all") {
        obj.isRead = obj.isReadBy?.includes(userIdStr) || false;
      }
      // Nếu là personal → dùng isRead có sẵn
      
      return obj;
    });

    // ✅ Đếm unread từ list đã computed (chính xác hơn)
    const unreadCount = notificationsWithReadStatus.filter(n => !n.isRead).length;
    console.log(`🔔 Unread count: ${unreadCount}`);

    return res.json({
      success: true,
      notifications: notificationsWithReadStatus,
      unreadCount: unreadCount,
    });

  } catch (err) {
    console.error('❌ Get notifications error:', err);
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
    const userIdStr = userId.toString(); // ✅ CONVERT SANG STRING
    const id = req.params.id;

    console.log(`\n📝 ========== MARK AS READ ==========`);
    console.log(`📝 Notification ID: ${id}`);
    console.log(`📝 User ID: ${userIdStr}`);

    const noti = await Notification.findById(id);
    if (!noti) {
      console.log(`❌ Notification not found`);
      return res.status(404).json({ message: "Notification not found" });
    }

    // Nếu là broadcast → thêm user vào isReadBy
    if (noti.audience === "all") {
      console.log(`  Type: Broadcast notification`);
      console.log(`  isReadBy BEFORE: [${noti.isReadBy.join(', ')}]`);
      
      // ✅ CHECK VÀ PUSH STRING
      if (!noti.isReadBy.includes(userIdStr)) {
        noti.isReadBy.push(userIdStr);
        await noti.save();
        console.log(`  ✅ Added user to isReadBy`);
        console.log(`  isReadBy AFTER: [${noti.isReadBy.join(', ')}]`);
      } else {
        console.log(`  ℹ️ User already in isReadBy`);
      }
    } else {
      // Nếu là riêng → đánh dấu isRead = true
      console.log(`  Type: Personal notification`);
      
      if (noti.user.toString() !== userIdStr) {
        console.log(`  ❌ Not allowed (wrong user)`);
        return res.status(403).json({ message: "Not allowed" });
      }

      console.log(`  isRead BEFORE: ${noti.isRead}`);
      noti.isRead = true;
      await noti.save();
      console.log(`  ✅ Set isRead = true`);
    }

    console.log(`📝 ========== MARK AS READ END ==========\n`);
    return res.json({ success: true });

  } catch (err) {
    console.error('❌ Mark as read error:', err);
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
    const userIdStr = userId.toString(); // ✅ CONVERT SANG STRING

    console.log(`\n📝 ========== MARK ALL AS READ ==========`);
    console.log(`📝 User ID: ${userIdStr}`);

    // Đánh dấu personal notifications
    const personalResult = await Notification.updateMany(
      { audience: "user", user: userId, isRead: false },
      { isRead: true }
    );
    console.log(`  ✅ Updated ${personalResult.modifiedCount} personal notifications`);

    // ✅ Broadcast: thêm user STRING vào isReadBy list
    const broadcastResult = await Notification.updateMany(
      {
        audience: "all",
        isReadBy: { $ne: userIdStr } // ✅ CHECK STRING
      },
      {
        $push: { isReadBy: userIdStr } // ✅ PUSH STRING
      }
    );
    console.log(`  ✅ Updated ${broadcastResult.modifiedCount} broadcast notifications`);
    console.log(`📝 ========== MARK ALL AS READ END ==========\n`);

    return res.json({ success: true });

  } catch (err) {
    console.error('❌ Mark all as read error:', err);
    return res.status(500).json({ message: err.message });
  }
};


// ======================================================
// XÓA 1 THÔNG BÁO RIÊNG
// DELETE /api/notifications/:id
// ======================================================
export const deleteNotification = async (req, res) => {
  try {
    const userId = req.user._id;

    const noti = await Notification.findOne({
      _id: req.params.id,
      audience: "user",
      user: userId
    });

    if (!noti) {
      return res.status(404).json({ 
        message: "Notification not found or cannot delete broadcast" 
      });
    }

    await noti.deleteOne();
    console.log(`🗑️ Deleted notification: ${req.params.id}`);

    return res.json({ success: true });

  } catch (err) {
    console.error('❌ Delete notification error:', err);
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
    const userIdStr = userId.toString(); // ✅ Convert to string

    const unreadPersonal = await Notification.countDocuments({
      audience: "user",
      user: userId,
      isRead: false,
    });

    // ✅ Check STRING
    const unreadBroadcast = await Notification.countDocuments({
      audience: "all",
      isReadBy: { $ne: userIdStr }
    });

    const count = unreadPersonal + unreadBroadcast;
    console.log(`🔔 Unread count: ${count} (personal: ${unreadPersonal}, broadcast: ${unreadBroadcast})`);

    return res.json({
      success: true,
      count: count,
    });

  } catch (err) {
    console.error('❌ Get unread count error:', err);
    return res.status(500).json({ message: err.message });
  }
};