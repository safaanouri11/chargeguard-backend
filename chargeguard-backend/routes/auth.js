const router = require('express').Router();
const jwt    = require('jsonwebtoken');
const User   = require('../models/user');
const makeToken = (id) =>
  jwt.sign({ id }, process.env.JWT_SECRET, { expiresIn: '30d' });
// ── POST /api/auth/register ───────────────────────────────
router.post('/register', async (req, res) => {
  try {
    const { firstName, lastName, email, password, role, region } = req.body;
    const exists = await User.findOne({ email });
    if (exists) return res.status(400).json({ message: 'Email already in use' });
    const user = await User.create({ firstName, lastName, email, password, role, region });
    res.status(201).json({
      _id:       user._id,
      firstName: user.firstName,
      lastName:  user.lastName,
      email:     user.email,
      role:      user.role,
      balance:   user.balance,
      points:    user.points,
      token:     makeToken(user._id),
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
// ── POST /api/auth/login ──────────────────────────────────
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    const user = await User.findOne({ email });
    if (!user) return res.status(401).json({ message: 'Invalid email or password' });
    const match = await user.matchPassword(password);
    if (!match) return res.status(401).json({ message: 'Invalid email or password' });
    res.json({
      _id:       user._id,
      firstName: user.firstName,
      lastName:  user.lastName,
      email:     user.email,
      role:      user.role,
      phone:     user.phone,
      vehicle:   user.vehicle,
      connector: user.connector,
      balance:   user.balance,
      points:    user.points,
      avatar:    user.avatar,
      token:     makeToken(user._id),
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
module.exports = router;