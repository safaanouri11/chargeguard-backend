const express = require('express');
const bcrypt  = require('bcryptjs');
const jwt     = require('jsonwebtoken');
const User    = require('../models/User');
const router = express.Router();
const SECRET = process.env.JWT_SECRET || 'chargeguard_secret_2026';
function makeToken(id) {
  return jwt.sign({ id }, SECRET);
}
// POST /api/auth/register (driver)
router.post('/register', async function(req, res) {
  try {
    var { firstName, lastName, email, password, role, region } = req.body;
    var exists = await User.findOne({ email: email.toLowerCase() });
    if (exists) return res.status(400).json({ message: 'Email already in use' });
    var hashed = await bcrypt.hash(password, 10);
    var user = await User.create({
      firstName, lastName, email: email.toLowerCase(),
      password: hashed, role: role || 'driver', region: region || 'Palestine',
    });
    console.log('New user registered: ' + user.email);
    res.status(201).json({
      _id: user._id, firstName: user.firstName, lastName: user.lastName,
      email: user.email, role: user.role, balance: user.balance,
      points: user.points, batteryPct: user.batteryPct, token: makeToken(user._id),
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
// POST /api/auth/register-host
router.post('/register-host', async function(req, res) {
  try {
    var { firstName, lastName, email, password, businessName, phone,
          bankName, iban, idImage, licenseImage } = req.body;
    if (!idImage || !licenseImage) {
      return res.status(400).json({ message: 'ID and License images are required' });
    }
    var exists = await User.findOne({ email: email.toLowerCase() });
    if (exists) return res.status(400).json({ message: 'Email already in use' });
    var hashed = await bcrypt.hash(password, 10);
    var user = await User.create({
      firstName, lastName, email: email.toLowerCase(),
      password: hashed,
      role: 'host',
      region: 'Palestine',
      businessName: businessName || '',
      phone: phone || '',
      bankName: bankName || '',
      iban: iban || '',
      idImage, licenseImage,
      hostStatus: 'Pending',
    });
    console.log('New host application: ' + user.email + ' (PENDING REVIEW)');
    res.status(201).json({
      _id: user._id, firstName: user.firstName, lastName: user.lastName,
      email: user.email, role: user.role, businessName: user.businessName,
      phone: user.phone, hostStatus: user.hostStatus, token: makeToken(user._id),
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
// POST /api/auth/login
router.post('/login', async function(req, res) {
  try {
    var { email, password } = req.body;
    var user = await User.findOne({ email: email.toLowerCase() });
    if (!user) return res.status(401).json({ message: 'Invalid email or password' });
    var match = await bcrypt.compare(password, user.password);
    console.log('Login attempt:', email, '| Match:', match);
    if (!match) return res.status(401).json({ message: 'Invalid email or password' });
    console.log('User logged in: ' + user.email);
    res.json({
      _id: user._id, firstName: user.firstName, lastName: user.lastName,
      email: user.email, role: user.role, phone: user.phone,
      vehicle: user.vehicle, connector: user.connector, balance: user.balance,
      points: user.points, avatar: user.avatar, region: user.region,
      batteryPct: user.batteryPct, businessName: user.businessName,
      bankName: user.bankName, iban: user.iban, bio: user.bio,
      hostStatus: user.hostStatus, rejectionReason: user.rejectionReason,
      token: makeToken(user._id),
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
// POST /api/auth/forgot-password
router.post('/forgot-password', async function(req, res) {
  try {
    var user = await User.findOne({ email: (req.body.email || '').toLowerCase() });
    if (!user) return res.status(404).json({ message: 'No account found with this email' });
    // Generate 6-digit code
    var code = Math.floor(100000 + Math.random() * 900000).toString();
    var expiry = new Date(Date.now() + 15 * 60 * 1000); // 15 minutes
    await User.findByIdAndUpdate(user._id, { resetCode: code, resetExpiry: expiry });
    console.log('Reset code for ' + user.email + ': ' + code);
    // In production → send email. For demo → return code in response
    res.json({
      message: 'Reset code generated',
      code: code, // Remove in production
      firstName: user.firstName,
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
// POST /api/auth/reset-password
router.post('/reset-password', async function(req, res) {
  try {
    var { email, code, newPassword } = req.body;
    var user = await User.findOne({ email: email.toLowerCase() });
    if (!user) return res.status(404).json({ message: 'Account not found' });
    if (!user.resetCode || user.resetCode !== code) {
      return res.status(400).json({ message: 'Invalid reset code' });
    }
    if (new Date() > user.resetExpiry) {
      return res.status(400).json({ message: 'Reset code has expired' });
    }
    var hashed = await bcrypt.hash(newPassword, 10);
    await User.findByIdAndUpdate(user._id, {
      password: hashed, resetCode: null, resetExpiry: null
    });
    console.log('Password reset for: ' + user.email);
    res.json({ message: 'Password reset successfully' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
module.exports = router;