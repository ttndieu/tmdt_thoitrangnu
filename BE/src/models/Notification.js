import mongoose from "mongoose";

const notificationSchema = new mongoose.Schema({
  // user null => broadcast
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
    default: null,
  },

  audience: {
    type: String,
    enum: ["user", "all"],
    default: "user",
  },

  type: {
    type: String,
    enum: ["order", "promotion", "product", "system", "voucher"],
    required: true,
  },

  title: { type: String, required: true },
  message: { type: String, required: true },

  data: {
    type: Map,
    of: mongoose.Schema.Types.Mixed,
    default: {},
  },

  isRead: { type: Boolean, default: false },

  // user nào đã đọc broadcast
  isReadBy: [{ type: String }],

  createdAt: { type: Date, default: Date.now },
});

// Index hiệu năng
notificationSchema.index({ audience: 1, createdAt: -1 });

export default mongoose.model("Notification", notificationSchema);
