const crudRouter = require('./crudFactory');
const Service = require('../models/Service');

module.exports = crudRouter(Service, {
  authRequired: true,
  createRoles: ['workshop', 'admin'],
  updateRoles: ['workshop', 'admin'],
  deleteRoles: ['admin'],
  ownerField: null,
});
