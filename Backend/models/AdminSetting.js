import mongoose from 'mongoose';

const adminSettingSchema = new mongoose.Schema(
  {
    key: {
      type: String,
      required: true,
      unique: true,
      trim: true,
    },
    privacyPolicy: {
      type: String,
      default: '',
    },
    aboutContent: {
      type: String,
      default: '',
    },
    announcementTitle: {
      type: String,
      default: '',
    },
    announcementBody: {
      type: String,
      default: '',
    },
    notificationsEnabled: {
      type: Boolean,
      default: true,
    },
  },
  {
    timestamps: true,
  },
);

const AdminSetting = mongoose.model('AdminSetting', adminSettingSchema);

export default AdminSetting;
