import { defineConfig } from "vite";
import elmPlugin from "vite-plugin-elm";

export default defineConfig({
	base: "/JUWURA",
	plugins: [
		elmPlugin({
			debug: false,
		}),
	],
});
