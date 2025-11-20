import mongoose from "mongoose";

const addressSchema = mongoose.Schema({
  fullName: String,
  phone: String,
  addressLine: String,
  ward: String,
  district: String,
  city: String,
  isDefault: { type: Boolean, default: false },
});

const userSchema = mongoose.Schema(
  {
    name: { type: String, required: true },

    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
    },

    password: {
      type: String,
      required: true,
    },

    role: {
      type: String,
      enum: ["user", "admin"],
      default: "user",
    },

    phone: {
      type: String,
    },

    avatar: { type: String },

    // wishlist trong schema user
    wishlist: [
      { type: mongoose.Schema.Types.ObjectId, ref: "Product" }
    ],

    addresses: [addressSchema],
  },
  { timestamps: true }
);

export default mongoose.model("User", userSchema);
