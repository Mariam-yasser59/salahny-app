const crudRouter = require('./crudFactory');
const EmergencyRequest = require('../models/EmergencyRequest');

module.exports = crudRouter(EmergencyRequest, {
  scopeToOwner: true,
  populate: ['user', 'assignedWorkshop'],
  createRoles: ['driver', 'admin'],
  updateRoles: ['driver', 'workshop', 'admin'],
});
