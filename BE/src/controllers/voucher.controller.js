import Voucher from "../models/Voucher.js";
import Notification from "../models/Notification.js";

// ======================================================
// LẤY DANH SÁCH VOUCHER (PUBLIC)
// GET /api/voucher
// ======================================================
export const getAllVouchers = async (req, res) => {
  try {
    const vouchers = await Voucher.find({
      active: true,
      quantity: { $gt: 0 },
      expiredAt: { $gt: new Date() },
    }).sort({ createdAt: -1 });

    res.json({ vouchers });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// ======================================================
// APPLY VOUCHER (USER)
// POST /api/voucher/apply
// Body: { code, totalAmount }
// ======================================================
export const applyVoucher = async (req, res) => {
  try {
    const { code, totalAmount } = req.body;

    console.log(`\n🎫 ========== APPLY VOUCHER ==========`);
    console.log(`🎫 Code: ${code}`);
    console.log(`🎫 Total amount: ${totalAmount}`);

    if (!code || !totalAmount) {
      return res.status(400).json({ 
        message: "Thiếu thông tin mã giảm giá" 
      });
    }

    const voucher = await Voucher.findOne({ code: code.toUpperCase() });

    if (!voucher) {
      console.log(`❌ Voucher not found`);
      return res.status(404).json({ 
        message: "Mã giảm giá không tồn tại" 
      });
    }

    if (!voucher.active) {
      console.log(`❌ Voucher inactive`);
      return res.status(400).json({ 
        message: "Mã giảm giá đã bị khóa" 
      });
    }

    if (voucher.expiredAt < new Date()) {
      console.log(`❌ Voucher expired`);
      return res.status(400).json({ 
        message: "Mã giảm giá đã hết hạn" 
      });
    }

    if (totalAmount < voucher.minOrderValue) {
      console.log(`❌ Order too low: ${totalAmount} < ${voucher.minOrderValue}`);
      return res.status(400).json({
        message: `Đơn hàng phải từ ${voucher.minOrderValue.toLocaleString('vi-VN')}đ mới dùng được mã`
      });
    }

    if (voucher.quantity <= 0) {
      console.log(`❌ Out of stock`);
      return res.status(400).json({ 
        message: "Mã đã hết lượt dùng" 
      });
    }

    // Calculate discount
    const discount = Math.min(
      (totalAmount * voucher.discountPercent) / 100,
      voucher.maxDiscount
    );

    const finalPrice = totalAmount - discount;

    console.log(`✅ Voucher valid`);
    console.log(`💰 Discount: ${discount}`);
    console.log(`💵 Final price: ${finalPrice}`);
    console.log(`🎫 ========== APPLY VOUCHER END ==========\n`);

    res.json({
      success: true,
      voucher: {
        id: voucher._id,
        code: voucher.code,
        discountPercent: voucher.discountPercent,
        maxDiscount: voucher.maxDiscount,
      },
      discount,
      finalPrice
    });

  } catch (err) {
    console.error('❌ Apply voucher error:', err);
    res.status(500).json({ message: err.message });
  }
};

// ======================================================
// CREATE VOUCHER (ADMIN) - WITH NOTIFICATION
// POST /api/voucher
// ======================================================
export const createVoucher = async (req, res) => {
  try {
    console.log(`\n🎫 ========== CREATE VOUCHER ==========`);
    console.log(`📝 Data:`, req.body);

    // Convert code to uppercase
    if (req.body.code) {
      req.body.code = req.body.code.toUpperCase();
    }

    const voucher = await Voucher.create(req.body);
    console.log(`✅ Voucher created: ${voucher.code}`);

    // ✅ GỬI THÔNG BÁO BROADCAST
    if (voucher.active) {
      try {
        const message = `Mã ${voucher.code} giảm đến ${voucher.maxDiscount.toLocaleString('vi-VN')}đ đã nằm trong ví. Số lượng có hạn, dùng ngay kẻo hết!`;

        await Notification.create({
          user: null,
          audience: "all",
          type: "voucher",
          title: "🎉 Voucher mới!",
          message: message,
          data: {
            voucherId: voucher._id.toString(),
            code: voucher.code,
            discountPercent: voucher.discountPercent,
            maxDiscount: voucher.maxDiscount,
            minOrderValue: voucher.minOrderValue,
          },
          isRead: false,
          isReadBy: [],
        });

        console.log(`📢 Notification sent to all users`);
      } catch (notifErr) {
        console.error('⚠️ Notification error:', notifErr.message);
      }
    }

    console.log(`🎫 ========== CREATE VOUCHER END ==========\n`);
    res.status(201).json({ voucher });

  } catch (err) {
    console.error('❌ Create voucher error:', err);
    res.status(500).json({ message: err.message });
  }
};

// ======================================================
// UPDATE VOUCHER (ADMIN) - WITH NOTIFICATION
// PUT /api/voucher/:id
// ======================================================
export const updateVoucher = async (req, res) => {
  try {
    console.log(`\n🎫 ========== UPDATE VOUCHER ==========`);
    console.log(`📝 ID: ${req.params.id}`);

    const oldVoucher = await Voucher.findById(req.params.id);
    if (!oldVoucher) {
      return res.status(404).json({ message: "Voucher not found" });
    }

    if (req.body.code) {
      req.body.code = req.body.code.toUpperCase();
    }

    const updated = await Voucher.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true }
    );

    console.log(`✅ Voucher updated: ${updated.code}`);

    // ✅ NẾU KÍCH HOẠT VOUCHER → GỬI THÔNG BÁO
    if (!oldVoucher.active && updated.active) {
      try {
        const message = `Mã ${updated.code} giảm đến ${updated.maxDiscount.toLocaleString('vi-VN')}đ đã được điều chỉnh.`;

        await Notification.create({
          user: null,
          audience: "all",
          type: "voucher",
          title: "✨ Voucher đã cập nhật!",
          message: message,
          data: { voucherId: updated._id.toString() },
          isReadBy: [],
        });

        console.log(`📢 Notification sent (activated)`);
      } catch (notifErr) {
        console.error('⚠️ Notification error:', notifErr.message);
      }
    }

    console.log(`🎫 ========== UPDATE VOUCHER END ==========\n`);
    res.json({ voucher: updated });

  } catch (err) {
    console.error('❌ Update voucher error:', err);
    res.status(500).json({ message: err.message });
  }
};

