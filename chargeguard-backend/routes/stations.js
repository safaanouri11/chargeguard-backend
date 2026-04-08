const router  = require('express').Router();
const protect = require('../middleware/auth');
const Station = require('../models/Station');
// ── GET /api/stations ─────────────────────────────────────
router.get('/', async (req, res) => {
  try {
    const stations = await Station.find().populate('host', 'firstName lastName');
    res.json(stations);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
// ── POST /api/stations/seed — MUST be before /:id ─────────
router.post('/seed', async (req, res) => {
  try {
    await Station.deleteMany({});
    const stations = await Station.insertMany([
      {
        name: 'An-Najah EV Station',
        location: { lat: 32.221, lng: 35.258, address: 'An-Najah University, Nablus' },
        power: '50 kW', connector: 'CCS2', price: 2.5, available: true,
      },
      {
        name: 'City Mall Charger',
        location: { lat: 32.213, lng: 35.263, address: 'City Mall, Nablus' },
        power: '22 kW', connector: 'Type 2', price: 1.8, available: false,
      },
      {
        name: 'Campus Green Charger',
        location: { lat: 32.219, lng: 35.255, address: 'Campus Area, Nablus' },
        power: 'AC', connector: 'CCS2', price: 1.5, available: true,
      },
      {
        name: 'Downtown Fast Charger',
        location: { lat: 32.208, lng: 35.260, address: 'Downtown, Nablus' },
        power: '50 kW', connector: 'CHAdeMO', price: 3.0, available: false,
      },
    ]);
    res.json({ message: ` ${stations.length} stations seeded!`, stations });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
// ── GET /api/stations/:id ─────────────────────────────────
router.get('/:id', async (req, res) => {
  try {
    const station = await Station.findById(req.params.id).populate('host', 'firstName lastName');
    if (!station) return res.status(404).json({ message: 'Station not found' });
    res.json(station);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
// ── POST /api/stations (Host only) ───────────────────────
router.post('/', protect, async (req, res) => {
  try {
    if (req.user.role !== 'host') {
      return res.status(403).json({ message: 'Only hosts can add stations' });
    }
    const station = await Station.create({ ...req.body, host: req.user._id });
    res.status(201).json(station);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
// ── PUT /api/stations/:id ─────────────────────────────────
router.put('/:id', protect, async (req, res) => {
  try {
    const station = await Station.findById(req.params.id);
    if (!station) return res.status(404).json({ message: 'Station not found' });
    if (station.host && station.host.toString() !== req.user._id.toString()) {
      return res.status(403).json({ message: 'Not authorized' });
    }
    const updated = await Station.findByIdAndUpdate(req.params.id, req.body, { new: true });
    res.json(updated);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
module.exports = router;