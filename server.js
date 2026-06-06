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
    // 1. Scan the server directory to see what files exist
    fs.readdir(__dirname, (dirErr, files) => {
        const fileListString = files ? files.join(', ') : 'None';

        const { code } = req.body;
        if (!code) return res.status(400).json({ error: 'No code provided' });

        const timestamp = Date.now();
        const inputPath = path.join(__dirname, `temp_input_${timestamp}.lua`);
        const outputPath = path.join(__dirname, `temp_output_${timestamp}.lua`);

        // 2. Look for ANY .lua file that isn't a temporary user input file
        let targetLuaFile = files.find(f => f.endsWith('.lua') && !f.startsWith('temp_'));

        if (!targetLuaFile) {
            return res.status(500).json({
                error: 'No Lua obfuscator script found in repository!',
                detectedFiles: fileListString
            });
        }

        const scriptPath = path.join(__dirname, targetLuaFile);

        fs.writeFile(inputPath, code, (writeErr) => {
            if (writeErr) return res.status(500).json({ error: 'Failed to create temp input file' });

            // 3. Execute whatever Lua file was successfully discovered
            exec(`lua "${scriptPath}" "${inputPath}" "${outputPath}"`, (execErr, stdout, stderr) => {
                fs.readFile(outputPath, 'utf8', (readErr, obfuscatedCode) => {
                    fs.unlink(inputPath, () => {});
                    fs.unlink(outputPath, () => {});

                    // If your script outputs an error, show it along with what files we have
                    if (execErr || stderr) {
                        return res.status(500).json({
                            error: 'Obfuscation runtime error',
                            details: stderr || execErr.message,
                            runningScript: targetLuaFile,
                            detectedFiles: fileListString
                        });
                    }

                    if (readErr) {
                        return res.json({ obfuscatedCode: stdout });
                    }

                    res.json({ obfuscatedCode: obfuscatedCode });
                });
            });
        });
    });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Limitless API active on port ${PORT}`));
