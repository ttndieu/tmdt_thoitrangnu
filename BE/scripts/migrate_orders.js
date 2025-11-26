// BE/scripts/migrate_orders.js

import mongoose from 'mongoose';
import Order from '../src/models/Order.js';
import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

dotenv.config({ path: path.resolve(__dirname, '../.env') });

async function migrateOrders() {
  try {
    console.log('\n📦 ========== ORDER MIGRATION ==========\n');
    
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB');
    console.log('🔍 Database:', mongoose.connection.name);
    console.log('');

    const orders = await Order.find({ 
      orderNumber: { $exists: false } 
    }).sort({ createdAt: 1 });
    
    console.log(`📋 Found ${orders.length} orders without orderNumber\n`);

    if (orders.length === 0) {
      console.log('✅ All orders already have orderNumber');
      console.log('📦 ========== MIGRATION COMPLETE ==========\n');
      process.exit(0);
    }

    let updated = 0;

    for (let order of orders) {
      try {
        // ✅ GENERATE SHORT ORDER NUMBER: #ABC123
        const shortId = order._id.toString().slice(-6).toUpperCase();
        order.orderNumber = `#${shortId}`;
        
        // Add paymentStatus if missing
        if (!order.paymentStatus) {
          order.paymentStatus = order.status === 'completed' || order.status === 'confirmed' 
            ? 'paid' 
            : 'pending';
        }
        
        await order.save();
        updated++;
        
        console.log(`✅ [${updated}/${orders.length}] Updated order ${order._id}`);
        console.log(`   → Order number: ${order.orderNumber}`);
        console.log(`   → Payment status: ${order.paymentStatus}`);
        console.log('');
      } catch (err) {
        console.error(`❌ Error updating order ${order._id}:`, err.message);
        console.log('');
      }
    }

    console.log(`\n✅ Migration completed: ${updated}/${orders.length} orders updated`);
    console.log('📦 ========== MIGRATION COMPLETE ==========\n');
    
    process.exit(0);
  } catch (error) {
    console.error('\n❌ Migration error:', error);
    console.error('Stack:', error.stack);
    console.log('');
    process.exit(1);
  }
}

migrateOrders();