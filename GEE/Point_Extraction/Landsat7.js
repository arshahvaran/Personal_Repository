// Define the coordinates, start date, path, and row of interest
var point = ee.Geometry.Point([-79.87555556, 43.27944444]);
var startDate = ee.Date('2021-08-14');
var path = 18;
var row = 30;

// Automatically define the end date as one day after the start date
var endDate = startDate.advance(1, 'day');

// Define the Landsat 8 TOA collection
var landsat8TOACollection = ee.ImageCollection('LANDSAT/LE07/C02/T1')
  .filterBounds(point)
  .filterDate(startDate, endDate)
  .filter(ee.Filter.eq('WRS_PATH', path))
  .filter(ee.Filter.eq('WRS_ROW', row))
  .select(['B1', 'B2', 'B3', 'B4']);

// Select the first image from the filtered TOA collection
var toaImage = landsat8TOACollection.first();

// Get the pixel values at the specified point for TOA collection
var toaPixelValues = toaImage.reduceRegion({
  reducer: ee.Reducer.first(),
  geometry: point,
  scale: 30
});

// Print the TOA pixel values to the console
print('TOA Pixel values at the specified point:', toaPixelValues);

// Define the Landsat 8 SR collection
var landsat8SRCollection = ee.ImageCollection('LANDSAT/LE07/C02/T1_L2')
  .filterBounds(point)
  .filterDate(startDate, endDate)
  .filter(ee.Filter.eq('WRS_PATH', path))
  .filter(ee.Filter.eq('WRS_ROW', row))
  .select(['SR_B1', 'SR_B2', 'SR_B3', 'SR_B4']);

// Select the first image from the filtered SR collection
var srImage = landsat8SRCollection.first();

// Get the pixel values at the specified point for SR collection
var srPixelValues = srImage.reduceRegion({
  reducer: ee.Reducer.first(),
  geometry: point,
  scale: 30
});

// Print the SR pixel values to the console
print('SR Pixel values at the specified point:', srPixelValues);
