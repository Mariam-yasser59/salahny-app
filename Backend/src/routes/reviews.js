const crudRouter = require('./crudFactory');
const Review = require('../models/Review');

module.exports = crudRouter(Review, {
  populate: ['user', 'workshop', 'booking'],
  createRoles: ['driver', 'admin'],
  updateRoles: ['driver', 'admin'],
  publicRead: true,
});
