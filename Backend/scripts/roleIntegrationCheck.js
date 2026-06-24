import { io as socketClient } from 'socket.io-client';

const baseUrl = process.env.SALAHNY_TEST_BASE_URL || 'http://localhost:5000/api';
const socketUrl = baseUrl.replace(/\/api\/?$/, '');
const runId = Date.now();
const slot = new Date(Date.now() + 3 * 24 * 60 * 60 * 1000);
slot.setMinutes(0, 0, 0);

const state = {
  adminToken: '',
  driverToken: '',
  workshopToken: '',
  driverId: '',
  workshopOwnerId: '',
  workshopId: '',
  bookingId: '',
  vehicleId: '',
  packageId: '',
};

const summary = [];

const request = async (path, options = {}) => {
  const response = await fetch(`${baseUrl}${path}`, options);
  const contentType = response.headers.get('content-type') || '';
  const payload = contentType.includes('application/json')
    ? await response.json()
    : await response.text();
  return { response, payload };
};

const jsonRequest = (path, { method = 'GET', token, body } = {}) =>
  request(path, {
    method,
    headers: {
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...(body ? { 'Content-Type': 'application/json' } : {}),
    },
    ...(body ? { body: JSON.stringify(body) } : {}),
  });

const expect = (name, actual, predicate) => {
  const ok = predicate(actual);
  summary.push({ name, ok, detail: ok ? 'ok' : JSON.stringify(actual) });
  if (!ok) {
    throw new Error(`${name} failed: ${JSON.stringify(actual)}`);
  }
};

const connectSocket = (token) =>
  new Promise((resolve, reject) => {
    const socket = socketClient(socketUrl, {
      transports: ['websocket'],
      auth: { token },
    });
    const timer = setTimeout(() => reject(new Error('socket connect timeout')), 5000);
    socket.on('connect', () => {
      clearTimeout(timer);
      resolve(socket);
    });
    socket.on('connect_error', reject);
  });

const onceEvent = (socket, event) =>
  new Promise((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error(`${event} timeout`)), 5000);
    socket.once(event, (payload) => {
      clearTimeout(timer);
      resolve(payload);
    });
  });

const uploadPermit = async () => {
  const form = new FormData();
  form.append('kind', 'permit');
  form.append(
    'file',
    new Blob(['temporary verification permit'], { type: 'application/pdf' }),
    `permit-${runId}.pdf`,
  );
  return request('/documents', {
    method: 'POST',
    headers: { Authorization: `Bearer ${state.workshopToken}` },
    body: form,
  });
};

const uploadDriverLicense = async () => {
  const form = new FormData();
  form.append('kind', 'driver_license');
  form.append(
    'file',
    new Blob(['temporary driver license'], { type: 'application/pdf' }),
    `driver-license-${runId}.pdf`,
  );
  return request('/documents', {
    method: 'POST',
    headers: { Authorization: `Bearer ${state.driverToken}` },
    body: form,
  });
};

const uploadObdFile = async (contents, fileName, mimeType) => {
  const form = new FormData();
  form.append('vehicleId', state.vehicleId);
  form.append('file', new Blob([contents], { type: mimeType }), fileName);
  return request('/diagnostics/upload-obd', {
    method: 'POST',
    headers: { Authorization: `Bearer ${state.driverToken}` },
    body: form,
  });
};

const cleanup = async () => {
  if (!state.adminToken) return;
  if (state.driverId) {
    await jsonRequest(`/admin/users/${state.driverId}`, {
      method: 'DELETE',
      token: state.adminToken,
    }).catch(() => {});
  }
  if (state.workshopOwnerId) {
    await jsonRequest(`/admin/users/${state.workshopOwnerId}`, {
      method: 'DELETE',
      token: state.adminToken,
    }).catch(() => {});
  }
  if (state.packageId) {
    await jsonRequest(`/packages/${state.packageId}`, {
      method: 'DELETE',
      token: state.adminToken,
    }).catch(() => {});
  }
};

