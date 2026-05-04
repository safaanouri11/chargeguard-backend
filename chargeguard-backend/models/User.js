const mongoose = require('mongoose');
const userSchema = new mongoose.Schema({
  firstName:  { type: String, required: true },
  lastName:   { type: String, required: true },
  email:      { type: String, required: true, unique: true, lowercase: true },
  password:   { type: String, required: true },
  phone:      { type: String, default: '' },
  role:       { type: String, default: 'driver' },
  region:     { type: String, default: 'Palestine' },
  vehicle:    { type: String, default: '' },
  connector:  { type: String, default: 'CCS2' },
  avatar:     { type: String, default: '' },
  balance:    { type: Number, default: 0 },
  points:     { type: Number, default: 0 },
  batteryPct: { type: Number, default: 65 },
  // Host fields
  bio:          { type: String, default: '' },
  businessName: { type: String, default: '' },
  bankName:     { type: String, default: '' },
  iban:         { type: String, default: '' },
  hostEarnings: { type: Number, default: 0 },
  hostPayouts:  { type: Number, default: 0 },
  // Host verification
  hostStatus:      { type: String, default: 'None' }, // None, Pending, Approved, Rejected
  idImage:         { type: String, default: '' },
  licenseImage:    { type: String, default: '' },
  rejectionReason: { type: String, default: '' },
  approvedAt:      { type: Date, default: null },
  // Password Reset
  resetCode:       { type: String,  default: null },
  resetExpiry:     { type: Date,    default: null },
  // Host notifications
  notifBookings: { type: Boolean, default: true },
  notifPayouts:  { type: Boolean, default: true },
  notifReviews:  { type: Boolean, default: true },
  // Referral
  referralCode:     { type: String, unique: true, sparse: true, index: true },
  referredBy:       { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
  referralCount:    { type: Number, default: 0 },
  referralEarnings: { type: Number, default: 0 },
}, { timestamps: true });
module.exports = mongoose.model('User', userSchema);