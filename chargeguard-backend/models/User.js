const mongoose = require('mongoose');
const bcrypt   = require('bcryptjs');
const userSchema = new mongoose.Schema({
  firstName:  { type: String, required: true },
  lastName:   { type: String, required: true },
  email:      { type: String, required: true, unique: true, lowercase: true },
  password:   { type: String, required: true },
  phone:      { type: String, default: '' },
  role:       { type: String, enum: ['driver', 'host'], default: 'driver' },
  region:     { type: String, default: 'Palestine' },
  vehicle:    { type: String, default: '' },
  connector:  { type: String, default: 'CCS2' },
  avatar:     { type: String, default: '' },   // base64 or URL
  balance:    { type: Number, default: 0 },
  points:     { type: Number, default: 0 },
}, { timestamps: true });
// Hash password before save
userSchema.pre('save', async function(next) {
  if (!this.isModified('password')) return next();
  this.password = await bcrypt.hash(this.password, 10);
  next();
});
// Compare password
userSchema.methods.matchPassword = async function(entered) {
  return await bcrypt.compare(entered, this.password);
};
module.exports = mongoose.model('User', userSchema);