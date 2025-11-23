import cron from 'node-cron';
import { checkExpiringVouchers } from '../controllers/voucher.controller.js';

export const startScheduler = () => {
  console.log('\n🕐 ========== STARTING SCHEDULER ==========');

  // Check vouchers sắp hết hạn - 9:00 AM hàng ngày
  cron.schedule('0 9 * * *', async () => {
    console.log('\n⏰ Running: Check expiring vouchers');
    await checkExpiringVouchers();
  });
  console.log('✅ Scheduled: Check expiring vouchers (daily 9:00 AM)');

  // Tự động disable expired vouchers - mỗi giờ
  cron.schedule('0 * * * *', async () => {
    console.log('\n⏰ Running: Disable expired vouchers');
    await disableExpiredVouchers();
  });
  console.log('✅ Scheduled: Disable expired vouchers (hourly)');

  console.log('🕐 ========== SCHEDULER STARTED ==========\n');
};

const disableExpiredVouchers = async () => {
  try {
    const Voucher = (await import('../models/Voucher.js')).default;
    
    const result = await Voucher.updateMany(
      {
        active: true,
        expiredAt: { $lt: new Date() },
      },
      { active: false }
    );

    if (result.modifiedCount > 0) {
      console.log(`  ✅ Disabled ${result.modifiedCount} expired vouchers`);
    }
  } catch (err) {
    console.error('❌ Disable expired vouchers error:', err);
  }
};