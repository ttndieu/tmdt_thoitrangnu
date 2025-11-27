// BE/src/models/PaymentIntent.js

import mongoose from "mongoose";

const intentItemSchema = mongoose.Schema({
  product: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "Product",
    required: true,
  },
  quantity: { type: Number, required: true },
  price: { type: Number, required: true },
  size: { type: String, required: true },
  color: { type: String, required: true },
});

const paymentIntentSchema = mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    
    items: [intentItemSchema],
    
    // Voucher
    voucher: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Voucher",
      default: null,
    },
    voucherCode: { type: String, default: null },
    discount: { type: Number, default: 0 },
    
    // Shipping fee
    shippingFee: { 
      type: Number, 
      default: 15000  // VND
    },
    
    // Amounts
    originalAmount: { type: Number, required: true },
    totalAmount: { type: Number, required: true },
    
    // Payment
    paymentMethod: {
      type: String,
      enum: ["cod", "vnpay"],
      required: true,
    },
    
    paymentStatus: {
      type: String,
      enum: ["pending", "paid", "failed", "cancelled"],
      default: "pending",
    },
    
    // Shipping
    shippingAddress: {
      type: Object,
      required: true,
    },
    
    // VNPay data
    transactionId: String,
    vnpTransactionNo: String,
    bankCode: String,
    cardType: String,
    responseCode: String,
    vnpayData: Object,
    
    // Link to order
    order: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Order",
      default: null,
    },
    
    // Expiry
    expiresAt: {
      type: Date,
      default: () => new Date(Date.now() + 30 * 60 * 1000),
      index: { expires: 0 },
    },
  },
  { timestamps: true }
);

paymentIntentSchema.index({ user: 1, paymentStatus: 1 });
paymentIntentSchema.index({ transactionId: 1 });

export default mongoose.model("PaymentIntent", paymentIntentSchema);