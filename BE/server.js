import dotenv from "dotenv";
dotenv.config(); // Load .env

import app from "./src/app.js";
import connectDB from "./src/config/db.js";
import { startScheduler } from "./src/utils/scheduler.js";

const PORT = process.env.PORT || 3000;

// Kết nối Mongo trước rồi mới chạy server
connectDB().then(() => {
  app.listen(PORT, () => {
    console.log(` Server running at http://localhost:${PORT}`);
    startScheduler();
  });
});
