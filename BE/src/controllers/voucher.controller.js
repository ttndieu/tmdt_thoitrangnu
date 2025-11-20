import Voucher from "../models/Voucher.js";

// Admin tạo mã
export const createVoucher = async (req, res) => {
  try {
    const voucher = await Voucher.create(req.body);
    return res.status(201).json({ voucher });
  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
};
// lấy danh sách voucher
export const getAllVouchers = async (req, res) => {
  try {
    const vouchers = await Voucher.find();
    return res.json({ vouchers });
  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
};

//User áp dụng voucher (checkout)
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

    // Tính giảm giá
    const discount = Math.min(
      (totalAmount * voucher.discountPercent) / 100,
      voucher.maxDiscount
    );

    const finalPrice = totalAmount - discount;

    return res.json({
      success: true,
      discount,
      finalPrice
    });

  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
};

//update voucher
export const updateVoucher = async (req, res) => {
  try {
    const updated = await Voucher.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true }
    );

    return res.json({ voucher: updated });
  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
};


//xóa voucher
export const deleteVoucher = async (req, res) => {
  try {
    await Voucher.findByIdAndDelete(req.params.id);
    return res.json({ message: "Voucher deleted" });
  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
};
