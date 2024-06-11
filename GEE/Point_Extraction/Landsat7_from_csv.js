// Load the CSV file from your assets
var csvFile = ee.FeatureCollection("projects/ee-arshahvaran/assets/gee_l7");

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

  // Define the Landsat 7 SR collection
  var landsat7SRCollection = ee.ImageCollection('LANDSAT/LE07/C02/T1_L2')
    .filterBounds(point)
    .filterDate(startDate, endDate)
    .filter(ee.Filter.eq('WRS_PATH', path))
    .filter(ee.Filter.eq('WRS_ROW', row))
    .select(['SR_B1', 'SR_B2', 'SR_B3', 'SR_B4']);

  // Select the first image from the filtered SR collection
  var srImage = landsat7SRCollection.first();

  // Initialize variables to hold pixel values
  var srPixelValues = ee.Dictionary({
    'SR_B1': null,
    'SR_B2': null,
    'SR_B3': null,
    'SR_B4': null
  });

  // Get the pixel values if the image exists
  srPixelValues = ee.Algorithms.If(
    srImage,
    srImage.reduceRegion({
      reducer: ee.Reducer.first(),
      geometry: point,
      scale: 30
    }),
    srPixelValues
  );

  // Define the Landsat 7 TOA collection
  var landsat7TOACollection = ee.ImageCollection('LANDSAT/LE07/C02/T1')
    .filterBounds(point)
    .filterDate(startDate, endDate)
    .filter(ee.Filter.eq('WRS_PATH', path))
    .filter(ee.Filter.eq('WRS_ROW', row))
    .select(['B1', 'B2', 'B3', 'B4']);

  // Select the first image from the filtered TOA collection
  var toaImage = landsat7TOACollection.first();

  // Initialize variables to hold pixel values
  var toaPixelValues = ee.Dictionary({
    'B1': null,
    'B2': null,
    'B3': null,
    'B4': null
  });

  // Get the pixel values if the image exists
  toaPixelValues = ee.Algorithms.If(
    toaImage,
    toaImage.reduceRegion({
      reducer: ee.Reducer.first(),
      geometry: point,
      scale: 30
    }),
    toaPixelValues
  );

  // Combine the SR and TOA pixel values into the feature
  var combined = feature.set({
    'B1': ee.Dictionary(toaPixelValues).get('B1'),
    'B2': ee.Dictionary(toaPixelValues).get('B2'),
    'B3': ee.Dictionary(toaPixelValues).get('B3'),
    'B4': ee.Dictionary(toaPixelValues).get('B4'),
    'SR_B1': ee.Dictionary(srPixelValues).get('SR_B1'),
    'SR_B2': ee.Dictionary(srPixelValues).get('SR_B2'),
    'SR_B3': ee.Dictionary(srPixelValues).get('SR_B3'),
    'SR_B4': ee.Dictionary(srPixelValues).get('SR_B4')
  });

  return combined;
};

// Apply the extraction function to each feature in the CSV
var updatedFeatures = csvFile.map(extractPixelValues);

// Export the updated CSV file
Export.table.toDrive({
  collection: updatedFeatures,
  description: 'Updated_Landsat7_Pixel_Values',
  fileFormat: 'CSV'
});
