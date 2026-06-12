const mongoose = require('mongoose');
async function run() {
    await mongoose.connect('mongodb+srv://test:You%40%40123@cluster0.p2xus.mongodb.net/ERP');
    const p = await mongoose.connection.collection('products').find({ name: /Chip/i }).toArray();
    console.log("Products: ", JSON.stringify(p, null, 2));

    if (p.length > 0) {
        const s = await mongoose.connection.collection('stock_movements').aggregate([
            { $match: { product_id: p[0]._id } }
        ]).toArray();
        console.log("Movements: ", JSON.stringify(s, null, 2));
    }
    process.exit(0);
}
run();
