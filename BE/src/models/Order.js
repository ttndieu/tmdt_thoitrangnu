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
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
    },

    items: [orderItemSchema],

    totalAmount: Number,

    paymentMethod: {
      type: String,
      enum: ["cod", "momo", "vnpay"],
      default: "cod",
    },

    status: {
      type: String,
      enum: ["pending", "confirmed", "shipping", "completed", "cancelled"],
      default: "pending",
    },

    shippingAddress: Object,
  },
  { timestamps: true }
);

export default mongoose.model("Order", orderSchema);
