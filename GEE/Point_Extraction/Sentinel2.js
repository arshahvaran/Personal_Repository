// Define the coordinates, start date, and tile of interest
var point = ee.Geometry.Point([-79.79583333, 43.28555556]);
var startDate = ee.Date('2021-06-10');
var endDate = startDate.advance(1, 'day');
var tile = '17TNJ';


// Define the Sentinel-2 TOA collection
var sentinel2TOACollection = ee.ImageCollection('COPERNICUS/S2_HARMONIZED')
  .filterBounds(point)
  .filterDate(startDate, endDate)
  .filter(ee.Filter.eq('MGRS_TILE', tile))
  .select(['B1', 'B2', 'B3', 'B4', 'B5', 'B6', 'B7', 'B8', 'B8A']);

// Select the first image from the filtered TOA collection
var toaImage = sentinel2TOACollection.first();

// Get the pixel values at the specified point for TOA collection
var toaPixelValues = toaImage.reduceRegion({
  reducer: ee.Reducer.first(),
  geometry: point,
  scale: 10
});
// Print the TOA pixel values to the console
print('Level-1:', toaPixelValues);

// Define the Sentinel-2 SR collection
var sentinel2SRCollection = ee.ImageCollection('COPERNICUS/S2_SR_HARMONIZED')
  .filterBounds(point)
  .filterDate(startDate, endDate)
  .filter(ee.Filter.eq('MGRS_TILE', tile))
  .select(['B1', 'B2', 'B3', 'B4', 'B5', 'B6', 'B7', 'B8', 'B8A']);

// Select the first image from the filtered SR collection
var srImage = sentinel2SRCollection.first();

// Get the pixel values at the specified point for SR collection
var srPixelValues = srImage.reduceRegion({
  reducer: ee.Reducer.first(),
  geometry: point,
  scale: 10
});

// Print the SR pixel values to the console
print('Level-2:', srPixelValues);
