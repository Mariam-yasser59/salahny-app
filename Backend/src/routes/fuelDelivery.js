const crudRouter = require('./crudFactory');
const FuelDeliveryRequest = require('../models/FuelDeliveryRequest');

module.exports = crudRouter(FuelDeliveryRequest, {
  scopeToOwner: true,
  populate: ['user'],
  createRoles: ['driver', 'admin'],
  updateRoles: ['driver', 'workshop', 'admin'],
});
