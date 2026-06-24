import ActivityLog from '../models/ActivityLog.js';

export const logActivity = async ({
  actor,
  actorRole = 'system',
  action,
  target,
  details,
}) => {
  await ActivityLog.create({
    actor,
    actorRole,
    action,
    target,
    details,
  });
};
