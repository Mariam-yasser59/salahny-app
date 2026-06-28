export const APP_SERVICE_FEE_RATE = 0.10;

const service = (id, category, name, price, durationMins, range, description, isPopular = false) => ({
  id,
  name,
  category,
  description: `${description} Average workshop price in Egypt: ${range}.`,
  emoji: 'Service',
  price,
  durationMins,
  isPopular,
  isEnabled: true,
});

export const egyptServiceCatalog = [
  service('engine-inspection', 'Engine & Mechanical', 'Engine Inspection', 400, 60, '300-500 EGP', 'Mechanical inspection for leaks, noises, overheating, mounts, and visible engine faults.', true),
  service('engine-overhaul', 'Engine & Mechanical', 'Engine Overhaul', 23500, 1440, '12,000-35,000 EGP', 'Major engine repair quotation after inspection.'),
  service('engine-oil-change', 'Engine & Mechanical', 'Engine Oil Change', 350, 45, '200-500 EGP labor', 'Oil change labor with level checks.'),
  service('oil-filter-replacement', 'Engine & Mechanical', 'Oil Filter Replacement', 100, 30, '50-150 EGP', 'Oil filter replacement labor.'),
  service('spark-plug-replacement', 'Engine & Mechanical', 'Spark Plug Replacement', 275, 45, '150-400 EGP', 'Spark plug inspection and replacement labor.'),
  service('timing-belt-replacement', 'Engine & Mechanical', 'Timing Belt Replacement', 1400, 180, '800-2,000 EGP', 'Timing belt replacement labor and timing check.'),
  service('water-pump-replacement', 'Engine & Mechanical', 'Water Pump Replacement', 1250, 180, '700-1,800 EGP', 'Water pump replacement labor and cooling-system bleeding.'),
  service('engine-mount-replacement', 'Engine & Mechanical', 'Engine Mount Replacement', 850, 120, '500-1,200 EGP', 'Engine mount inspection and replacement labor.'),
  service('fuel-pump-replacement', 'Engine & Mechanical', 'Fuel Pump Replacement', 1350, 150, '700-2,000 EGP', 'Fuel pump diagnosis and replacement labor.'),
  service('engine-tune-up', 'Engine & Mechanical', 'Engine Tune-Up', 1000, 120, '500-1,500 EGP', 'Preventive engine tune-up and performance check.', true),

  service('battery-replacement', 'Electrical System', 'Battery Replacement', 225, 30, '150-300 EGP labor', 'Battery replacement labor and terminal check.'),
  service('battery-check', 'Electrical System', 'Battery Check', 150, 20, '100-200 EGP', 'Battery load test and charging-voltage check.'),
  service('alternator-repair', 'Electrical System', 'Alternator Repair', 1300, 180, '600-2,000 EGP', 'Alternator diagnosis and repair labor.'),
  service('starter-motor-repair', 'Electrical System', 'Starter Motor Repair', 1050, 150, '600-1,500 EGP', 'Starter diagnosis and repair labor.'),
  service('wiring-repair', 'Electrical System', 'Wiring Repair', 1150, 180, '300-2,000 EGP', 'Electrical wiring diagnosis and repair estimate.'),
  service('fuse-replacement', 'Electrical System', 'Fuse Replacement', 100, 20, '50-150 EGP', 'Fuse inspection and replacement.'),
  service('sensor-replacement', 'Electrical System', 'Sensor Replacement', 1400, 90, '300-2,500 EGP', 'Faulty sensor diagnosis and replacement labor.'),
  service('ecu-diagnostics', 'Electrical System', 'ECU Diagnostics', 500, 45, '300-700 EGP', 'ECU scan and diagnostic report.'),
  service('ecu-programming', 'Electrical System', 'ECU Programming', 1900, 120, '800-3,000 EGP', 'ECU coding/programming quotation.'),

  service('ac-inspection', 'Air Conditioning', 'AC Inspection', 300, 45, '200-400 EGP', 'Air-conditioning cooling and pressure inspection.'),
  service('ac-gas-recharge', 'Air Conditioning', 'AC Gas Recharge', 700, 60, '500-900 EGP', 'AC gas recharge and pressure check.', true),
  service('compressor-repair', 'Air Conditioning', 'Compressor Repair', 3250, 180, '1,500-5,000 EGP', 'AC compressor inspection and repair estimate.'),
  service('cabin-filter-replacement', 'Air Conditioning', 'Cabin Filter Replacement', 175, 20, '100-250 EGP', 'Cabin filter replacement labor.'),
  service('ac-cleaning', 'Air Conditioning', 'AC Cleaning', 500, 60, '300-700 EGP', 'AC vents and evaporator cleaning.'),
  service('ac-leak-detection', 'Air Conditioning', 'AC Leak Detection', 500, 60, '300-700 EGP', 'Leak detection and pressure test.'),

  service('tire-replacement', 'Tires & Wheels', 'Tire Replacement', 120, 30, '80-150 EGP per tire', 'Tire mounting labor per tire.'),
  service('wheel-balancing', 'Tires & Wheels', 'Wheel Balancing', 100, 30, '80-120 EGP per wheel', 'Wheel balancing per wheel.'),
  service('wheel-alignment', 'Tires & Wheels', 'Wheel Alignment', 375, 45, '250-500 EGP', 'Computerized wheel alignment.'),
  service('tire-repair', 'Tires & Wheels', 'Tire Repair', 85, 20, '50-120 EGP', 'Puncture repair and pressure check.'),
  service('nitrogen-filling', 'Tires & Wheels', 'Nitrogen Filling', 35, 20, '20-50 EGP per tire', 'Nitrogen filling per tire.'),
  service('tire-rotation', 'Tires & Wheels', 'Tire Rotation', 225, 30, '150-300 EGP', 'Tire rotation and visual inspection.'),

  service('brake-inspection', 'Brake System', 'Brake Inspection', 275, 45, '200-350 EGP', 'Brake pad, disc, oil, and safety inspection.'),
  service('brake-pads-replacement', 'Brake System', 'Brake Pads Replacement', 475, 60, '250-700 EGP', 'Brake pad replacement labor.', true),
  service('brake-disc-replacement', 'Brake System', 'Brake Disc Replacement', 1000, 90, '500-1,500 EGP', 'Brake disc replacement labor.'),
  service('brake-oil-change', 'Brake System', 'Brake Oil Change', 375, 45, '250-500 EGP', 'Brake fluid replacement and bleeding.'),
  service('abs-diagnosis', 'Brake System', 'ABS Diagnosis', 500, 45, '300-700 EGP', 'ABS fault scan and diagnosis.'),
  service('brake-caliper-repair', 'Brake System', 'Brake Caliper Repair', 800, 90, '400-1,200 EGP', 'Brake caliper repair labor.'),

  service('suspension-inspection', 'Suspension & Steering', 'Suspension Inspection', 375, 60, '250-500 EGP', 'Suspension and steering inspection.'),
  service('shock-absorber-replacement', 'Suspension & Steering', 'Shock Absorber Replacement', 1000, 120, '500-1,500 EGP', 'Shock absorber replacement labor.'),
  service('steering-rack-repair', 'Suspension & Steering', 'Steering Rack Repair', 4000, 240, '2,000-6,000 EGP', 'Steering rack repair quotation.'),
  service('tie-rod-replacement', 'Suspension & Steering', 'Tie Rod Replacement', 500, 60, '300-700 EGP', 'Tie rod replacement labor.'),
  service('ball-joint-replacement', 'Suspension & Steering', 'Ball Joint Replacement', 550, 75, '300-800 EGP', 'Ball joint replacement labor.'),
  service('wheel-bearing-replacement', 'Suspension & Steering', 'Wheel Bearing Replacement', 800, 90, '400-1,200 EGP', 'Wheel bearing replacement labor.'),

  service('transmission-inspection', 'Transmission', 'Transmission Inspection', 500, 60, '300-700 EGP', 'Transmission inspection and fault check.'),
  service('gear-oil-change', 'Transmission', 'Gear Oil Change', 550, 60, '300-800 EGP', 'Gear oil replacement labor.'),
  service('automatic-transmission-service', 'Transmission', 'Automatic Transmission Service', 1750, 120, '1,000-2,500 EGP', 'Automatic transmission service labor.'),
  service('clutch-replacement', 'Transmission', 'Clutch Replacement', 4750, 240, '2,500-7,000 EGP', 'Clutch replacement labor estimate.'),
  service('gearbox-repair', 'Transmission', 'Gearbox Repair', 12500, 360, '5,000-20,000 EGP', 'Gearbox repair quotation after inspection.'),

  service('obd-ii-scan', 'Diagnostics', 'OBD-II Scan', 300, 30, '200-400 EGP', 'OBD-II scanner fault-code reading.'),
  service('full-computer-diagnostics', 'Diagnostics', 'Full Computer Diagnostics', 500, 45, '300-700 EGP', 'Full computer scan and diagnosis.', true),
  service('engine-fault-diagnosis', 'Diagnostics', 'Engine Fault Diagnosis', 450, 45, '300-600 EGP', 'Engine fault diagnosis using scanner and inspection.'),
  service('check-engine-reset', 'Diagnostics', 'Check Engine Reset', 175, 20, '100-250 EGP', 'Check-engine reset after diagnosis.'),
  service('ai-diagnosis-report', 'Diagnostics', 'AI Diagnosis Report', 225, 30, '150-300 EGP', 'AI-assisted detection and prediction report from OBD readings.', true),

  service('tow-truck-city', 'Emergency Services', 'Tow Truck Inside City', 500, 60, '300-700 EGP', 'Tow truck service inside the city.'),
  service('tow-truck-outside-city', 'Emergency Services', 'Tow Truck Outside City', 700, 90, 'Starts from 700 EGP', 'Tow truck service outside the city.'),
  service('battery-jump-start', 'Emergency Services', 'Battery Jump Start', 275, 30, '200-350 EGP', 'Roadside battery jump start.'),
  service('flat-tire-assistance', 'Emergency Services', 'Flat Tire Assistance', 225, 30, '150-300 EGP', 'Roadside flat tire assistance.'),
  service('fuel-delivery', 'Emergency Services', 'Fuel Delivery', 300, 45, '200-400 EGP plus fuel price', 'Roadside fuel delivery excluding fuel cost.'),
  service('emergency-lockout', 'Emergency Services', 'Emergency Lockout', 500, 45, '300-700 EGP', 'Vehicle lockout roadside assistance.'),

  service('exterior-wash', 'Car Care', 'Exterior Wash', 140, 30, '80-200 EGP', 'Exterior car wash.'),
  service('interior-cleaning', 'Car Care', 'Interior Cleaning', 325, 60, '150-500 EGP', 'Interior cleaning service.'),
  service('full-detailing', 'Car Care', 'Full Detailing', 3000, 240, '1,000-5,000 EGP', 'Interior and exterior detailing.'),
  service('polish', 'Car Care', 'Polish', 1250, 180, '500-2,000 EGP', 'Exterior polish service.'),
  service('ceramic-coating', 'Car Care', 'Ceramic Coating', 8000, 360, '4,000-12,000 EGP', 'Ceramic coating quotation.'),
  service('engine-cleaning', 'Car Care', 'Engine Cleaning', 425, 60, '250-600 EGP', 'Engine bay cleaning.'),

  service('dent-repair', 'Body & Paint', 'Dent Repair', 1150, 120, '300-2,000 EGP', 'Dent repair quotation.'),
  service('bumper-repair', 'Body & Paint', 'Bumper Repair', 1500, 180, '500-2,500 EGP', 'Bumper repair and paint estimate.'),
  service('painting-per-part', 'Body & Paint', 'Painting Per Part', 1400, 240, '800-2,000 EGP', 'Painting one body part.'),
  service('full-car-paint', 'Body & Paint', 'Full Car Paint', 30000, 1440, '15,000-45,000 EGP', 'Full car paint quotation.'),
  service('scratch-repair', 'Body & Paint', 'Scratch Repair', 650, 90, '300-1,000 EGP', 'Scratch repair and local paint estimate.'),
  service('windshield-replacement', 'Body & Paint', 'Windshield Replacement', 3750, 120, '1,500-6,000 EGP', 'Windshield replacement labor estimate.'),

  service('periodic-maintenance-5000', 'Maintenance', 'Periodic Maintenance (5,000 km)', 1400, 120, '800-2,000 EGP', '5,000 km periodic maintenance.'),
  service('periodic-maintenance-10000', 'Maintenance', 'Periodic Maintenance (10,000 km)', 2500, 180, '1,500-3,500 EGP', '10,000 km periodic maintenance.', true),
  service('fluid-check', 'Maintenance', 'Fluid Check', 225, 30, '150-300 EGP', 'Vehicle fluid level and condition check.'),
  service('coolant-replacement', 'Maintenance', 'Coolant Replacement', 500, 60, '300-700 EGP', 'Coolant replacement and bleeding.'),
  service('belt-inspection', 'Maintenance', 'Belt Inspection', 225, 30, '150-300 EGP', 'Drive belt inspection.'),
  service('multi-point-inspection', 'Maintenance', 'Multi-Point Inspection', 450, 60, '300-600 EGP', 'Full vehicle multi-point inspection.', true),
];

export const findCatalogService = (idOrName) => {
  const key = String(idOrName || '').trim().toLowerCase();
  if (!key) return null;
  return egyptServiceCatalog.find(
    (item) => item.id.toLowerCase() === key || item.name.toLowerCase() === key,
  ) || null;
};

export const calculateCheckoutTotal = (subtotal) => {
  const safeSubtotal = Math.max(0, Number(subtotal) || 0);
  const appServiceFee = Math.round(safeSubtotal * APP_SERVICE_FEE_RATE * 100) / 100;
  return {
    subtotal: safeSubtotal,
    appServiceFee,
    total: Math.round((safeSubtotal + appServiceFee) * 100) / 100,
  };
};
