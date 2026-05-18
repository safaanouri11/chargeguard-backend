const express = require('express');
const bcrypt  = require('bcryptjs');
const jwt     = require('jsonwebtoken');
const User    = require('../models/User');
const Transaction = require('../models/Transaction');
const notify  = require('../utils/notify');
const { generateUniqueCode } = require('../utils/referralCode');
const router = express.Router();
const SECRET = process.env.JWT_SECRET || 'chargeguard_secret_2026';
const REFERRER_BONUS = 10; // NIS to inviter when invitee registers
const INVITEE_BONUS  = 5;  // NIS welcome bonus to new user
async function applyReferral(newUser, code) {
  if (!code) return;
  var inviter = await User.findOne({ referralCode: code.toUpperCase() });
  if (!inviter || inviter._id.equals(newUser._id)) return;
  await User.findByIdAndUpdate(newUser._id, {
    referredBy: inviter._id,
    $inc: { balance: INVITEE_BONUS },
  });
  await User.findByIdAndUpdate(inviter._id, {
    $inc: { balance: REFERRER_BONUS, referralCount: 1, referralEarnings: REFERRER_BONUS },
  });
  await Transaction.create({
    user: newUser._id, label: 'Referral Welcome Bonus',
    amount: INVITEE_BONUS, type: 'referral',
  });
  await Transaction.create({
    user: inviter._id, label: 'Referral Reward (' + newUser.firstName + ')',
    amount: REFERRER_BONUS, type: 'referral',
  });
  await notify(inviter._id,
    'Referral Reward',
    'You earned ' + REFERRER_BONUS + ' NIS — ' + newUser.firstName + ' joined using your code.',
    'referral', '/referrals');
  await notify(newUser._id,
    'Welcome Bonus',
    INVITEE_BONUS + ' NIS added to your wallet for joining via referral.',
    'referral', '/wallet');
}
function makeToken(id) {
  return jwt.sign({ id }, SECRET);
}
// POST /api/auth/register (driver)
router.post('/register', async function(req, res) {
  try {
    var { firstName, lastName, email, password, role, region, referralCode } = req.body;
    var exists = await User.findOne({ email: email.toLowerCase() });
    if (exists) return res.status(400).json({ message: 'Email already in use' });
    var hashed = await bcrypt.hash(password, 10);
    var newCode = await generateUniqueCode();
    var user = await User.create({
      firstName, lastName, email: email.toLowerCase(),
      password: hashed, role: role || 'driver', region: region || 'Palestine',
      referralCode: newCode,
    });
    await applyReferral(user, referralCode);
    var fresh = await User.findById(user._id);
    console.log('New user registered: ' + fresh.email);
    res.status(201).json({
      _id: fresh._id, firstName: fresh.firstName, lastName: fresh.lastName,
      email: fresh.email, role: fresh.role, balance: fresh.balance,
      points: fresh.points, batteryPct: fresh.batteryPct,
      referralCode: fresh.referralCode, token: makeToken(fresh._id),
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
// POST /api/auth/register-host
router.post('/register-host', async function(req, res) {
  try {
    var { firstName, lastName, email, password, businessName, phone,
          bankName, iban, idImage, licenseImage, referralCode } = req.body;
    if (!idImage || !licenseImage) {
      return res.status(400).json({ message: 'ID and License images are required' });
    }
    var exists = await User.findOne({ email: email.toLowerCase() });
    if (exists) return res.status(400).json({ message: 'Email already in use' });
    var hashed = await bcrypt.hash(password, 10);
    var newCode = await generateUniqueCode();
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
      referralCode: newCode,
    });
    await applyReferral(user, referralCode);
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
    if (user.suspended) {
      return res.status(403).json({
        message: 'Account suspended' + (user.suspendedReason ? ': ' + user.suspendedReason : ''),
      });
    }
    console.log('User logged in: ' + user.email);
    res.json({
      _id: user._id, firstName: user.firstName, lastName: user.lastName,
      email: user.email, role: user.role, phone: user.phone,
      vehicle: user.vehicle, connector: user.connector, balance: user.balance,
      points: user.points, avatar: user.avatar, region: user.region,
      batteryPct: user.batteryPct, businessName: user.businessName,
      bankName: user.bankName, iban: user.iban, bio: user.bio,
      hostStatus: user.hostStatus, rejectionReason: user.rejectionReason,
      referralCode: user.referralCode,
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