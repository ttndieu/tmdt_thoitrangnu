import nodemailer from "nodemailer";

export const sendOrderEmail = async (to, order) => {
  try {
    const transporter = nodemailer.createTransport({
      host: process.env.MAIL_HOST,
      port: process.env.MAIL_PORT,
      secure: false,
      auth: {
        user: process.env.MAIL_USER,
        pass: process.env.MAIL_PASS
      }
    });

    const mailOptions = {
      from: `"Fashion Shop" <${process.env.MAIL_USER}>`,
      to,
      subject: "Xác nhận đơn hàng của bạn",
      html: `
        <h2>Cảm ơn bạn đã đặt hàng!</h2>
        <p>Mã đơn hàng: <strong>${order._id}</strong></p>
        <p>Tổng tiền: <strong>${order.totalAmount.toLocaleString()}đ</strong></p>
        <p>Số sản phẩm: <strong>${order.items.length}</strong></p>
        <p>Ngày tạo đơn: ${new Date(order.createdAt).toLocaleString()}</p>
        <br/>
        <p>Chúng tôi sẽ liên hệ với bạn khi đơn hàng được giao!</p>
      `
    };

    await transporter.sendMail(mailOptions);

  } catch (err) {
    console.error("Email send failed:", err);
  }
};
