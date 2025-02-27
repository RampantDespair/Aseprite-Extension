import chokidar from "chokidar";
import fs from "fs-extra";
import { glob } from "glob";
import path from "path";

// Get the output directory from environment variables
const outputDir = path.join(
  process.env.APPDATA ?? "",
  "Aseprite/extensions/",
  process.env.npm_package_name ?? "extension",
);

// Ensure the output directory exists
fs.ensureDirSync(outputDir);

// Clean the output directory
fs.emptyDirSync(outputDir);

// Define the files to watch
const watchPaths = [
  "package.json",
  "public/**/*.{lua,json}",
  "src/**/*.{lua,json}",
];

// Function to copy file and flatten structure
const copyFileFlattened = async (filePath: string) => {
  const fileName = path.basename(filePath);
  const destPath = path.join(outputDir, fileName);

  try {
    await fs.copy(filePath, destPath);
    console.log(`Copied: ${filePath} -> ${destPath}`);
  } catch (err) {
    console.error(`Error copying ${filePath}:`, err);
  }
};

// Initially copy all files
const copyAllFiles = async () => {
  try {
    const files = await glob(watchPaths);
    await Promise.all(files.map(copyFileFlattened));
    console.log("Initial copy complete.");
  } catch (err) {
    console.error("Error during initial copy:", err);
  }
};

await copyAllFiles();

// Initialize file watcher
const watcher = chokidar.watch(watchPaths, { persistent: true });

watcher
  .on("add", copyFileFlattened)
  .on("change", copyFileFlattened)
  .on("unlink", async (filePath) => {
    const fileName = path.basename(filePath);
    const destPath = path.join(outputDir, fileName);

    try {
      await fs.remove(destPath);
      console.log(`Removed: ${destPath}`);
    } catch (err) {
      console.error(`Error removing ${destPath}:`, err);
    }
  });

console.log("Watching for file changes...");
