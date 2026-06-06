const express = require('express');
const cors = require('cors');
const { exec } = require('child_process');
const fs = require('fs');
const path = require('path');

const app = express();
app.use(cors());
app.use(express.json());
app.use(express.static('public'));

app.post('/api/obfuscate', (req, res) => {
    const { code } = req.body;
    if (!code) return res.status(400).json({ error: 'No code provided' });

    const timestamp = Date.now();
    const inputPath = path.join(__dirname, `temp_input_${timestamp}.lua`);
    const outputPath = path.join(__dirname, `temp_output_${timestamp}.lua`);
   
    fs.writeFile(inputPath, code, (err) => {
        if (err) return res.status(500).json({ error: 'Failed to create temp input file' });

        exec(`lua limitless.lua "${inputPath}" "${outputPath}"`, (execErr, stdout, stderr) => {
            fs.readFile(outputPath, 'utf8', (readErr, obfuscatedCode) => {
                fs.unlink(inputPath, () => {});
                fs.unlink(outputPath, () => {});

                if (execErr || stderr) {
                    return res.status(500).json({ error: 'Obfuscation runtime error', details: stderr || execErr.message });
                }

                if (readErr) {
                    return res.json({ obfuscatedCode: stdout });
                }

                res.json({ obfuscatedCode: obfuscatedCode });
            });
        });
    });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Limitless API active on port ${PORT}`));
