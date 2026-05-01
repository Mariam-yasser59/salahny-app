const crudRouter = require('./crudFactory');
const CarWashRequest = require('../models/CarWashRequest');

module.exports = crudRouter(CarWashRequest, {
  scopeToOwner: true,
  populate: ['user'],
  createRoles: ['driver', 'admin'],
  updateRoles: ['driver', 'workshop', 'admin'],
});
