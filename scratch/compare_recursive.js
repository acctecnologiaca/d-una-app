const fs = require('fs');
const path = require('path');

const OLD_ROOT = 'C:/Users/aleja/.gemini/antigravity';
const NEW_ROOT = 'C:/Users/aleja/.gemini/antigravity-ide';

function getFilesRecursive(dir, baseDir) {
  let results = [];
  const list = fs.readdirSync(dir);
  for (const file of list) {
    const filePath = path.join(dir, file);
    const stat = fs.statSync(filePath);
    const relativePath = path.relative(baseDir, filePath);
    
    // Ignore conversations and brain content for performance and size
    if (relativePath.startsWith('conversations') || relativePath.startsWith('brain')) {
      continue;
    }
    
    if (stat.isDirectory()) {
      results = results.concat(getFilesRecursive(filePath, baseDir));
    } else {
      results.push({ path: relativePath.replace(/\\/g, '/'), size: stat.size });
    }
  }
  return results;
}

console.log('--- RECURSIVE METADATA COMPARISON ---');
try {
  const oldFiles = getFilesRecursive(OLD_ROOT, OLD_ROOT);
  const newFiles = getFilesRecursive(NEW_ROOT, NEW_ROOT);
  
  console.log(`Old directory non-chat files count: ${oldFiles.length}`);
  console.log(`New directory non-chat files count: ${newFiles.length}`);
  
  const oldMap = new Map(oldFiles.map(f => [f.path, f.size]));
  const newMap = new Map(newFiles.map(f => [f.path, f.size]));
  
  const missingInNew = oldFiles.filter(f => !newMap.has(f.path));
  const missingInOld = newFiles.filter(f => !oldMap.has(f.path));
  
  console.log('Missing in new folder:', missingInNew);
  console.log('Missing in old folder:', missingInOld);
  
  for (const [p, size] of oldMap.entries()) {
    if (newMap.has(p)) {
      const newSize = newMap.get(p);
      if (size !== newSize) {
        console.log(`Size mismatch for ${p}: old=${size}, new=${newSize}`);
      }
    }
  }
} catch (e) {
  console.log('Error:', e.message);
}
