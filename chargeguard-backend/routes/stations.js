const express = require('express');
const Station = require('../models/Station');
const { distanceKm } = require('../utils/distance');
const router = express.Router();

// Build a Mongo filter from the common station query params used by both
// `/` and `/nearby`. Returns a plain object suitable for Station.find().
function buildFilter(q) {
  var f = {};
  if (q.connectors) {
    f.connector = { $in: q.connectors.split(',').map(function(s) { return s.trim(); }) };
  } else if (q.connector) {
    f.connector = q.connector;
  }
  if (q.onlyAvailable === 'true') f.occupancy = 'free';
  if (q.minRating) {
    var r = parseFloat(q.minRating);
    if (!isNaN(r)) f.rating = { $gte: r };
  }
  if (q.networks) {
    f.network = { $in: q.networks.split(',').map(function(s) { return s.trim(); }) };
  }
  if (q.amenities) {
    var ams = q.amenities.split(',').map(function(s) { return s.trim(); });
    f.amenities = { $all: ams };
  }
  if (q.parking) {
    var pks = q.parking.split(',').map(function(s) { return s.trim(); });
    f.parking = { $in: pks };
  }
  if (q.minPlugCount) {
    var pc = parseInt(q.minPlugCount);
    if (!isNaN(pc)) f.plugCount = { $gte: pc };
  }
  if (q.includeComingSoon !== 'true') {
    // by default exclude Coming Soon; if explicitly requested, include
    if (q.onlyComingSoon === 'true') f.status = 'Coming Soon';
    else f.status = { $ne: 'Coming Soon' };
  }
  return f;
}

// Power filtering happens in-memory because `power` is a free-form string
// like "22 kW" / "AC" / "50 kW" — too messy for Mongo.
function powerFilter(stations, q) {
  var min = q.minPower != null ? parseFloat(q.minPower) : null;
  var max = q.maxPower != null ? parseFloat(q.maxPower) : null;
  if (min == null && max == null) return stations;
  return stations.filter(function(s) {
    var p = parseInt(s.power) || 0; // "AC" → 0
    if (min != null && p < min) return false;
    if (max != null && p > max) return false;
    return true;
  });
}

// GET /api/stations
// Supports: connectors=CCS2,Type 2 | connector=CCS2 | onlyAvailable=true |
// minRating=4 | networks=Tesla,ChargePoint | amenities=WiFi,Restroom |
// parking=Covered,Garage | minPlugCount=2 | minPower=22 | maxPower=350 |
// includeComingSoon=true | onlyComingSoon=true
router.get('/', async function(req, res) {
  try {
    var stations = await Station.find(buildFilter(req.query));
    res.json(powerFilter(stations, req.query));
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
// GET /api/stations/nearby?lat=&lng=&radius=&...filters
router.get('/nearby', async function(req, res) {
  try {
    var lat = parseFloat(req.query.lat);
    var lng = parseFloat(req.query.lng);
    var radius = parseFloat(req.query.radius) || 10; // km
    if (isNaN(lat) || isNaN(lng)) {
      return res.status(400).json({ message: 'lat and lng query params are required' });
    }
    var filter = buildFilter(req.query);
    filter['location.lat'] = { $ne: null };
    filter['location.lng'] = { $ne: null };
    var stations = await Station.find(filter);
    stations = powerFilter(stations, req.query);
    var withDistance = stations
      .map(function(s) {
        var d = distanceKm(lat, lng, s.location && s.location.lat, s.location && s.location.lng);
        return { station: s, distanceKm: Math.round(d * 100) / 100 };
      })
      .filter(function(x) { return x.distanceKm <= radius; })
      .sort(function(a, b) { return a.distanceKm - b.distanceKm; });
    res.json({
      count: withDistance.length,
      results: withDistance.map(function(x) {
        return Object.assign(x.station.toObject(), { distanceKm: x.distanceKm });
      }),
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
// GET /api/stations/filters — returns the distinct values available so the
// UI can show only filter options that actually have data behind them.
router.get('/filters', async function(req, res) {
  try {
    var [connectors, networks, amenities, parking] = await Promise.all([
      Station.distinct('connector'),
      Station.distinct('network'),
      Station.distinct('amenities'),
      Station.distinct('parking'),
    ]);
    res.json({
      connectors: connectors.filter(Boolean),
      networks:   networks.filter(Boolean),
      amenities:  amenities.filter(Boolean),
      parking:    parking.filter(Boolean),
    });
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
