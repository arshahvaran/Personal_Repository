// Load the CSV file from your assets
var csvFile = ee.FeatureCollection("projects/ee-arshahvaran/assets/gee_l8");

// Function to extract pixel values for a given feature
var extractPixelValues = function(feature) {
  // Get coordinates and other properties from the feature
  var lat = feature.get('Lat_DD_WGS84');
  var lon = feature.get('Long_DD_WGS84');
  var point = ee.Geometry.Point([lon, lat]);
  var startDate = ee.Date(feature.get('Sensing_Date'));
  var path = ee.Number(feature.get('Path'));
  var row = ee.Number(feature.get('Row'));

  // Define the end date as one day after the start date
  var endDate = startDate.advance(1, 'day');

  // Define the Landsat 8 SR collection
  var landsat8SRCollection = ee.ImageCollection('LANDSAT/LC08/C02/T1_L2')
    .filterBounds(point)
    .filterDate(startDate, endDate)
    .filter(ee.Filter.eq('WRS_PATH', path))
    .filter(ee.Filter.eq('WRS_ROW', row))
    .select(['SR_B1', 'SR_B2', 'SR_B3', 'SR_B4', 'SR_B5']);

  // Select the first image from the filtered SR collection
  var srImage = landsat8SRCollection.first();

  // Get the pixel values at the specified point for SR collection
  var srPixelValues = srImage.reduceRegion({
    reducer: ee.Reducer.first(),
    geometry: point,
    scale: 30
  });

  // Define the Landsat 8 TOA collection
  var landsat8TOACollection = ee.ImageCollection('LANDSAT/LC08/C02/T1')
    .filterBounds(point)
    .filterDate(startDate, endDate)
    .filter(ee.Filter.eq('WRS_PATH', path))
    .filter(ee.Filter.eq('WRS_ROW', row))
    .select(['B1', 'B2', 'B3', 'B4', 'B5']);

  // Select the first image from the filtered TOA collection
  var toaImage = landsat8TOACollection.first();

  // Get the pixel values at the specified point for TOA collection
  var toaPixelValues = toaImage.reduceRegion({
    reducer: ee.Reducer.first(),
    geometry: point,
    scale: 30
  });

  // Combine the SR and TOA pixel values into the feature
  var combined = feature.set({
    'B1': toaPixelValues.get('B1'),
    'B2': toaPixelValues.get('B2'),
    'B3': toaPixelValues.get('B3'),
    'B4': toaPixelValues.get('B4'),
    'B5': toaPixelValues.get('B5'),
    'SR_B1': srPixelValues.get('SR_B1'),
    'SR_B2': srPixelValues.get('SR_B2'),
    'SR_B3': srPixelValues.get('SR_B3'),
    'SR_B4': srPixelValues.get('SR_B4'),
    'SR_B5': srPixelValues.get('SR_B5')
  });

  return combined;
};

// Apply the extraction function to each feature in the CSV
var updatedFeatures = csvFile.map(extractPixelValues);

// Export the updated CSV file
Export.table.toDrive({
  collection: updatedFeatures,
  description: 'Updated_Landsat_Pixel_Values',
  fileFormat: 'CSV'
});
