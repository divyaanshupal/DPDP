const express=require('express');
const router=express.Router();
const User=require('../Models/User');
const generateUUID=require('../Utils/uuidGenerator');

//register route
router.post('/register',async(req,res)=>{
    const{name,email,phone}=req.body;
    try{
        const uuid=await generateUUID();
        const newUser=new User({name,email,phone,uuid});
        await newUser.save();
        res.status(201).json({message:'User Registered',uuid});
    }
    catch(error){
        res.status(500).json({error:error.message});
    }
});

//user details fetch route
router.get('/user/:uuid', async (req, res) => {
    try {
        const user = await User.findOne({ uuid: req.params.uuid });

        if (!user) {
            return res.status(404).json({ error: "User not found" }); // Use 404 for not found
        }

        // ✨ CHANGE: Instead of sending the whole user object (which includes
        // email and phone), we only send the public-facing information.
        res.json({
            uuid: user.uuid,
            name: user.name,
            documents: user.documents
        });

    } catch (e) {
        res.status(500).json({ e: 'server error' });
    }
});


// --- ✨ ADD THIS NEW ROUTE AT THE END OF THE FILE ---
// Route to update a user's document list
router.put('/user/:uuid/documents', async (req, res) => {
    // The Flutter app will send a body like: { "documents": [{ "name": "...", "fileType": "..." }] }
    const { documents } = req.body;
  
    if (!Array.isArray(documents)) {
      return res.status(400).json({ message: 'Request body must contain a "documents" array.' });
    }
  
    try {
      // Find the user by UUID and completely replace their documents array with the new one.
      const updatedUser = await User.findOneAndUpdate(
        { uuid: req.params.uuid },
        { $set: { documents: documents } },
        { new: true } // This option ensures the updated user is returned
      );
  
      if (!updatedUser) {
        return res.status(404).json({ message: 'User not found.' });
      }
  
      res.status(200).json({ message: 'Document list updated successfully.' });
    } catch (error) {
      console.error('Update Docs Error:', error);
      res.status(500).json({ message: 'Server error while updating documents.' });
    }
});

// Route to get user by email
router.post('/user-by-email', async (req, res) => {
    const { email } = req.body;
    
    if (!email) {
        return res.status(400).json({ error: 'Email is required' });
    }
    
    try {
        const user = await User.findOne({ email: email });
        
        if (!user) {
            return res.status(404).json({ error: 'User not found' });
        }
        
        res.status(200).json({ uuid: user.uuid });
    } catch (error) {
        console.error('Get user by email error:', error);
        res.status(500).json({ error: 'Server error while finding user' });
    }
});


module.exports = router;