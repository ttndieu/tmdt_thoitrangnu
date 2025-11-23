import User from "../models/User.js";
import bcrypt from "bcryptjs";

// GET /api/user/me
export const getProfile = async (req, res) => {
  try {
    return res.json({ user: req.user });
  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
};

// PUT /api/user/update
export const updateProfile = async (req, res) => {
  try {
    const { name, avatar, phone } = req.body;

    const user = await User.findByIdAndUpdate(
      req.user._id,
      { name, avatar, phone },
      { new: true }
    ).select("-password");

    return res.json({ user });
  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
};

// POST /api/user/change-password
export const changePassword = async (req, res) => {
  try {
    const { oldPassword, newPassword } = req.body;

    console.log('\n🔐 ========== CHANGE PASSWORD ==========');
    console.log('👤 User ID:', req.user._id);

    // Validate input
    if (!oldPassword || !newPassword) {
      return res.status(400).json({ 
        message: "Vui lòng nhập đầy đủ thông tin" 
      });
    }

    if (newPassword.length < 6) {
      return res.status(400).json({ 
        message: "Mật khẩu mới phải có ít nhất 6 ký tự" 
      });
    }

    // Tìm user với password
    const user = await User.findById(req.user._id);
    if (!user) {
      return res.status(404).json({ message: "Không tìm thấy người dùng" });
    }

    // Kiểm tra mật khẩu cũ
    const isMatch = await bcrypt.compare(oldPassword, user.password);
    if (!isMatch) {
      console.log('❌ Old password incorrect');
      return res.status(400).json({ 
        message: "Mật khẩu cũ không chính xác" 
      });
    }

    // Hash mật khẩu mới
    const hashedPassword = await bcrypt.hash(newPassword, 10);
    user.password = hashedPassword;
    await user.save();

    console.log('✅ Password changed successfully');
    console.log('🔐 ========== CHANGE PASSWORD END ==========\n');

    return res.json({ 
      message: "Đổi mật khẩu thành công" 
    });

  } catch (err) {
    console.error('❌ Change password error:', err);
    return res.status(500).json({ message: err.message });
  }
};

// POST /api/user/address
export const addAddress = async (req, res) => {
  try {
    const address = req.body;

    const user = await User.findById(req.user._id);
    user.addresses.push(address);
    await user.save();

    return res.json({ addresses: user.addresses });
  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
};

// DELETE /api/user/address/:addressId
export const deleteAddress = async (req, res) => {
  try {
    const { addressId } = req.params;

    const user = await User.findById(req.user._id);
    user.addresses = user.addresses.filter((a) => a._id.toString() !== addressId);
    await user.save();

    return res.json({ addresses: user.addresses });
  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
};
