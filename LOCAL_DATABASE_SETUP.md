# Mindease Local MongoDB Database Setup

## ✅ Setup Complete!

Your Mindease project has been successfully configured to use a local MongoDB database instead of MongoDB Atlas.

## 📋 Configuration Details

- **Database Name**: `mindease_local`
- **Connection String**: `mongodb:// 192.168.2.102:27017/mindease_local`
- **Data Directory**: `C:\data\db`
- **MongoDB Version**: 8.0

## 🗃️ Database Collections

The following collections have been created and populated:

1. **users** (2 documents)
   - Admin user: `admin@mentalhealth.com` / `admin123`
   - Test user: `hadyy@gmail.com` / `password123`

2. **therapists** (1 document)
   - Dr. Sarah Johnson: `sarah@therapy.com` / `therapist123` (pending approval)

3. **Empty collections ready for data**:
   - appointments
   - journalentries
   - moods
   - payments
   - testresults

## 🚀 How to Start the System

### Option 1: Using the PowerShell Script
```powershell
.\start-local-db.ps1
cd project
npm start
```

### Option 2: Manual Steps
1. **Start MongoDB**:
   ```powershell
   & "C:\Program Files\MongoDB\Server\8.0\bin\mongod.exe" --dbpath "C:\data\db"
   ```

2. **Start the Server**:
   ```bash
   cd project
   npm start
   ```

## 🧪 Testing the Database

Run the verification script to check your database:
```bash
cd project
node verify-data.js
```

## 🔧 Troubleshooting

### If MongoDB won't start:
1. Make sure the data directory exists: `C:\data\db`
2. Check if port 27017 is available
3. Run PowerShell as Administrator and try: `net start MongoDB`

### If connection fails:
1. Verify MongoDB is running: `netstat -an | findstr :27017`
2. Check the server logs for detailed error messages
3. Ensure no firewall is blocking port 27017

## 📁 Important Files Modified

- `project/src/config/db.js` - Updated to use local MongoDB
- `project/test-db.js` - Updated to test local database
- `project/verify-data.js` - New script to verify data
- `start-local-db.ps1` - Startup script for convenience

## 🔄 Migration from Atlas

Your project has been successfully migrated from MongoDB Atlas to a local MongoDB instance. All the same functionality is preserved, but now running locally for better development experience and no internet dependency.

## 🎯 Next Steps

1. Your server should now start without connection errors
2. All API endpoints will work with the local database
3. You can add more test data as needed
4. Consider setting up MongoDB Compass for a GUI interface to your local database

## 💡 Tips

- The local database persists data between restarts
- You can backup your data by copying the `C:\data\db` folder
- For production, you may want to switch back to a cloud database
- Consider using environment variables to switch between local and cloud databases
