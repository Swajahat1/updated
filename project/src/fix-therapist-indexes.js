const mongoose = require('mongoose');

async function fixTherapistIndexes() {
  try {
    console.log('Connecting to MongoDB...');
    await mongoose.connect('mongodb:// 192.168.2.102:27017/mindease');
    
    const db = mongoose.connection.db;
    const collection = db.collection('therapists');
    
    console.log('Checking current indexes...');
    const indexes = await collection.indexes();
    console.log('Current indexes:', JSON.stringify(indexes, null, 2));
    
    // Drop any incorrect indexes on location field
    console.log('Dropping incorrect indexes...');
    try {
      await collection.dropIndex({ location: "2dsphere" });
      console.log('Dropped location 2dsphere index');
    } catch (error) {
      console.log('No location 2dsphere index to drop');
    }

    try {
      await collection.dropIndex("location_2dsphere");
      console.log('Dropped location_2dsphere index');
    } catch (error) {
      console.log('No location_2dsphere index to drop');
    }

    // Also try to drop any other location-related indexes
    try {
      await collection.dropIndex("location_1");
      console.log('Dropped location_1 index');
    } catch (error) {
      console.log('No location_1 index to drop');
    }

    // Drop all indexes except _id and recreate them properly
    console.log('Dropping all indexes except _id...');
    try {
      await collection.dropIndexes();
      console.log('Dropped all indexes');
    } catch (error) {
      console.log('Error dropping indexes:', error.message);
    }
    
    // Create correct index on coordinates field
    console.log('Creating correct index on coordinates...');
    try {
      await collection.createIndex({ coordinates: "2dsphere" });
      console.log('Created coordinates 2dsphere index');
    } catch (error) {
      console.log('Coordinates index already exists or error:', error.message);
    }
    
    console.log('Final indexes:');
    const finalIndexes = await collection.indexes();
    console.log(JSON.stringify(finalIndexes, null, 2));
    
    console.log('Index fix completed successfully!');
    process.exit(0);
    
  } catch (error) {
    console.error('Error fixing indexes:', error);
    process.exit(1);
  }
}

fixTherapistIndexes();
