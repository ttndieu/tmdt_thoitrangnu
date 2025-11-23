import Voucher from "../models/Voucher.js";
import { notifyAllUsers } from "../services/notification.service.js";

// ------------------------------
// Tạo voucher
// ------------------------------
export const createVoucher = async (req, res) => {
  try {
    const voucher = await Voucher.create(req.body);

    await notifyAllUsers(
      "voucher",
      "🎉 Voucher mới!",
      `Mã ${voucher.code} giảm đến ${voucher.maxDiscount.toLocaleString()}đ đã nằm trong ví. Số lượng có hạn, dùng ngay kẻo hết!`,
      { voucherId: voucher._id.toString() }
    );

    res.status(201).json({ voucher });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// ------------------------------
// Danh sách voucher
// ------------------------------
export const getAllVouchers = async (req, res) => {
  try {
    const vouchers = await Voucher.find();
    res.json({ vouchers });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// ------------------------------
// User apply Khi Checkout
// ------------------------------
export const applyVoucher = async (req, res) => {
  try {
    const { code, totalAmount } = req.body;

    const voucher = await Voucher.findOne({ code });
    if (!voucher)
      return res.status(404).json({ message: "Mã giảm giá không tồn tại" });

    if (!voucher.active)
      return res.status(400).json({ message: "Mã giảm giá đã bị khóa" });

    if (voucher.expiredAt < new Date())
      return res.status(400).json({ message: "Mã giảm giá đã hết hạn" });

    if (totalAmount < voucher.minOrderValue)
      return res.status(400).json({
        message: `Đơn hàng phải từ ${voucher.minOrderValue}đ mới dùng được mã`
      });

    if (voucher.quantity <= 0)
      return res.status(400).json({ message: "Mã đã hết lượt dùng" });

    const discount = Math.min(
      (totalAmount * voucher.discountPercent) / 100,
      voucher.maxDiscount
    );

    res.json({
      success: true,
      discount,
      finalPrice: totalAmount - discount
    });

  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// ------------------------------
// Cập nhật voucher
// ------------------------------
export const updateVoucher = async (req, res) => {
  try {
    const updated = await Voucher.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true }
    );

    await notifyAllUsers(
      "voucher",
      "✨ Voucher đã cập nhật!",
      `Mã ${updated.code} giảm đến ${updated.maxDiscount.toLocaleString()}đ đã được điều chỉnh.`,
      { voucherId: updated._id.toString() }
    );

    res.json({ voucher: updated });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// ------------------------------
// Xóa voucher
// ------------------------------
export const deleteVoucher = async (req, res) => {
  try {
    await Voucher.findByIdAndDelete(req.params.id);
    res.json({ message: "Voucher deleted" });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};
