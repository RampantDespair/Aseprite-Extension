import { createBaseConfig } from "@repo/config-webpack";
import CopyPlugin from "copy-webpack-plugin";
import glob from "glob";
import luamin from "luamin";
import path from "path";

const __dirname = import.meta.dirname;
const paths = {
  in: path.resolve(__dirname),
  out: path.resolve(__dirname, "dist"),
};

const luaFiles = glob.sync(path.resolve(paths.in, "src", "**/*.lua"));

const createConfig = (env, argv) => {
  const config = createBaseConfig(env, argv);

  // Overrides
  config.entry = {};
  config.output.path = paths.out;

  config.resolve.alias = {
    "@": path.resolve(__dirname, "./"),
  };

  // Plugins
  config.plugins.push(
    new CopyPlugin({
      patterns: [
        {
          from: path.resolve(paths.in, "package.json"),
          to: paths.out,
          transform(content) {
            const contents = JSON.parse(content.toString());

            delete contents["$schema"];
            delete contents["workspaces"];
            delete contents["scripts"];
            delete contents["devDependencies"];

            return JSON.stringify(contents, null, 0);
          },
        },
        {
          from: path.resolve(paths.in, "public", "__info.json"),
          to: paths.out,
        },
        ...luaFiles.map((file) => ({
          from: file,
          to: paths.out,
          transform(content, absoluteFilename) {
            try {
              const minifiedLua = luamin.minify(content.toString());
              console.log(`✔ Minified: ${absoluteFilename}`);
              return minifiedLua;
            } catch (error) {
              console.error(`❌ Failed to minify: ${absoluteFilename}`);
              console.error(error);
              return content;
            }
          },
        })),
      ],
    }),
  );

  return config;
};

export default createConfig;
