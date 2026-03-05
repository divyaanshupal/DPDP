const mongoose = require('mongoose');


// We add { _id: false } because we don't need a separate ID for each document entry.
const documentSchema = new mongoose.Schema({
  name: { type: String, required: true },
  fileType: { type: String, required: true }
}, { _id: false });


const userSchema = new mongoose.Schema({
    uuid: {
        type: String,
        required: true,
        unique: true,
    },
    name: {
        type: String,
    },
    email: String,
    phone: String,
    
    // It will be an empty array [] by default when a new user registers.
    documents: [documentSchema]

}, { timestamps: true });

module.exports = mongoose.model('User', userSchema);