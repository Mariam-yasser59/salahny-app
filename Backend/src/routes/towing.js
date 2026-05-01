const crudRouter = require('./crudFactory');
const TowingRequest = require('../models/TowingRequest');

module.exports = crudRouter(TowingRequest, {
  scopeToOwner: true,
  populate: ['user'],
  createRoles: ['driver', 'admin'],
  updateRoles: ['driver', 'workshop', 'admin'],
});
