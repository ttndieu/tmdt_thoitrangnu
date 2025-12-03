// BE/src/models/Order.js

import mongoose from "mongoose";

const orderItemSchema = mongoose.Schema({
  product: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "Product",
  },
  quantity: Number,
  price: Number,
  size: String,
  color: String,
});

const orderSchema = mongoose.Schema(
  {
    // ORDER NUMBER - SHORT FORMAT: #abc123
    orderNumber: {
      type: String,
      unique: true,
    },

    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
    },

    items: [orderItemSchema],

    // VOUCHER FIELDS
    voucher: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Voucher",
      default: null,
    },
    voucherCode: { 
      type: String, 
      default: null 
    },
    discount: { 
      type: Number, 
      default: 0 
    },
    originalAmount: Number,
    totalAmount: Number,

    paymentMethod: {
      type: String,
      enum: ["cod", "vnpay"],
      default: "cod",
    },

    status: {
      type: String,
      enum: ["pending", "confirmed", "shipping", "completed", "cancelled"],
      default: "pending",
    },

    paymentStatus: {
      type: String,
      enum: ["pending", "paid", "failed", "refunded"],
      default: "pending",
    },

    shippingAddress: Object,

    trackingNumber: {
      type: String,
      default: null,
    },

    notes: {
      type: String,
      default: null,
    },
  },
  { 
    timestamps: true,
    toJSON: { virtuals: true },
    toObject: { virtuals: true }
  }
);

// PRE-SAVE HOOK: GENERATE SHORT ORDER NUMBER
orderSchema.pre('save', async function(next) {
  if (this.isNew && !this.orderNumber) {
    try {
      // Use last 6 chars of ObjectId + # prefix
      // Simpler and unique
      const shortId = this._id.toString().slice(-6).toUpperCase();
      this.orderNumber = `#${shortId}`;

    } catch (error) {
      console.error('Error generating order number:', error);
      // Fallback
      this.orderNumber = `#${Date.now().toString(36).slice(-6).toUpperCase()}`;
    }
  }
  next();
});

// INDEXES
orderSchema.index({ user: 1, createdAt: -1 });
orderSchema.index({ orderNumber: 1 });
orderSchema.index({ status: 1 });
orderSchema.index({ paymentStatus: 1 });

export default mongoose.model("Order", orderSchema);