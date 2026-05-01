require('dotenv').config();
const mongoose = require('mongoose');
const User = require('./src/models/User');
const Vehicle = require('./src/models/Vehicle');
const Workshop = require('./src/models/Workshop');
const Service = require('./src/models/Service');
const ServicePackage = require('./src/models/ServicePackage');
const Admin = require('./src/models/Admin');
const DriverProfile = require('./src/models/DriverProfile');

const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/salahny';

async function seed() {
  await mongoose.connect(MONGO_URI);
  console.log('[SEED] Connected to MongoDB');

  await User.deleteMany({});
  await Vehicle.deleteMany({});
  await Workshop.deleteMany({});
  await Service.deleteMany({});
  await ServicePackage.deleteMany({});
  await Admin.deleteMany({});
  await DriverProfile.deleteMany({});

  const [driver, ws1, ws2, admin] = await User.create([
    {
      name: 'Ahmed Hassan',
      email: 'driver@salahny.com',
      phone: '01012345678',
      password: 'password123',
      role: 'driver',
      walletBalance: 500,
      rating: 4.5,
      totalBookings: 5,
      isActive: true,
      isVerified: true,
    },
    {
      name: 'Mohamed Ali',
      email: 'workshop@salahny.com',
      phone: '01098765432',
      password: 'password123',
      role: 'workshop',
      workshopName: 'Al-Motahed Auto Workshop',
      address: '15 El-Tahrir St, Cairo',
      specialty: 'Engine & Diagnostics',
      rating: 4.8,
      reviewCount: 47,
      isOpen: true,
      isActive: true,
      isVerified: true,
      jobsDone: 234,
      services: ['Oil Change', 'OBD Diagnostics', 'Brake Service', 'AC Service'],
    },
    {
      name: 'Khaled Ibrahim',
      email: 'workshop2@salahny.com',
      phone: '01155556666',
      password: 'password123',
      role: 'workshop',
      workshopName: 'Speed Masters Garage',
      address: '88 Nasr City, Cairo',
      specialty: 'Transmission & Electrical',
      rating: 4.6,
      reviewCount: 31,
      isOpen: true,
      isActive: true,
      isVerified: true,
      jobsDone: 178,
      services: ['Transmission Service', 'Battery Check', 'Electrical Repair'],
    },
    {
      name: 'Super Admin',
      email: 'admin@salahny.com',
      phone: '01000000000',
      password: 'admin123',
      role: 'admin',
      isActive: true,
      isVerified: true,
    },
  ]);

  await DriverProfile.create({ user: driver._id, phone: driver.phone, status: 'active' });
  await Admin.create({ user: admin._id, permissions: ['all'], status: 'active' });

  await Vehicle.create([
    {
      ownerId: driver._id.toString(),
      make: 'Toyota',
      model: 'Camry',
      year: 2020,
      plate: 'ABC-1234',
      color: 'White',
      fuelType: 'Gasoline',
      mileage: 45000,
      health: 85,
    },
    {
      ownerId: driver._id.toString(),
      make: 'Hyundai',
      model: 'Elantra',
      year: 2018,
      plate: 'XYZ-9876',
      color: 'Silver',
      fuelType: 'Gasoline',
      mileage: 72000,
      health: 72,
    },
  ]);

  await Workshop.create([
    {
      name: 'Al-Motahed Auto Workshop',
      location: '15 El-Tahrir St, Cairo',
      services: ['Oil Change', 'OBD Diagnostics', 'Brake Service', 'AC Service'],
      prices: { 'Oil Change': 150, 'OBD Diagnostics': 200, 'Brake Service': 350, 'AC Service': 250 },
      owner: ws1._id,
    },
    {
      name: 'Speed Masters Garage',
      location: '88 Nasr City, Cairo',
      services: ['Transmission Service', 'Battery Check', 'Electrical Repair'],
      prices: { 'Transmission Service': 500, 'Battery Check': 100, 'Electrical Repair': 300 },
      owner: ws2._id,
    },
  ]);

  await Service.insertMany([
    { name: 'Oil Change', category: 'Maintenance', description: 'Full synthetic oil change with filter', price: 150, durationMins: 45, isPopular: true },
    { name: 'OBD Diagnostics', category: 'Diagnostics', description: 'Full OBD-II scan with AI analysis', price: 200, durationMins: 60, isPopular: true },
    { name: 'Brake Service', category: 'Safety', description: 'Brake pads and rotor inspection', price: 350, durationMins: 90, isPopular: false },
    { name: 'AC Service', category: 'Comfort', description: 'AC recharge and leak check', price: 250, durationMins: 60, isPopular: false },
    { name: 'Battery Check', category: 'Electrical', description: 'Battery load test and terminal clean', price: 100, durationMins: 30, isPopular: true },
    { name: 'Tire Rotation', category: 'Maintenance', description: 'Rotate and balance all 4 tires', price: 120, durationMins: 45, isPopular: false },
    { name: 'Engine Tune-Up', category: 'Maintenance', description: 'Spark plugs, air filter, fuel system', price: 450, durationMins: 120, isPopular: false },
    { name: 'Transmission Service', category: 'Drivetrain', description: 'Transmission fluid flush and filter', price: 500, durationMins: 120, isPopular: false },
  ]);

  await ServicePackage.insertMany([
    { name: 'Basic', tagline: 'For casual drivers', durationMonths: 1, price: 49, originalPrice: 69, features: ['1 OBD Scan/month', 'Basic fault detection', 'Email reports'] },
    { name: 'Pro', tagline: 'For regular maintenance', durationMonths: 3, price: 129, originalPrice: 189, isPopular: true, features: ['5 OBD Scans/month', 'AI fault prediction', 'Priority booking', 'SMS alerts', 'PDF reports'] },
    { name: 'Fleet', tagline: 'For fleet managers', durationMonths: 12, price: 399, originalPrice: 599, features: ['Unlimited scans', 'Multi-vehicle', 'Fleet analytics', 'Dedicated support', 'API access'] },
  ]);

  console.log('\n[SEED] Done! Test accounts:');
  console.log('  Driver:     driver@salahny.com    / password123');
  console.log('  Workshop 1: workshop@salahny.com  / password123');
  console.log('  Workshop 2: workshop2@salahny.com / password123');
  console.log('  Admin:      admin@salahny.com     / admin123');
  await mongoose.disconnect();
}

seed().catch((err) => {
  console.error(err);
  process.exit(1);
});