try {
  const health = await jsonRequest('/health');
  expect('health', health.response.status, (status) => status === 200);

  const adminLogin = await jsonRequest('/auth/login', {
    method: 'POST',
    body: { email: 'admin@salahny.com', password: process.env.ADMIN_PASSWORD || 'admin123' },
  });
  expect('admin login', adminLogin.response.status, (status) => status === 200);
  state.adminToken = adminLogin.payload.data.token;

  const driverRegister = await jsonRequest('/auth/register', {
    method: 'POST',
    body: {
      name: `Integration Driver ${runId}`,
      email: `driver.${runId}@salahny.test`,
      phone: `010${String(runId).slice(-8)}`,
      password: 'Password1',
      role: 'driver',
    },
  });
  expect('driver register', driverRegister.response.status, (status) => status === 201);
  const resetRequest = await jsonRequest('/auth/forgot-password', {
    method: 'POST',
    body: { email: `driver.${runId}@salahny.test` },
  });
  expect('driver forgot password request', resetRequest.response.status, (status) => status === 200);
  state.driverToken = driverRegister.payload.data.token;
  state.driverId = driverRegister.payload.data.user.id;

  const uploadedLicense = await uploadDriverLicense();
  expect('driver license upload', uploadedLicense.response.status, (status) => status === 201);
  expect(
    'driver AI verification status saved',
    uploadedLicense.payload.data.aiVerificationStatus,
    (status) => ['ai_verified', 'ai_rejected', 'needs_admin_review'].includes(status),
  );
  const driverDocumentFile = await request(
    `/documents/${uploadedLicense.payload.data.id}/file?token=${state.adminToken}`,
  );
  expect('admin opens driver document', driverDocumentFile.response.status, (status) => status === 200);
  const adminVerifications = await jsonRequest('/admin/verifications', {
    token: state.adminToken,
  });
  expect(
    'admin sees verification AI result',
    adminVerifications.payload.data.some(
      (item) =>
        item._id === uploadedLicense.payload.data.id &&
        ['ai_verified', 'ai_rejected', 'needs_admin_review'].includes(item.aiVerificationStatus),
    ),
    (visible) => visible === true,
  );
  const approvedDriverLicense = await jsonRequest(
    `/admin/verifications/${uploadedLicense.payload.data.id}/approve`,
    {
      method: 'PATCH',
      token: state.adminToken,
      body: { reviewNotes: 'integration test approval' },
    },
  );
  expect('admin driver document approval', approvedDriverLicense.response.status, (status) => status === 200);
  const refreshedSession = await jsonRequest('/auth/refresh', {
    method: 'POST',
    body: { refreshToken: driverRegister.payload.data.refreshToken },
  });
  expect('driver refresh token rotation', refreshedSession.response.status, (status) => status === 200);
  state.driverToken = refreshedSession.payload.data.token;
  const updatedProfile = await jsonRequest('/users/me', {
    method: 'PUT',
    token: state.driverToken,
    body: {
      name: `Integration Driver Updated ${runId}`,
      email: `driver.${runId}@salahny.test`,
      phone: `010${String(runId).slice(-8)}`,
    },
  });
  expect('driver profile update', updatedProfile.response.status, (status) => status === 200);

  const workshopRegister = await jsonRequest('/auth/register', {
    method: 'POST',
    body: {
      name: `Integration Workshop Owner ${runId}`,
      email: `workshop.${runId}@salahny.test`,
      phone: `011${String(runId).slice(-8)}`,
      password: 'Password1',
      role: 'workshop',
    },
  });
  expect('workshop register', workshopRegister.response.status, (status) => status === 201);
  state.workshopToken = workshopRegister.payload.data.token;
  state.workshopOwnerId = workshopRegister.payload.data.user.id;

  const createdWorkshop = await jsonRequest('/workshops', {
    method: 'POST',
    token: state.workshopToken,
    body: {
      name: `Integration Garage ${runId}`,
      location: 'Integration City',
      serviceDetails: [{ name: 'Oil Change', price: 150, durationMins: 60 }],
      availableSlots: [slot.toISOString()],
      latitude: 30.0444,
      longitude: 31.2357,
      phone: '01111111111',
    },
  });
  expect('workshop profile create', createdWorkshop.response.status, (status) => status === 201);
  state.workshopId = createdWorkshop.payload.data._id;

  const hiddenBeforeApproval = await jsonRequest('/workshops');
  expect(
    'pending workshop hidden',
    hiddenBeforeApproval.payload.data.some((item) => item._id === state.workshopId),
    (visible) => visible === false,
  );
  const publicWorkshopsBeforeApproval = await jsonRequest('/public/workshops');
  expect(
    'public workshops hide pending workshop',
    publicWorkshopsBeforeApproval.payload.data.some((item) => item._id === state.workshopId),
    (visible) => visible === false,
  );

  const uploaded = await uploadPermit();
  expect('workshop permit upload', uploaded.response.status, (status) => status === 201);
  const documentId = uploaded.payload.data.id;
  const workshopDocumentFile = await request(`/documents/${documentId}/file?token=${state.adminToken}`);
  expect('admin opens workshop document', workshopDocumentFile.response.status, (status) => status === 200);

  const reviewed = await jsonRequest(`/admin/verifications/${documentId}/approve`, {
    method: 'PATCH',
    token: state.adminToken,
    body: { reviewNotes: 'integration test approval' },
  });
  expect('admin document approval', reviewed.response.status, (status) => status === 200);

  const workshopDashboard = await jsonRequest('/workshop-portal/dashboard', {
    token: state.workshopToken,
  });
  expect(
    'workshop sees approved status',
    workshopDashboard.payload.data.profile,
    (profile) => profile.isVerified === true && profile.accountStatus === 'active',
  );
  expect(
    'workshop dashboard starts empty',
    workshopDashboard.payload.data.stats,
    (stats) => stats.totalBookings === 0 && stats.active === 0 && stats.completed === 0,
  );

  const visibleAfterApproval = await jsonRequest('/workshops');
  expect(
    'approved workshop visible',
    visibleAfterApproval.payload.data.some((item) => item._id === state.workshopId),
    (visible) => visible === true,
  );

  const portalSlots = await jsonRequest('/workshop-portal/slots', {
    method: 'PUT',
    token: state.workshopToken,
    body: { slots: [slot.toISOString()] },
  });
  expect('workshop saves slots', portalSlots.response.status, (status) => status === 200);
  const reloadedSlots = await jsonRequest('/workshop-portal/slots', {
    token: state.workshopToken,
  });
  expect('workshop reloads slots', reloadedSlots.payload.data.length, (count) => count === 1);

  const vehicle = await jsonRequest('/vehicles', {
    method: 'POST',
    token: state.driverToken,
    body: {
      make: 'Toyota',
      model: 'Corolla',
      year: '2022',
      plate: `INT-${String(runId).slice(-5)}`,
    },
  });
  expect('driver vehicle create', vehicle.response.status, (status) => status === 201);
  state.vehicleId = vehicle.payload.data.id;
  const secondVehicle = await jsonRequest('/vehicles', {
    method: 'POST',
    token: state.driverToken,
    body: {
      make: 'Honda',
      model: 'Civic',
      year: '2023',
      plate: `TMP-${String(runId).slice(-5)}`,
    },
  });
  expect('driver second vehicle create', secondVehicle.response.status, (status) => status === 201);
  const vehiclesAfterAdd = await jsonRequest('/vehicles', { token: state.driverToken });
  expect('driver vehicle count increases', vehiclesAfterAdd.payload.data.length, (count) => count === 2);
  const deletedVehicle = await jsonRequest(`/vehicles/${secondVehicle.payload.data.id}`, {
    method: 'DELETE',
    token: state.driverToken,
  });
  expect('driver vehicle delete', deletedVehicle.response.status, (status) => status === 200);
  const vehiclesAfterDelete = await jsonRequest('/vehicles', { token: state.driverToken });
  expect('driver vehicle count decreases', vehiclesAfterDelete.payload.data.length, (count) => count === 1);

  const booking = await jsonRequest('/bookings', {
    method: 'POST',
    token: state.driverToken,
    body: {
      workshop: state.workshopId,
      service: 'Oil Change',
      serviceId: 'oil-change',
      date: slot.toISOString(),
      total: 150,
      vehicleLabel: 'Toyota Corolla 2022',
      vehicleId: state.vehicleId,
    },
  });
  expect('driver booking create', booking.response.status, (status) => status === 201);
  state.bookingId = booking.payload.data._id;
  const workshopAfterBooking = await jsonRequest(`/workshops/${state.workshopId}`);
  expect(
    'booked slot removed',
    workshopAfterBooking.payload.data.availableSlots.length,
    (count) => count === 0,
  );

  const driverSocket = await connectSocket(state.driverToken);
  await new Promise((resolve) =>
    driverSocket.emit('join_booking', { bookingId: state.bookingId }, resolve),
  );

  const duplicate = await jsonRequest('/bookings', {
    method: 'POST',
    token: state.driverToken,
    body: {
      workshop: state.workshopId,
      service: 'Oil Change',
      serviceId: 'oil-change',
      date: slot.toISOString(),
      total: 150,
      vehicleLabel: 'Toyota Corolla 2022',
      vehicleId: state.vehicleId,
    },
  });
  expect('double booking blocked', duplicate.response.status, (status) => status === 409);

  const portalBookings = await jsonRequest('/workshop-portal/bookings', {
    token: state.workshopToken,
  });
  expect(
    'workshop sees assigned booking',
    portalBookings.payload.data.some((item) => item.id === state.bookingId),
    (visible) => visible === true,
  );
  const driverBookings = await jsonRequest('/bookings', {
    token: state.driverToken,
  });
  expect(
    'driver sees own booking',
    driverBookings.payload.data.some((item) => item._id === state.bookingId),
    (visible) => visible === true,
  );

  const realtimeNotification = onceEvent(driverSocket, 'notification_created');
  const accepted = await jsonRequest(`/workshop-portal/bookings/${state.bookingId}/status`, {
    method: 'PATCH',
    token: state.workshopToken,
    body: { status: 'accepted' },
  });
  expect('workshop accepts booking', accepted.response.status, (status) => status === 200);
  const dashboardAfterAccept = await jsonRequest('/workshop-portal/dashboard', {
    token: state.workshopToken,
  });
  expect(
    'workshop dashboard counts accepted booking',
    dashboardAfterAccept.payload.data.stats,
    (stats) => stats.totalBookings === 1 && stats.active === 1,
  );
  expect(
    'driver receives live notification',
    (await realtimeNotification).type,
    (type) => type === 'booking',
  );

  const inProgress = await jsonRequest(`/workshop-portal/bookings/${state.bookingId}/status`, {
    method: 'PATCH',
    token: state.workshopToken,
    body: { status: 'in_progress' },
  });
  expect('workshop starts service', inProgress.payload.data.status, (status) => status === 'in_progress');
  const visibleCurrentRequest = await jsonRequest('/workshop-portal/bookings', {
    token: state.workshopToken,
  });
  expect(
    'in-progress request remains visible',
    visibleCurrentRequest.payload.data.some(
      (item) => item.id === state.bookingId && item.status === 'in_progress',
    ),
    (visible) => visible === true,
  );

  const diagnosticsBeforeAttach = await jsonRequest(
    `/workshop-portal/bookings/${state.bookingId}/status`,
    {
      method: 'PATCH',
      token: state.workshopToken,
      body: { status: 'diagnostics_ready' },
    },
  );
  expect(
    'workshop cannot skip required diagnostic',
    diagnosticsBeforeAttach.response.status,
    (status) => status === 409,
  );

  const workshopScan = await jsonRequest(`/diagnostics/workshop/${state.bookingId}/run`, {
    method: 'POST',
    token: state.workshopToken,
    body: {
      sensorReadings: {
        coolantTemp: 96,
        rpm: 2200,
        speed: 40,
      },
    },
  });
  expect('workshop booking diagnostic scan', workshopScan.response.status, (status) => status === 201);

  const diagnosticsReady = await jsonRequest(
    `/workshop-portal/bookings/${state.bookingId}/status`,
    {
      method: 'PATCH',
      token: state.workshopToken,
      body: { status: 'diagnostics_ready' },
    },
  );
  expect(
    'workshop marks diagnostics ready',
    diagnosticsReady.payload.data.status,
    (status) => status === 'diagnostics_ready',
  );

  const repairInProgress = await jsonRequest(
    `/workshop-portal/bookings/${state.bookingId}/status`,
    {
      method: 'PATCH',
      token: state.workshopToken,
      body: { status: 'repair_in_progress' },
    },
  );
  expect(
    'workshop starts repair',
    repairInProgress.payload.data.status,
    (status) => status === 'repair_in_progress',
  );
  const completed = await jsonRequest(`/workshop-portal/bookings/${state.bookingId}/status`, {
    method: 'PATCH',
    token: state.workshopToken,
    body: { status: 'completed' },
  });
  expect('workshop completes booking', completed.payload.data.status, (status) => status === 'completed');
  const dashboardAfterComplete = await jsonRequest('/workshop-portal/dashboard', {
    token: state.workshopToken,
  });
  expect(
    'workshop dashboard counts completed booking',
    dashboardAfterComplete.payload.data.stats,
    (stats) => stats.active === 0 && stats.completed === 1 && stats.revenue === 150,
  );
  const workshopDashboardAlias = await jsonRequest('/workshops/dashboard', {
    token: state.workshopToken,
  });
  expect(
    'workshop dashboard alias exposes earnings',
    workshopDashboardAlias.payload.data.stats.revenue,
    (revenue) => revenue === 150,
  );

  const driverMessage = await jsonRequest(`/chat/bookings/${state.bookingId}/messages`, {
    method: 'POST',
    token: state.driverToken,
    body: { text: 'Please check the filter too.' },
  });
  expect('driver sends workshop chat', driverMessage.response.status, (status) => status === 201);

  const realtimeBookingMessage = onceEvent(driverSocket, 'booking_message');
  const workshopReply = await jsonRequest(`/chat/bookings/${state.bookingId}/messages`, {
    method: 'POST',
    token: state.workshopToken,
    body: { text: 'We will inspect it.' },
  });
  expect('workshop replies in chat', workshopReply.response.status, (status) => status === 201);
  expect(
    'driver receives live booking chat',
    (await realtimeBookingMessage).text,
    (text) => text === 'We will inspect it.',
  );

  const monitoredChats = await jsonRequest('/admin/chats/bookings', {
    token: state.adminToken,
  });
  expect(
    'admin monitors booking chats',
    monitoredChats.payload.data.some(
      (item) =>
        item.bookingId === state.bookingId &&
        item.driver?.id === state.driverId &&
        item.workshop?.id === state.workshopId,
    ),
    (visible) => visible === true,
  );

  const workshopAdminMessage = await jsonRequest('/workshop-portal/admin/messages', {
    method: 'POST',
    token: state.workshopToken,
    body: { text: 'Need admin assistance for a pricing question.' },
  });
  expect(
    'workshop sends admin message',
    workshopAdminMessage.response.status,
    (status) => status === 201,
  );

  const adminWorkshopThread = await jsonRequest(`/admin/workshops/${state.workshopId}/messages`, {
    token: state.adminToken,
  });
  expect(
    'admin sees workshop message',
    adminWorkshopThread.payload.data.messages.length > 0,
    (visible) => visible === true,
  );

  const scan = await jsonRequest('/diagnostics/scan', {
    method: 'POST',
    token: state.driverToken,
    body: {
      vehicleId: state.vehicleId,
      sensorReadings: {
        ENGINE_RPM: 900,
        COOLANT_TEMPERATURE: 90,
        VEHICLE_SPEED: 0,
        CONTROL_MODULE_VOLTAGE: 12.6,
      },
      faultCodes: [],
    },
  });
  expect('driver diagnostic scan', scan.response.status, (status) => status === 201);
  const csvUpload = await uploadObdFile(
    'ENGINE_RPM,COOLANT_TEMPERATURE,VEHICLE_SPEED,CONTROL_MODULE_VOLTAGE\n900,90,0,12.6',
    'obd.csv',
    'text/csv',
  );
  expect('driver uploads OBD CSV', csvUpload.response.status, (status) => status === 201);
  const jsonUpload = await uploadObdFile(
    JSON.stringify({
      ENGINE_RPM: 1200,
      COOLANT_TEMPERATURE: 92,
      VEHICLE_SPEED: 12,
      CONTROL_MODULE_VOLTAGE: 12.7,
    }),
    'obd.json',
    'application/json',
  );
  expect('driver uploads OBD JSON', jsonUpload.response.status, (status) => status === 201);
  const adminDiagnostics = await jsonRequest('/admin/diagnostics', {
    token: state.adminToken,
  });
  expect(
    'admin sees diagnostics',
    adminDiagnostics.payload.data.some((item) => item.driver?.id === state.driverId),
    (visible) => visible === true,
  );

  const notifications = await jsonRequest('/notifications', {
    token: state.driverToken,
  });
  expect(
    'driver receives notifications',
    notifications.payload.data.length > 0,
    (visible) => visible === true,
  );

  const driverAdminMessage = await jsonRequest('/direct-messages/admin', {
    method: 'POST',
    token: state.driverToken,
    body: { text: 'Need admin help.' },
  });
  expect('driver sends admin message', driverAdminMessage.response.status, (status) => status === 201);

  const adminDriverThread = await jsonRequest(`/admin/drivers/${state.driverId}/messages`, {
    token: state.adminToken,
  });
  expect(
    'admin sees driver message',
    adminDriverThread.payload.data.length > 0,
    (visible) => visible === true,
  );

  const realtimeTracking = onceEvent(driverSocket, 'tracking_update');
  const tracking = await jsonRequest(`/tracking/${state.bookingId}`, {
    method: 'POST',
    token: state.workshopToken,
    body: { latitude: 30.0444, longitude: 31.2357, etaMinutes: 12, note: 'On route' },
  });
  expect('workshop posts tracking', tracking.response.status, (status) => status === 201);
  expect(
    'driver receives live tracking',
    (await realtimeTracking).etaMinutes,
    (eta) => eta === 12,
  );
  const driverTracking = await jsonRequest(`/tracking/${state.bookingId}`, {
    token: state.driverToken,
  });
  expect(
    'driver reads tracking',
    driverTracking.payload.data.length > 0,
    (visible) => visible === true,
  );

  const emergency = await jsonRequest('/emergency', {
    method: 'POST',
    token: state.driverToken,
    body: {
      emergencyType: 'engine',
      issueDescription: 'Integration roadside check',
      address: 'Integration City',
      latitude: 30.0445,
      longitude: 31.2358,
      locationNotes: 'Near integration landmark',
      phone: '01000000000',
      vehicleLabel: 'Toyota Corolla 2022',
      vehicleId: state.vehicleId,
    },
  });
  expect('driver emergency request', emergency.response.status, (status) => status === 201);
  expect(
    'emergency auto assignment',
    emergency.payload.data,
    (item) => item.status === 'assigned' && item.assignedWorkshop?.id === state.workshopId,
  );
  const workshopEmergency = await jsonRequest('/emergency/workshop/assigned', {
    token: state.workshopToken,
  });
  expect(
    'workshop sees assigned emergency',
    workshopEmergency.payload.data.some((item) => item.id === emergency.payload.data.id),
    (visible) => visible === true,
  );
  const adminEmergency = await jsonRequest('/admin/emergency', {
    token: state.adminToken,
  });
  expect(
    'admin sees emergency',
    adminEmergency.payload.data.some((item) => item.id === emergency.payload.data.id),
    (visible) => visible === true,
  );
  const acceptedEmergency = await jsonRequest(`/emergency/${emergency.payload.data.id}/accept`, {
    method: 'PATCH',
    token: state.workshopToken,
    body: {},
  });
  expect(
    'workshop accepts emergency',
    acceptedEmergency.payload.data.status,
    (status) => status === 'accepted_by_workshop',
  );
  const emergencyChat = await jsonRequest(`/emergency/${emergency.payload.data.id}/messages`, {
    method: 'POST',
    token: state.driverToken,
    body: { text: 'Please hurry.' },
  });
  expect('driver sends emergency chat', emergencyChat.response.status, (status) => status === 201);
  const manualEmergency = await jsonRequest('/emergency', {
    method: 'POST',
    token: state.driverToken,
    body: {
      emergencyType: 'other',
      issueDescription: 'Manual address only',
      address: 'Manual-only location',
      locationNotes: 'No GPS permission',
      vehicleId: state.vehicleId,
    },
  });
  expect(
    'manual emergency waits for admin assignment',
    manualEmergency.payload.data.status,
    (status) => status === 'pending_admin_assignment',
  );

  const createdPackage = await jsonRequest('/packages', {
    method: 'POST',
    token: state.adminToken,
    body: {
      name: `Integration Package ${runId}`,
      tagline: 'Integration test package',
      durationMonths: 1,
      price: 99,
      originalPrice: 120,
      features: ['Integration feature'],
      isPopular: false,
      isEnabled: true,
    },
  });
  expect('admin creates package', createdPackage.response.status, (status) => status === 201);
  state.packageId = createdPackage.payload.data._id;

  const purchase = await jsonRequest('/payments/packages', {
    method: 'POST',
    token: state.driverToken,
    body: {
      packageId: state.packageId,
      paymentMethod: 'Cash on Service',
    },
  });
  expect('driver package purchase', purchase.response.status, (status) => status === 201);
  const subscribers = await jsonRequest(`/admin/packages/${state.packageId}/subscribers`, {
    token: state.adminToken,
  });
  expect(
    'admin sees package subscribers',
    subscribers.payload.data.some((item) => item.userId === state.driverId),
    (visible) => visible === true,
  );
  const earnings = await jsonRequest('/workshop-portal/earnings', {
    token: state.workshopToken,
  });
  expect(
    'workshop earnings recorded once',
    earnings.payload.data,
    (data) => data.total === 150 && data.items.length === 1,
  );
  const completeAgain = await jsonRequest(`/workshop-portal/bookings/${state.bookingId}/status`, {
    method: 'PATCH',
    token: state.workshopToken,
    body: { status: 'completed' },
  });
  expect('booking can remain completed', completeAgain.response.status, (status) => status === 200);
  const earningsAfterRepeat = await jsonRequest('/workshop-portal/earnings', {
    token: state.workshopToken,
  });
  expect(
    'duplicate earnings prevented',
    earningsAfterRepeat.payload.data,
    (data) => data.total === 150 && data.items.length === 1,
  );
  driverSocket.close();
} finally {
  await cleanup();
  console.table(summary);
}
