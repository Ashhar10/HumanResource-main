const fs = require('fs');
const path = require('path');
const mod = require('png-to-ico');
const pngToIco = mod.default || mod;

async function makeIco() {
  const src = path.join(__dirname, 'public/icons/logo.png');
  const buildDir = path.join(__dirname, 'build');
  if (!fs.existsSync(buildDir)) fs.mkdirSync(buildDir, { recursive: true });

  const dest = path.join(buildDir, 'icon.ico');
  const buf = await pngToIco(src);
  fs.writeFileSync(dest, buf);
  fs.writeFileSync(path.join(__dirname, 'public/icon.ico'), buf);
  console.log('Successfully generated Windows icon.ico:', dest, `(${buf.length} bytes)`);
}

makeIco().catch(console.error);