// ======================================================
// DELETE VOUCHER (ADMIN)
// DELETE /api/voucher/:id
// ======================================================
export const deleteVoucher = async (req, res) => {
  try {
    const voucher = await Voucher.findByIdAndDelete(req.params.id);
    
    if (!voucher) {
      return res.status(404).json({ message: "Voucher not found" });
    }

    console.log(`🗑️ Deleted voucher: ${voucher.code}`);
    res.json({ message: "Voucher deleted" });

  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// ======================================================
// CHECK VOUCHERS SẮP HẾT HẠN (CRON JOB)
// ======================================================
export const checkExpiringVouchers = async () => {
  try {
    console.log('\n⏰ ========== CHECK EXPIRING VOUCHERS ==========');

    const now = new Date();
    const tomorrow = new Date(now.getTime() + 24 * 60 * 60 * 1000);

    const expiringVouchers = await Voucher.find({
      active: true,
      quantity: { $gt: 0 },
      expiredAt: {
        $gte: now,
        $lte: tomorrow,
      },
    });

    console.log(`📋 Found ${expiringVouchers.length} expiring vouchers`);

    for (const voucher of expiringVouchers) {
      const hoursLeft = Math.round(
        (voucher.expiredAt - now) / (1000 * 60 * 60)
      );

      try {
        await Notification.create({
          user: null,
          audience: "all",
          type: "voucher",
          title: `⏰ Mã ${voucher.code} sắp hết hạn!`,
          message: `Chỉ còn ${hoursLeft} giờ để sử dụng mã giảm ${voucher.discountPercent}%. Nhanh tay đặt hàng!`,
          data: {
            voucherId: voucher._id.toString(),
            code: voucher.code,
            hoursLeft: hoursLeft,
          },
          isReadBy: [],
        });

        console.log(`  ✅ Notified: ${voucher.code} (${hoursLeft}h left)`);
      } catch (notifErr) {
        console.error(`  ⚠️ Error: ${notifErr.message}`);
      }
    }

    console.log('⏰ ========== CHECK EXPIRING VOUCHERS END ==========\n');

  } catch (err) {
    console.error('❌ Check expiring vouchers error:', err);
  }
};