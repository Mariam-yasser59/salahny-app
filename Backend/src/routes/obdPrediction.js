const crudRouter = require('./crudFactory');
const ObdPrediction = require('../models/ObdPrediction');

module.exports = crudRouter(ObdPrediction, {
  scopeToOwner: true,
  populate: ['user', 'vehicle'],
  createRoles: ['driver', 'workshop', 'admin'],
  updateRoles: ['driver', 'workshop', 'admin'],
});
