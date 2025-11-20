import mongoose from "mongoose";

const voucherSchema = mongoose.Schema({
  code: { type: String, required: true, unique: true }, // mã: SALE50
  discountPercent: { type: Number, default: 0 }, // % giảm
  maxDiscount: { type: Number, default: 0 }, // giảm tối đa
  minOrderValue: { type: Number, default: 0 }, // đơn tối thiểu
  quantity: { type: Number, default: 9999 }, // số lượng còn lại
  expiredAt: { type: Date, required: true }, // ngày hết hạn
  active: { type: Boolean, default: true }, // có đang bật không?
}, { timestamps: true });

export default mongoose.model("Voucher", voucherSchema);
