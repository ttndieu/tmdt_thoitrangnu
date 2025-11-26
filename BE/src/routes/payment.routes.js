// BE/src/routes/payment.routes.js

import express from "express";
import PaymentController from "../controllers/payment.controller.js";
import { verifyToken } from "../middlewares/auth.middleware.js";

const router = express.Router();

// ✅ CREATE VNPAY PAYMENT
router.post(
  "/vnpay/create",
  verifyToken,
  PaymentController.createVNPayPayment
);

// ✅ VNPAY CALLBACK
router.get("/vnpay/callback", PaymentController.vnpayCallback);

// ✅ VNPAY IPN
router.get("/vnpay/ipn", PaymentController.vnpayIPN);

export default router;