const express = require('express');
const Station = require('../models/Station');
const router = express.Router();
// GET /api/stations
router.get('/', async function(req, res) {
  try {
    var stations = await Station.find();
    res.json(stations);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
// GET /api/stations/seed
router.get('/seed', async function(req, res) {
  try {
    await Station.deleteMany({});
    var stations = await Station.insertMany([
      { name: 'An-Najah EV Station',   location: { lat: 32.221, lng: 35.258, address: 'An-Najah University, Nablus' }, power: '50 kW', connector: 'CCS2',    price: 2.5, available: true,  rating: 4.8 },
      { name: 'City Mall Charger',     location: { lat: 32.213, lng: 35.263, address: 'City Mall, Nablus' },           power: '22 kW', connector: 'Type 2',  price: 1.8, available: true,  rating: 4.5 },
      { name: 'Campus Green Charger',  location: { lat: 32.219, lng: 35.255, address: 'Campus Area, Nablus' },         power: 'AC',    connector: 'CCS2',    price: 1.5, available: true,  rating: 4.7 },
      { name: 'Downtown Fast Charger', location: { lat: 32.208, lng: 35.260, address: 'Downtown, Nablus' },            power: '50 kW', connector: 'CHAdeMO', price: 3.0, available: true,  rating: 4.3 },
    ]);
    res.json({ message: stations.length + ' stations seeded!' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
// GET /api/stations/:id
router.get('/:id', async function(req, res) {
  try {
    var s = await Station.findById(req.params.id);
    if (!s) return res.status(404).json({ message: 'Not found' });
    res.json(s);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
module.exports = router;