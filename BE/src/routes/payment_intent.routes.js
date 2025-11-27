// BE/src/routes/payment_intent.routes.js

import express from "express";
import PaymentIntentController from "../controllers/payment_intent.controller.js";
import { verifyToken } from "../middlewares/auth.middleware.js";

const router = express.Router();

router.post("/create", verifyToken, PaymentIntentController.createIntent);
router.get("/:id", verifyToken, PaymentIntentController.getIntent);
router.put("/:id/cancel", verifyToken, PaymentIntentController.cancelIntent);

export default router;