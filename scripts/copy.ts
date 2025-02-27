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

// Define the files to watch
const watchPaths = ["package.json", "public/**/*.json", "src/**/*.lua"];
const expandedPaths = glob.sync(watchPaths);
const normalizedPaths = expandedPaths.map((p) => p.replace(/\\/g, "/"));

// Function to copy file and flatten structure
const copyFileFlattened = (filePath: string) => {
  const fileName = path.basename(filePath);
  const destPath = path.join(outputDir, fileName);

  try {
    fs.copySync(filePath, destPath);
    console.log(`Copied: ${filePath} -> ${destPath}`);
  } catch (err) {
    console.error(`Error copying ${filePath}:`, err);
  }
};

// Initialize file watcher
const watcher = chokidar.watch(normalizedPaths, { persistent: true });

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
