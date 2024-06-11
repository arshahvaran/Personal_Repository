// Load the CSV file from your assets
var csvFile = ee.FeatureCollection("projects/ee-arshahvaran/assets/gee_s2");

// Function to extract pixel values for a given feature
var extractPixelValues = function(feature) {
  // Get coordinates and other properties from the feature
  var lat = feature.get('Lat_DD_WGS84');
  var lon = feature.get('Long_DD_WGS84');
  var point = ee.Geometry.Point([lon, lat]);
  var startDate = ee.Date(feature.get('Sensing_Date'));
  var tile = feature.get('Tile');

  // Define the end date as one day after the start date
  var endDate = startDate.advance(1, 'day');

  // Define the Sentinel-2 TOA collection
  var sentinel2TOACollection = ee.ImageCollection('COPERNICUS/S2_HARMONIZED')
    .filterBounds(point)
    .filterDate(startDate, endDate)
    .filter(ee.Filter.eq('MGRS_TILE', tile))
    .select(['B1', 'B2', 'B3', 'B4', 'B5', 'B6', 'B7', 'B8', 'B8A']);

  // Select the first image from the filtered TOA collection
  var toaImage = sentinel2TOACollection.first();

  // Initialize variables to hold pixel values
  var toaPixelValues = ee.Dictionary({
    'B1': null,
    'B2': null,
    'B3': null,
    'B4': null,
    'B5': null,
    'B6': null,
    'B7': null,
    'B8': null,
    'B8A': null
  });

  // Get the pixel values if the image exists
  toaPixelValues = ee.Algorithms.If(
    toaImage,
    toaImage.reduceRegion({
      reducer: ee.Reducer.first(),
      geometry: point,
      scale: 10
    }),
    toaPixelValues
  );

  // Define the Sentinel-2 SR collection
  var sentinel2SRCollection = ee.ImageCollection('COPERNICUS/S2_SR_HARMONIZED')
    .filterBounds(point)
    .filterDate(startDate, endDate)
    .filter(ee.Filter.eq('MGRS_TILE', tile))
    .select(['B1', 'B2', 'B3', 'B4', 'B5', 'B6', 'B7', 'B8', 'B8A']);

  // Select the first image from the filtered SR collection
  var srImage = sentinel2SRCollection.first();

  // Initialize variables to hold pixel values
  var srPixelValues = ee.Dictionary({
    'B1': null,
    'B2': null,
    'B3': null,
    'B4': null,
    'B5': null,
    'B6': null,
    'B7': null,
    'B8': null,
    'B8A': null
  });

  // Get the pixel values if the image exists
  srPixelValues = ee.Algorithms.If(
    srImage,
    srImage.reduceRegion({
      reducer: ee.Reducer.first(),
      geometry: point,
      scale: 10
    }),
    srPixelValues
  );

  // Combine the SR and TOA pixel values into the feature
  var combined = feature.set({
    'Level1_B01': ee.Dictionary(toaPixelValues).get('B1'),
    'Level1_B02': ee.Dictionary(toaPixelValues).get('B2'),
    'Level1_B03': ee.Dictionary(toaPixelValues).get('B3'),
    'Level1_B04': ee.Dictionary(toaPixelValues).get('B4'),
    'Level1_B05': ee.Dictionary(toaPixelValues).get('B5'),
    'Level1_B06': ee.Dictionary(toaPixelValues).get('B6'),
    'Level1_B07': ee.Dictionary(toaPixelValues).get('B7'),
    'Level1_B08': ee.Dictionary(toaPixelValues).get('B8'),
    'Level1_B08A': ee.Dictionary(toaPixelValues).get('B8A'),
    'Level2_B01': ee.Dictionary(srPixelValues).get('B1'),
    'Level2_B02': ee.Dictionary(srPixelValues).get('B2'),
    'Level2_B03': ee.Dictionary(srPixelValues).get('B3'),
    'Level2_B04': ee.Dictionary(srPixelValues).get('B4'),
    'Level2_B05': ee.Dictionary(srPixelValues).get('B5'),
    'Level2_B06': ee.Dictionary(srPixelValues).get('B6'),
    'Level2_B07': ee.Dictionary(srPixelValues).get('B7'),
    'Level2_B08': ee.Dictionary(srPixelValues).get('B8'),
    'Level2_B08A': ee.Dictionary(srPixelValues).get('B8A')
  });

  return combined;
};

// Apply the extraction function to each feature in the CSV
var updatedFeatures = csvFile.map(extractPixelValues);

// Export the updated CSV file
Export.table.toDrive({
  collection: updatedFeatures,
  description: 'Updated_Sentinel2_Pixel_Values',
  fileFormat: 'CSV'
});
