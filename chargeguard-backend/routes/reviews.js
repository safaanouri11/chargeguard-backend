const express = require('express');
const Review  = require('../models/Review');
const Station = require('../models/Station');
const Booking = require('../models/Booking');
const protect = require('../middleware/protect');
const notify  = require('../utils/notify');
const router = express.Router();
async function refreshStationRating(stationId) {
  var reviews = await Review.find({ station: stationId });
  if (reviews.length === 0) {
    await Station.findByIdAndUpdate(stationId, { rating: 5.0 });
    return;
  }
  var avg = reviews.reduce(function(s, r) { return s + r.rating; }, 0) / reviews.length;
  await Station.findByIdAndUpdate(stationId, { rating: Math.round(avg * 10) / 10 });
}
// GET /api/reviews/station/:stationId
router.get('/station/:stationId', async function(req, res) {
  try {
    var reviews = await Review.find({ station: req.params.stationId })
      .populate('user', 'firstName lastName avatar')
      .sort({ createdAt: -1 });
    var avg = reviews.length > 0
      ? reviews.reduce(function(s, r) { return s + r.rating; }, 0) / reviews.length
      : 0;
    res.json({
      reviews: reviews,
      count:   reviews.length,
      avgRating: Math.round(avg * 10) / 10,
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
// GET /api/reviews/me
router.get('/me', protect, async function(req, res) {
  try {
    var reviews = await Review.find({ user: req.user._id })
      .populate('station', 'name location')
      .sort({ createdAt: -1 });
    res.json(reviews);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
// POST /api/reviews/:stationId
router.post('/:stationId', protect, async function(req, res) {
  try {
    var rating = parseFloat(req.body.rating);
    if (!rating || rating < 1 || rating > 5) {
      return res.status(400).json({ message: 'Rating must be between 1 and 5' });
    }
    var station = await Station.findById(req.params.stationId);
    if (!station) return res.status(404).json({ message: 'Station not found' });
    // Only allow if user has a completed booking at this station
    var hadBooking = await Booking.exists({
      user: req.user._id, station: req.params.stationId, status: 'Completed'
    });
    if (!hadBooking) {
      return res.status(403).json({ message: 'You can only review stations you have used.' });
    }
    // One review per user per station — update if exists
    var existing = await Review.findOne({ user: req.user._id, station: req.params.stationId });
    var review;
    if (existing) {
      existing.rating = rating;
      existing.comment = req.body.comment || '';
      review = await existing.save();
    } else {
      review = await Review.create({
        user: req.user._id,
        station: req.params.stationId,
        host: station.host,
        rating: rating,
        comment: req.body.comment || '',
      });
      if (station.host) {
        await notify(station.host,
          'New Review',
          rating + '-star review on ' + station.name + '.',
          'review', '/host/reviews');
      }
    }
    await refreshStationRating(req.params.stationId);
    res.status(201).json(review);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
// PUT /api/reviews/:id  (edit own review)
router.put('/:id', protect, async function(req, res) {
  try {
    var review = await Review.findOne({ _id: req.params.id, user: req.user._id });
    if (!review) return res.status(404).json({ message: 'Not found' });
    if (req.body.rating !== undefined) {
      var r = parseFloat(req.body.rating);
      if (!r || r < 1 || r > 5) return res.status(400).json({ message: 'Invalid rating' });
      review.rating = r;
    }
    if (req.body.comment !== undefined) review.comment = req.body.comment;
    await review.save();
    await refreshStationRating(review.station);
    res.json(review);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
// DELETE /api/reviews/:id
router.delete('/:id', protect, async function(req, res) {
  try {
    var review = await Review.findOneAndDelete({ _id: req.params.id, user: req.user._id });
    if (!review) return res.status(404).json({ message: 'Not found' });
    await refreshStationRating(review.station);
    res.json({ message: 'Deleted' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
module.exports = router;
