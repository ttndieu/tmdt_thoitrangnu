import mongoose from "mongoose";

const paymentSchema = mongoose.Schema(
  {
    order: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Order",
      required: true,
    },
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    amount: {
      type: Number,
      required: true,
    },
    method: {
      type: String,
      enum: ["cod", "vnpay"],
      default: "cod",
    },
    status: {
      type: String,
      enum: ["pending", "success", "failed", "cancelled"],
      default: "pending",
    },
    // VNPay specific fields
    transactionId: String, // vnp_TxnRef
    vnpTransactionNo: String, // vnp_TransactionNo
    bankCode: String,
    cardType: String,
    responseCode: String,
    vnpayData: Object, // Lưu toàn bộ response
  },
  { timestamps: true }
);

export default mongoose.model("Payment", paymentSchema);